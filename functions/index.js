/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */
import fetch from "node-fetch";
import { onDocumentWritten, onDocumentDeleted } from "firebase-functions/v2/firestore";
import { setGlobalOptions } from "firebase-functions/v2";
import admin from "firebase-admin";
import { defineSecret } from "firebase-functions/params";

const OPENAI_KEY = defineSecret("OPENAI_KEY");

admin.initializeApp();
setGlobalOptions({ maxInstances: 10 });

export const deleteUserData = onDocumentDeleted("users/{uid}", async (event) => {
  const uid = event.params.uid;
  const db = admin.firestore();
  const storage = admin.storage().bucket();
  const userRef = db.collection("users").doc(uid);

  try {
    // 💤 1) Delete sleepLogs + nested clips
    const sleepLogs = await userRef.collection("sleepLogs").get();
    for (const log of sleepLogs.docs) {
      const clips = await log.ref.collection("clips").get();
      for (const clip of clips.docs) {
        const path = clip.get("storagePath");
        if (path) {
          try { await storage.file(path).delete(); } catch {}
        }
        await clip.ref.delete();
      }
      await log.ref.delete();
    }

    // 🏃‍♂️ 2) Delete activities
    const acts = await userRef.collection("activities").get();
    for (const doc of acts.docs) await doc.ref.delete();

    // ⚙️ 3) Delete settings
    const settings = await userRef.collection("settings").get();
    for (const doc of settings.docs) await doc.ref.delete();

    console.log(`✅ Deleted all data for user ${uid}`);
  } catch (err) {
    console.error("❌ Error deleting user data:", err);
  }
});

export const generateSleepInsights = onDocumentWritten(
  { 
    document: "users/{userId}/sleepLogs/{logId}", 
    secrets: [OPENAI_KEY] 
  },
  async (event) => {
  const data = event.data?.after?.data();
  const { userId, logId } = event.params;

  if (!data?.end) return; // skip incomplete logs
  if (data?.sleepQuality) return; // skip already generated logs
  if (data?.recommendations) return; // skip already generated recommendations

  const db = admin.firestore();
  const openaiKey = OPENAI_KEY.value();

  const log = data;
  const profileSnap = await db.doc(`users/${userId}`).get();
  const profile = profileSnap.exists ? profileSnap.data() : {};
  const age = profile.age || null;
  let targetHours = 8;
  if (age) {
    targetHours = age < 18 ? 9 : age <= 64 ? 8 : 7.5;
  }
  let sleepDebtHours = 0;
  let audioClipsCount = 0;

  try {
    // ======================================================
    // Fetch related data (profile, activities, recent logs, audio clips)
    // ======================================================
    const [activitiesSnap, logsSnap, clipsSnap] = await Promise.all([
      db.collection(`users/${userId}/activities`).get(),
      db.collection(`users/${userId}/sleepLogs`).orderBy("start", "desc").limit(8).get(),
      db.collection(`users/${userId}/sleepLogs/${logId}/clips`).get(),
    ]);

    // Activities
    const activities = activitiesSnap.docs.map((doc) => {
      const a = doc.data();
      return {
        type: a.type,
        loggedAt: a.loggedAt,
        kind: a.kind,
        otherDescription: a.otherDescription,
        amountMg: a.amountMg,
        durationMin: a.durationMin,
        drinks: a.drinks,
        medication: a.medication,
        start: a.start,
        end: a.end,
      };
    });

    // Audio clip count
    audioClipsCount = clipsSnap.size;

    // Recent sleeps
    const allLogs = logsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    const latest = log;
    const recentSleeps = allLogs
      .filter((l) => l.id !== logId)
      .slice(0, 7)
      .map((l) => ({
        start: l.start,
        end: l.end
      }));

    // Calculate sleep debt
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    
    // Filter to only include completed logs within the past 7 days
    const recentLogs = allLogs.filter((x) => {
      const end = x.end?.toDate ? x.end.toDate() : new Date(x.end);
      return end >= sevenDaysAgo && x.start && x.end;
    });

    if (recentLogs.length > 0) {
      // Total minutes actually slept
      const totalSleptMinutes = recentLogs.reduce((sum, l) => {
        const start = l.start?.toDate ? l.start.toDate() : new Date(l.start);
        const end = l.end?.toDate ? l.end.toDate() : new Date(l.end);
        return sum + (end - start) / 60000;
      }, 0);

      // Target = targetHours × number of logs
      const targetTotalMinutes = targetHours * 60 * recentLogs.length;

      // Debt = difference between target and actual, clamped at 0
      const debtMinutes = Math.max(0, targetTotalMinutes - totalSleptMinutes);

      sleepDebtHours = Math.round(debtMinutes / 60);
    } else {
      sleepDebtHours = 0;
    }

    // calculate streak
    const calendar = new Date();
    const daysWithLogs = new Set(
      allLogs
        .filter((l) => {
          const end = l.end?.toDate ? l.end.toDate() : new Date(l.end);
          return end && !isNaN(end);
        })
        .map((l) => {
          const end = l.end?.toDate ? l.end.toDate() : new Date(l.end);
          return end.toISOString().split("T")[0];
        })
    );

    let streak = 0;
    let day = new Date();
    day.setHours(0, 0, 0, 0);

    const yesterday = new Date(day);
    yesterday.setDate(day.getDate() - 1);

    // Start from today if there’s a log today, else yesterday
    let anchor =
      daysWithLogs.has(day.toISOString().split("T")[0]) ||
      daysWithLogs.has(yesterday.toISOString().split("T")[0])
        ? (daysWithLogs.has(day.toISOString().split("T")[0]) ? day : yesterday)
        : null;

    if (anchor) {
      while (daysWithLogs.has(anchor.toISOString().split("T")[0])) {
        streak++;
        anchor.setDate(anchor.getDate() - 1);
      }
    }

    const streakDays = streak;

    // ======================================================
    // Build full input JSON
    // ======================================================

    // Compare latest vs previous night
    const previous = allLogs.find((l) => l.id !== logId);
    let diff = {};

    const start = latest.start?.toDate ? latest.start.toDate() : new Date(latest.start);
    const end = latest.end?.toDate ? latest.end.toDate() : new Date(latest.end);
    const latestDuration = (end - start) / 3600000;

    if (previous) {
      const prevStart = previous.start?.toDate ? previous.start.toDate() : new Date(previous.start);
      const prevEnd = previous.end?.toDate ? previous.end.toDate() : new Date(previous.end);
      const prevDuration = (prevEnd - prevStart) / 3600000;
      diff = {
        changeInDurationHrs: +(latestDuration - prevDuration).toFixed(2),
        changeInBedtimeMins: ((start - prevStart) / 60000).toFixed(0),
        changeInWakeupMins: ((end - prevEnd) / 60000).toFixed(0)
      };
    }

    const quality = Math.min(100, Math.round((latestDuration / targetHours) * 100));

    const input = {
      quality,
      age,
      targetHours,
      latestDuration,
      streakDays,
      bedtime: latest.start,
      wakeup: latest.end,
      sleepDebtHours,
      activities,
      audioClipsCount,
      recentSleeps,
      diff
    };

    // ======================================================
    // Send to OpenAI
    // ======================================================
    console.log("🕒 Debug check:", input);
    const inputJSON = JSON.stringify(input, null, 2);
    const prompt = `
You are a certified sleep health expert analyzing a user's recent sleep and lifestyle data. 

### PRIMARY OBJECTIVE Generate a JSON object assessing the user's most recent sleep log and offering three personalized recommendations. 

### OUTPUT FORMAT Respond with **only valid JSON**: 
{ 
  "recommendations": ["tip1", "tip2", "tip3"] 
} 

### RECOMMENDATION LOGIC (MANDATORY) 
Determine which mode to use based on "quality" from the input JSON: 

- **Excellent Mode (quality ≥ 90)** → All 3 recommendations must be **positive reinforcement**. 
Examples: “Great consistency!”, “You met your sleep goal again!”, “Keep your routine steady.” 

- **Good Mode (75 ≤ quality < 90)** → 1 positive reinforcement + 2 improvement tips. 
Example mix: “Great sleep duration!” + “Try to keep bedtime within 30 minutes.” + “Maintain your streak.” 

- **Fair Mode (60 ≤ quality < 75)** → 2 actionable improvement tips + 1 motivational tip. 
Examples: “Sleep 1 more hour to reach target.”, “Limit noise at bedtime.”, “You’re on the right track!” 

- **Poor Mode (40 ≤ quality < 60)** → 3 concise, direct improvement tips. 
Examples: “Sleep 2 hours longer.”, “Go to bed earlier.”, “Avoid late caffeine.” 

- **Very Poor Mode (quality < 40)** → 3 urgent recommendations focused on recovery and behavior reset. 
Examples: “Prioritize at least 7 hours tonight.”, “Reduce evening stimulation.”, “Catch up on rest this week.” 

### ADDITIONAL RULES FOR RECOMMENDATIONS 
- Provide **exactly 3 actionable tips**, ≤15 words each. 
- Avoid assumptions about lifestyle unless shown in data. 
- Avoid vague encouragements like "Keep it up!" unless in Excellent Mode. 
- Each tip must directly reference measureable data from the provided input (duration, sleepDebtHours, streakDays, bedtime, etc.). 
- Never contradict the score (e.g., do not praise if quality < 75 ). 
- Avoid repeating the same advice across different nights unless clearly relevant. 
- If quality <= 60, you must NOT include any positive or congratulatory language. 

### IMPORTANT
You are NOT calculating the quality score, that is done for you.
Ignore any previous "recommendations" values found in the data.
Always compute the new recommendations fresh using the strict rules above.

### USER DATA
${inputJSON}
`;

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${openaiKey}`,
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: `You are an expert in sleep science. session_id=${Date.now()}` },
          { role: "user", content: prompt },
        ],
        temperature: 0.9,
        top_p: 0.95,
      }),
    });

    const data = await response.json();
    console.log("🧠 Raw OpenAI response:", data);
    let parsed;

    try {
      parsed = JSON.parse(data.choices?.[0]?.message?.content ?? "{}");
    } catch (err) {
      console.error("❌ Failed to parse JSON:", err, data);
      parsed = {};
    }

    console.log("🧠 Parsed response:", parsed);

    const recommendations = parsed?.recommendations;

    // ======================================================
    // Update Firestore document
    // ======================================================
    await db.doc(`users/${userId}/sleepLogs/${logId}`).update({
      sleepQuality: quality,
      recommendations
    });

    console.log(`✅ Insights for ${userId}/${logId}: Quality ${quality}, ${recommendations.length} recs`);
    console.log(`✅ Insights generated for ${userId}/${logId}`);
  } catch (err) {
    console.error("❌ Error generating insights:", err);

    // Compute basic duration-based quality if AI call fails
    const start = log.start?.toDate ? log.start.toDate() : new Date(log.start);
    const end = log.end?.toDate ? log.end.toDate() : new Date(log.end);
    const sleepDurationHrs = (end - start) / (1000 * 60 * 60);

    const fallbackQuality = Math.min(100, Math.round((latestDuration / targetHours) * 100));

    // Basic rule-based recommendations
    const fallbackRecs = [];
    if (sleepDurationHrs < targetHours) fallbackRecs.push("Aim for your full sleep target tonight.");
    if (sleepDebtHours > 2) fallbackRecs.push("Try a longer sleep to reduce your weekly debt.");
    if (audioClipsCount > 3) fallbackRecs.push("Reduce disturbances for deeper sleep.");
    if (fallbackRecs.length < 3)
    fallbackRecs.push("Maintain consistent bed and wake times.");

    await db.doc(`users/${userId}/sleepLogs/${logId}`).update({
      sleepQuality: fallbackQuality,
      recommendations: fallbackRecs
    });

    console.warn(`⚠️ Used fallback insights for ${userId}/${logId}`);
  }
});

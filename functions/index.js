/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */
import fetch from "node-fetch";
import { onDocumentCreated, onDocumentDeleted } from "firebase-functions/v2/firestore";
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

export const generateSleepInsights = onDocumentCreated(
  { 
    document: "users/{userId}/sleepLogs/{logId}", 
    secrets: [OPENAI_KEY] 
  },
  async (event) => {
  const data = event.data?.data();
  const { userId, logId } = event.params;

  if (!data?.end) return; // skip incomplete logs

  const db = admin.firestore();
  const openaiKey = OPENAI_KEY.value();

  const log = data;
  const profileSnap = await db.doc(`users/${userId}`).get();
  const profile = profileSnap.exists ? profileSnap.data() : {};
  const age = profile.age || null;
  const targetHours = age < 18 ? 9 : age <= 64 ? 8 : 7.5;
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
        end: l.end,
        sleepQuality: l.sleepQuality,
        recommendations: l.recommendations,
      }));

    // Calculate sleep debt
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    let debtMinutes = 0;

    for (const l of allLogs.filter((x) => new Date(x.end) >= sevenDaysAgo)) {
      const duration = (new Date(l.end) - new Date(l.start)) / 60000;
      const target = targetHours * 60;
      if (duration < target) debtMinutes += target - duration;
      else debtMinutes -= duration - target;
      if (debtMinutes < 0) debtMinutes = 0;
    }
    sleepDebtHours = Math.round(debtMinutes / 60);

    // calculate streak
    const calendar = new Date();
    const daysWithLogs = new Set(
      allLogs
        .filter((l) => l.end && !isNaN(new Date(l.end)))
        .map((l) => new Date(l.end).toISOString().split("T")[0])
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

    const latestDuration = (new Date(latest.end) - new Date(latest.start)) / 3600000;
    if (previous) {
      const prevDuration = (new Date(previous.end) - new Date(previous.start)) / 3600000;
      diff = {
        changeInDurationHrs: +(latestDuration - prevDuration).toFixed(2),
        changeInBedtimeMins: ((new Date(latest.start) - new Date(previous.start)) / 60000).toFixed(0),
        changeInWakeupMins: ((new Date(latest.end) - new Date(previous.end)) / 60000).toFixed(0),
        prevQuality: previous.sleepQuality ?? null,
      };
    }

    const input = {
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
    const inputJSON = JSON.stringify(input, null, 2);
    const prompt = `
You are a certified sleep health expert analyzing a user's recent sleep and lifestyle data.

### PRIMARY OBJECTIVE
Generate a JSON object assessing the user's most recent sleep log and offering three personalized recommendations.

### OUTPUT FORMAT
Respond with **only valid JSON**:
{
  "quality": <integer between 0 and 100>,
  "recommendations": ["tip1", "tip2", "tip3"]
}

### STEP-BY-STEP SCORING LOGIC (MANDATORY)
1. Start from 100 points.
2. Subtract **10 points per full hour** the user's latest sleep (latestDuration) is below targetHours.
3. Subtract **10 points** if sleepDebtHours > 2.
4. Subtract **5 points** if bedtime or wakeup varies by more than 90 minutes compared to recent average.
5. Subtract **10 points** if audioClipsCount > 3 (disturbances).
6. Clamp the result between 0 and 100.
7. Round to the nearest integer and assign this to "quality".

### SCORING INTERPRETATION
- 90–100 → Excellent: target met or exceeded; consistent, low debt.
- 75–89 → Good: small misses or minor irregularity.
- 60–74 → Fair: 1–2 hours below target or moderate inconsistency.
- 40–59 → Poor: 2–3 hours short or irregular.
- 0–39 → Very poor: severe lack of sleep or chaotic schedule.

### RECOMMENDATION RULES
- Provide **exactly 3 actionable tips**, ≤15 words each.
- Each tip must be grounded in the provided data (duration, debt, bedtime/wakeup patterns, activities, etc).
- If sleep was good, provide **positive reinforcement** instead of generic tips.
- Avoid assumptions about lifestyle (e.g. screen use, stress) unless directly shown in data.
- Avoid repeating identical advice or phrasing from prior nights.
- Use the "diff" object to highlight meaningful changes (e.g., “Slept 2h longer”, “Went to bed earlier”).

### CONTEXT GUIDELINES
- Treat bedtime as “late” only if it causes < target sleep hours or adds to sleep debt.
- Treat bedtime as “early” only if it shortens sleep duration.
- Do not assume habits that aren’t logged (e.g., caffeine use).
- Consider the user's age, streakDays, recentSleeps, activities, and audio clips when reasoning.
- Encourage consistency and progress when behavior stabilizes or improves.

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
          { role: "system", content: "You are an expert in sleep science." },
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

    const quality = parsed?.quality;
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
    const sleepDurationHrs =
    (new Date(log.end) - new Date(log.start)) / (1000 * 60 * 60);
    const targetDiff = Math.abs(sleepDurationHrs - targetHours);

    let fallbackQuality;
    if (sleepDurationHrs >= targetHours) fallbackQuality = 90;
    else if (targetDiff < 1) fallbackQuality = 75;
    else if (targetDiff < 2) fallbackQuality = 60;
    else if (targetDiff < 3) fallbackQuality = 45;
    else fallbackQuality = 30;

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

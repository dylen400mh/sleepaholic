/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */
const { onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({ maxInstances: 10 });

exports.deleteUserData = onDocumentDeleted("users/{uid}", async (event) => {
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

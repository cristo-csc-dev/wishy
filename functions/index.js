/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions/v1");
const {setGlobalOptions} = require("firebase-functions");
// const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

const admin = require("firebase-admin");
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({
  maxInstances: 10,
});

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.onNewContactRequest = functions.firestore
    .document("users/{senderUserId}/contactRequests/{recipientUserId}")
    .onCreate(async (snap, context) => {
      const requestData = snap.data();
      const {senderUserId, senderName, senderEmail, recipientUserId,
        recipientName, recipientEmail, message} = requestData;

      // Estructura de la notificación para el usuario receptor.
      const newNotification = {
        type: "contactRequest",
        title: `Nueva solicitud de contacto de 
          ${senderName || ""} (${senderEmail})`,
        message: message,
        senderUserId: senderUserId,
        senderName: senderName,
        senderEmail: senderEmail,
        recipientUserId: recipientUserId,
        recipientName: recipientName,
        recipientEmail: recipientEmail,
        status: "pending",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
      };

      const notificationRef = admin.firestore()
          .collection(`users/${recipientUserId}/notifications`);

      await notificationRef.add(newNotification);

      logger.info(
          `Notificación creada para ${recipientUserId} por ${senderUserId}`,
      );
    });

exports.onContactRequestStatusUpdate = functions.firestore
    // Se dispara cada vez que un documento en 'notifications' es actualizado.
    .document("users/{userId}/notifications/{notificationId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();

      if (after.type !== "contactRequest" || before.status === after.status) {
        return null;
      }
      const recipientId = context.params.userId;
      const senderId = after.senderId;
      const newStatus = after.status;
      if (!senderId) {
        logger.error(
            `ERROR: Notificación ${context.params.notificationId} 
            no tiene senderId.`,
        );
        return null;
      }

      const addedAt = admin.firestore.FieldValue.serverTimestamp();
      const recipientContactData = {
        name: after.senderName,
        email: after.senderEmail,
        createdAt: addedAt,
      };
      const senderContactData = {
        name: after.recipientName,
        email: after.recipientEmail,
        createdAt: addedAt,
      };

      if (newStatus === "accepted") {
        await Promise.all([
          await admin
              .firestore()
              .doc(`users/${recipientId}/contacts/${senderId}`)
              .set(recipientContactData, {merge: true}),
          await admin
              .firestore()
              .doc(`users/${senderId}/contacts/${recipientId}`)
              .set(senderContactData, {merge: true}),
        ]);

        logger
            .info(`Contactos creados (bidireccional) entre ${recipientId} y 
              ${senderId}`, {
              recipient: recipientId,
              sender: senderId,
              status: newStatus,
            });

        const recipientContactName =
          recipientContactData.name || recipientContactData.email;
        const newNotification = {
          type: "contactAccepted",
          title: "Solicitud de contacto aceptada",
          message: `${recipientContactName} ha aceptado tu solicitud.`,
          senderId: recipientId,
          status: "pending",
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
        };

        const notificationRef = admin.firestore()
            .collection(`users/${senderId}/notifications`);
        await notificationRef.add(newNotification);
      } else if (newStatus === "rejected") {
        await admin
            .firestore()
            .doc(`users/${senderId}/contactRequests/${recipientId}`)
            .delete()
            .catch((e) => {});

        logger.info(`Contactos eliminados/descartados entre 
          ${recipientId} y ${senderId}`, {
          recipient: recipientId,
          sender: senderId,
          status: newStatus,
        });
      }
      change.after.ref.delete().catch((e) => {});
      admin
          .firestore()
          .doc(`users/${senderId}/contacts/${recipientId}`)
          .delete()
          .catch((e) => {});

      return null;
    });

/**
 * Trigger: cuando un contact se crea/actualiza/elimina para un usuario,
 * recalcula sharedWithMe de ese usuario.
 */
exports.recomputeSharedWithMeOnContactsChange = functions.firestore
    .document("users/{userId}/contacts/{contactId}")
    .onWrite(async (change, context) => {
      const userId = context.params.userId;
      try {
        await recomputeSharedWithMe(userId);
        return null;
      } catch (err) {
        functions.logger.error(
            "Error recomputing sharedWithMe for", userId, err,
        );
        throw err;
      }
    });

exports.recomputeSharedWithMeOnWishlistsChange = functions.firestore
    .document("users/{userId}/wishlists/{wishlistId}")
    .onWrite(async (change, context) => {
      const userId = context.params.userId;
      try {
        const after = change.after.data();
        (after.sharedWithContactIds || []).forEach(async (contactId) => {
          await recomputeSharedWithMe(contactId);
        });
        return null;
      } catch (err) {
        functions.logger.error(
            "Error recomputing sharedWithMe for", userId, err,
        );
        throw err;
      }
    });

/**
 * Recalcula el campo sharedWithMe para un usuario dado.
 * @param {userId} userId
 * @return {void}
 */
async function recomputeSharedWithMe(userId) {
  const previousSharedWithMeIds = admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("sharedWithMe")
      .get()
      .map((doc) => doc.id);
  const contactsRef = admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("contacts")
      .where("status", "==", "accepted");
  const contactsSnap = await contactsRef.get();

  if (contactsSnap.empty) {
    await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .update({
          sharedWithMe: [],
          sharedWithMeLastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        });
    return;
  }

  const wishlistEntries = {};
  const includedSharedWithMeIds = new Set();

  for (const contactDoc of contactsSnap.docs) {
    const contactId = contactDoc.id;
    const name =
      contactDoc.data().name || contactDoc.data().email;

    // Consulta las wishlists del contacto que estén compartidas con userId
    const wlSnap = await admin
        .firestore()
        .doc(contactId)
        .collection("wishlists")
        .where("sharedWithContactIds", "array-contains", userId)
        .get();

    for (const doc of wlSnap.docs) {
      const data = doc.data();
      const sharedDoc = admin.firestore()
          .collection("users")
          .doc(userId)
          .collection("sharedWithMe")
          .doc(doc.id);
      sharedDoc.set({
        id: doc.id,
        name: data.name || "",
        ownerId: data.ownerId || contactId,
        ownerName: name,
        privacy: data.privacy || "",
        // añade aquí otros campos si los necesitas
        path: doc.ref.path,
        ref: doc.ref,
      }, {merge: true});
      includedSharedWithMeIds.add(doc.id);
    }
    previousSharedWithMeIds
        .difference(includedSharedWithMeIds)
        .forEach(async (removedId) => {
          const removedDoc = admin.firestore()
              .collection("users")
              .doc(userId)
              .collection("sharedWithMe")
              .doc(removedId);
          await removedDoc.delete();
        });
  }
  const sharedWithMeArray = Array.from(wishlistEntries.values());
  await admin
      .firestore()
      .collection("users").doc(userId).update({
        sharedWithMe: sharedWithMeArray,
        sharedWithMeLastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      });
}

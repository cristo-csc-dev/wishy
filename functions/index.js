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
    .document("users/{recipientUserId}/contactRequests/{senderUserId}")
    .onCreate(async (snap, context) => {
      const requestData = snap.data();
      const {recipientUserId, senderUserId, senderName} = requestData;

      // Estructura de la notificación para el usuario receptor.
      const newNotification = {
        type: "contactRequest",
        title: "Nueva solicitud de contacto",
        message: `${senderName} quiere añadirte a sus contactos.`,
        senderId: senderUserId,
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

      const recipientContactRef = admin
          .firestore()
          .doc(`users/${recipientId}/contacts/${senderId}`);
      const senderContactRef = admin
          .firestore()
          .doc(`users/${senderId}/contacts/${recipientId}`);
      if (newStatus === "accepted") {
        const contactData = {
          addedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        await Promise.all([
          recipientContactRef.set(contactData),
          senderContactRef.set(contactData),
        ]);

        logger
            .info(`Contactos creados (bidireccional) entre ${recipientId} y 
              ${senderId}`, {
              recipient: recipientId,
              sender: senderId,
              status: newStatus,
            });
      } else if (newStatus === "rejected") {
        await Promise.all([
          recipientContactRef.delete().catch((e) => {}),
          senderContactRef.delete().catch((e) => {})
        ]);

        logger.info(`Contactos eliminados/descartados entre 
          ${recipientId} y ${senderId}`, {
          recipient: recipientId,
          sender: senderId,
          status: newStatus,
        });
      }
      return null;
    });

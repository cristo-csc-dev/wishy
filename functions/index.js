const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {getFirestore} = require("firebase-admin/firestore");
const admin = require("firebase-admin");
const functions = require("firebase-functions/v1");
const logger = require("firebase-functions/logger");


admin.initializeApp();
const db = getFirestore();

// Escuchamos los cambios en el nivel más profundo: los ítems
exports.syncItemsToGlobalList =
  onDocumentWritten("users/{userId}/wishlists/{wishlistId}/items/{itemId}",
      async (event) => {
        // Extraemos los IDs de la ruta
        const {userId, wishlistId, itemId} = event.params;
        // Referencia al documento en la colección aplanada global
        // Usamos el itemId como ID del documento para evitar duplicados
        const globalRef = db.collection("all_wishes_global").doc(itemId);

        // 1. Manejo de ELIMINACIÓN
        if (!event.data.after.exists) {
          await globalRef.delete();
          console.log(`Ítem ${itemId} eliminado de la lista global.`);
          return;
        }

        // 2. Manejo de CREACIÓN o ACTUALIZACIÓN
        const itemData = event.data.after.data();
        // Aplanamos la información
        await globalRef.set({
          ...itemData,
          itemId: itemId,
          originalWishlistId: wishlistId,
          ownerId: userId,
          flattenedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});

        console.log(
            `Ítem ${itemId} de la lista ${wishlistId} sincronizado globalmente`,
        );
      });

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

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

exports.actualizarColeccion = functions.firestore
    .document("users/{userId}/contacts/{contactId}")
    .onCreate((snapshot, context) => {
      logger.log("Se ha creado un nuevo contacto");
      // La función se ejecuta cuando un documento se actualiza
      // 'change' contiene el estado del documento 'antes' y
      // 'después' de la actualización
      // const newValue = change.after.data();
      // const previousValue = change.before.data();

      // Lógica para actualizar la otra colección
      // Aquí puedes usar el SDK de Admin de Firestore

      const db = admin.firestore();

      logger.debug("Context.params:", context.params);

      db.collection("users")
          .doc(context.params.contactId)
          .collection("notifications").add({
            type: "contactRequest",
            receiver: context.params.contactId,
            sender: {
              uid: context.params.userId,
              name: snapshot.data().name,
              email: snapshot.data().email,
            },
            message: snapshot.data().message || "",
            // Puedes agregar más campos según sea necesario
            ref: snapshot.ref,
            read: false,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            // Puedes agregar más campos según sea necesario
          },
          );
    },
    );

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.addClient = functions.https.onCall((data, context) => {
  // Ensure the user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Only authenticated users can add clients.');
  }

  // Extract client details from data
  const { email, password, firstName, lastName } = data;

  // Create a new user and add their details to Firestore
  return admin.auth().createUser({
    email: email,
    password: password
  })
  .then(userRecord => {
    return admin.firestore().collection('users').doc(userRecord.uid).set({
      firstName: firstName,
      lastName: lastName,
      email: email,
      uid: userRecord.uid,
    });
  })
  .then(() => {
    return { message: 'Client added successfully!' };
  })
  .catch(error => {
    throw new functions.https.HttpsError('unknown', error.message);
  });
});

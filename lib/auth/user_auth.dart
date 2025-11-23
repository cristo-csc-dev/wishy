import 'package:firebase_auth/firebase_auth.dart';

class UserAuth {

  static Future<UserCredential> signIn(String user, String password) async {
    return _getInstance().signInWithEmailAndPassword(
      email: user,
      password: password,
    );
  }

  static bool isUserAuthenticated() {
    return _getInstance().currentUser != null;
  }

  static bool isUserAuthenticatedAndVerified() {
    if(_getInstance().currentUser != null) {
      return _getInstance().currentUser!.emailVerified;
      // return true;
    }
    return false;
  }

  static User getCurrentUser() {
    if (_getInstance().currentUser == null) {
      throw Exception('Usuario no autenticado.');
    }
    return FirebaseAuth.instance.currentUser!;
  }

  static FirebaseAuth _getInstance() {
    return FirebaseAuth.instance;
  }

  static void sendEmailVerification(UserCredential userCredential) {
    userCredential.user!.sendEmailVerification();
  }
}
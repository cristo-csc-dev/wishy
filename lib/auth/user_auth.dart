import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class UserAuth extends ChangeNotifier {

  // 1. Creamos una instancia estática privada (la única que existirá)
  static final UserAuth _instance = UserAuth._internal();

  // 2. Constructor privado para evitar que se creen más instancias por error
  UserAuth._internal();

  // 3. Factory para que al llamar AuthService() siempre devuelva la misma instancia
  factory UserAuth() {
    return _instance;
  }
  
  // 4. Getter estático para acceso rápido (Opcional pero recomendado)
  static UserAuth get instance => _instance;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<UserCredential> signIn(String user, String password) async {
    UserCredential userCredential = await _getInstance().signInWithEmailAndPassword(
      email: user,
      password: password,
    );
    _isAuthenticated = true;
    notifyListeners();
    return userCredential;
  }

  bool isUserAuthenticated() {
    return _getInstance().currentUser != null;
  }

  bool isUserAuthenticatedAndVerified() {
    if(_getInstance().currentUser != null) {
      return _getInstance().currentUser!.emailVerified;
      // return true;
    }
    return false;
  }

  User getCurrentUser() {
    if (_getInstance().currentUser == null) {
      throw Exception('Usuario no autenticado.');
    }
    return FirebaseAuth.instance.currentUser!;
  }

  FirebaseAuth _getInstance() {
    return FirebaseAuth.instance;
  }

  void sendEmailVerification(UserCredential userCredential) {
    userCredential.user!.sendEmailVerification();
  }

  void signOut() async {
    await FirebaseAuth.instance.signOut();
    _isAuthenticated = false;
    notifyListeners();
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wishy/auth/user_auth.dart';
import 'firebase_options.dart';
import 'package:wishy/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wishy/services/contacts_manager.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {

  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
    // Escuchar cambios de estado de autenticación para cargar/limpiar contactos
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        ContactsManager.instance.loadForCurrentUser();
        ContactsManager.instance.startRealtimeUpdates();
      } else {
        ContactsManager.instance.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp.router(
      title: 'My Wishlist',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blueGrey,
        ),
      ),
      routerConfig: getRouter(UserAuth.instance),
    );
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wishy/auth/user_auth.dart';
import 'package:wishy/screens/login/login_screen.dart';
import 'firebase_options.dart'; // Importa el archivo de opciones de Firebase
import 'package:wishy/screens/home_screen.dart';
import 'package:wishy/routes.dart';

// 1. CLAVE GLOBAL: Define una clave global para acceder al NavigatorState desde cualquier lugar.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {

  // Asegura que los widgets de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con las opciones de la plataforma actual
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
      // home: StreamBuilder<User?>(
      //   stream: FirebaseAuth.instance.authStateChanges(),
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return const Scaffold(
      //         body: Center(child: CircularProgressIndicator()),
      //       );
      //     }
      //     if (snapshot.hasData) {
      //         return const HomeScreen();
      //     }
      //     return const LoginScreen();
      //   },
      // ),
    );
  }
}
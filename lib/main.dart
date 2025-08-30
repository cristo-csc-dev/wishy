import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart'; // Importa el archivo de opciones de Firebase
import 'package:wishy/screens/home_screen.dart';
import 'dart:developer' as dev;

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

  String _sharedLink = "{}";
  static const platform = MethodChannel('com.wishysa.wishy/channel');

  @override
  void initState() {
    super.initState();
    // WishDao().deleteAllWishes();
    platform.setMethodCallHandler(_handleMethodCalls);
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
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
      home: const HomeScreen(), // La pantalla de inicio de la aplicación
    );
  }

  Future<void> _handleMethodCalls(MethodCall call) async {
    if (call.method == 'onSharedText') {
      _sharedLink = call.arguments;
      final Map<String, dynamic> jsonData = jsonDecode(_sharedLink);
      dev.log("Received shared text: $jsonData");
    }
  }

}
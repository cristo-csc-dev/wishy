// Importaciones necesarias
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Componente de la pantalla de perfil
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Función para cerrar la sesión del usuario
  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Después de cerrar sesión, puedes navegar a la pantalla de inicio o de login.
      // Aquí se asume que tienes una pantalla de login y que el Navigator
      // está configurado para manejar la navegación.
      Navigator.of(context).pushReplacementNamed('/');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener la información del usuario actual
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Usuario'),
        backgroundColor: Colors.indigo.shade500,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Muestra el nombre de usuario o el correo electrónico
              Text(
                'Hola, ${user?.displayName ?? user?.email ?? 'Usuario'}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Botón para cerrar la sesión
              ElevatedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

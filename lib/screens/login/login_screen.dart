import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wishy/auth/user_auth.dart';
import 'package:wishy/dao/user_dao.dart';
import 'package:wishy/utils/message_utils.dart';
import 'create_user_screen.dart'; // Importa la nueva pantalla de creación

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signInWithEmailAndPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await UserAuth.instance.signIn(
        _emailController.text,
        _passwordController.text,
      );

      if(await UserDao().getUserById(UserAuth.instance.getCurrentUser().uid) == null) {
        await UserDao().createUser(_auth.currentUser!.uid, _emailController.text, _auth.currentUser!.displayName ?? "Sin nombre");
      }

    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Usuario o contraseña incorrectos.';
      } else {
        message = 'Error: ${e.message}';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
        backgroundColor: Colors.indigo.shade500,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bienvenido. Por favor, inicia sesión para continuar.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _signInWithEmailAndPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Iniciar sesión'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _showCreateUserScreen(context);
              },
              child: const Text('¿No tienes una cuenta? Crea una aquí'),
            ),
            if (MessageUtils.hasMessage()) ...[Text(
              MessageUtils.getMessage(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),]
          ],
        ),
      ),
    );
  }

  void _showCreateUserScreen(BuildContext context) async {
    Navigator.push(context,
      MaterialPageRoute(
        builder: (context) => const CreateUserScreen(),
      ),
    );
  }
}

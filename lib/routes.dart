import 'package:go_router/go_router.dart';
import 'package:wishy/auth/user_auth.dart';
import 'package:wishy/screens/contacts/contact_list_screen.dart';
import 'package:wishy/screens/contacts/friend_list_overview_screen.dart';
import 'package:wishy/screens/home_screen.dart';
import 'package:wishy/screens/login/login_screen.dart';
import 'package:wishy/screens/user/user_profile_screen.dart';

 GoRouter getRouter(UserAuth userAuth) => GoRouter(

  initialLocation: '/',
  refreshListenable: userAuth, // URL por defecto al abrir la app
  redirect: (context, state) {
    final isLoggedIn = userAuth.isAuthenticated;
    final isGoingToLogin = state.uri.toString() == '/login';

    // CASO 1: No está logueado y no está en el login -> Mandar a Login
    if (!isLoggedIn && !isGoingToLogin) {
      return '/login';
    }

    // CASO 2: Ya está logueado e intenta ir al login -> Mandar a Home
    if (isLoggedIn && isGoingToLogin) {
      return '/';
    }

    // CASO 3: No hace falta redirección
    return null;
  },
  routes: [
    // Ruta Raíz: http://midominio.com/
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        // Ruta Hija: http://midominio.com/profile
        GoRoute(
          path: '/settings',
          builder: (context, state) => const UserProfileScreen(),
        ),

        GoRoute(
          path: '/contacts',
          builder: (context, state) => const ContactsListScreen(),
          routes: [
            GoRoute(
              path: '/:contactId',
              builder: (context, state) {
                // Extraemos el parámetro de la URL
                final contactId = state.pathParameters['contactId']; 
                return FriendListsOverviewScreen(contactId: contactId!);
              },
            ),
          ],
        ),
      ]
    ),

     GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    
  ],
);
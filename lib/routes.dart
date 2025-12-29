import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wishy/auth/user_auth.dart';
import 'package:wishy/screens/contacts/contact_list_screen.dart';
import 'package:wishy/screens/contacts/create_contact_request_screen.dart';
import 'package:wishy/screens/contacts/edit_contact_screen.dart';
import 'package:wishy/screens/contacts/friend_list_overview_screen.dart';
import 'package:wishy/screens/home_screen.dart';
import 'package:wishy/screens/login/create_user_screen.dart';
import 'package:wishy/screens/login/login_screen.dart';
import 'package:wishy/screens/under_construction/under_construction_screen.dart';
import 'package:wishy/screens/user/user_profile_screen.dart';
import 'package:wishy/screens/wish/add_wish_screen.dart';
import 'package:wishy/screens/wish/create_edit_list_screen.dart';
import 'package:wishy/screens/wish/list_detail_screen.dart';
import 'package:wishy/screens/wish/wish_detail_screen.dart';
import 'package:wishy/utils/platform_type.dart';


const invitationUids = [
  'e4a7a2a0-42b8-4c71-8e27-add3f0c9b495',
  '3d3f8f6a-8b4c-4a1b-9c1d-1e1f2a3b4c5d',
  'a1b2c3d4-e5f6-a7b8-c9d0-e1f2a3b4c5d6',
  'f8c3c2e0-6c3a-4b1d-8e6b-8c6f2b8a9f3e',
  'b9e8f7d6-c5b4-4a3b-2a1c-0e9d8c7b6a5f'
];

GoRouter getRouter(UserAuth userAuth) => GoRouter(

  initialLocation: '/',
  refreshListenable: userAuth, // URL por defecto al abrir la app
  redirect: (context, state) {
    final isLoggedIn = userAuth.isAuthenticated;
    final isGoingToLogin = state.uri.toString() == '/login';

    // if(!isLoggedIn && 
    //   PlatformHelper.currentPlatformType == PlatformType.web &&
    //   !(invitationUids.contains(state.uri.queryParameters['invitationUid']))) {
    //   return '/underConstruction';
    // }

    if(!isLoggedIn && isGoingToLogin) {
      return null; // Permitir ir al login si no está logueado
    } 

    // CASO 1: No está logueado y no está en el login -> Mandar a Login
    if (!isLoggedIn && !isGoingToLogin) {
      return '/login';
    }

    // CASO 2: Ya está logueado e intenta ir al login -> Mandar a Home
    if (isLoggedIn && isGoingToLogin) {
      return '/home';
    }

    // CASO 3: No hace falta redirección
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    // Home
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: '/signup',
          builder: (context, state) => const CreateUserScreen(),
        ),

        // Perfil de usuario
        GoRoute(
          path: '/profile',
          builder: (context, state) => const UserProfileScreen(),
        ),

        // Contactos
        GoRoute(
          path: '/contacts',
          builder: (context, state) => const ContactsListScreen(),
          routes: [
            GoRoute(
              path: '/add',
              builder: (context, state) => const CreateContactRequestScreen(),
            ),
            GoRoute(
              path: '/:contactId',
              builder: (context, state) {
                final contactId = state.pathParameters['contactId'] ?? '';
                return FriendListsOverviewScreen(contactId: contactId);
              },
              routes: [
                GoRoute(
                  path: '/edit',
                  builder: (context, state) {
                    final contactId = state.pathParameters['contactId'] ?? '';
                    return EditContactScreen(contactId: contactId);
                  },
                ),
                GoRoute(
                  path: '/lists/:wishlistId',
                  builder: (context, state) {
                    final contactId = state.pathParameters['contactId'] ?? '';
                    final wishlistId = state.pathParameters['wishlistId'] ?? '';
                    return ListDetailScreen(userId: contactId, wishListId: wishlistId);
                  },
                  routes: [
                    GoRoute(
                      path: '/wishes/:wishId/detail',
                      builder: (context, state) {
                        final contactId = state.pathParameters['contactId'] ?? '';
                        final wishlistId = state.pathParameters['wishlistId'] ?? '';
                        final wishItem = state.pathParameters['wishId'] ?? '';
                        return WishDetailScreen(userId: contactId, wishListId: wishlistId, wishItemId: wishItem);
                      },
                    ),
                  ]
                ),
              ],
            ),
          ],
        ),
        // Listas de deseos
        GoRoute(
          path: '/wishlist/add',
          builder: (context, state) => const CreateEditListScreen(),
        ),
        GoRoute(
          path: '/wishlist/:wishlistId',
          builder: (context, state) {
            final wishListId = state.pathParameters['wishlistId'] ?? '';
            return ListDetailScreen(
              wishListId: wishListId,
              userId: UserAuth.instance.getCurrentUser().uid,
            );
          },
          routes: [
            GoRoute(
              path: '/edit',
              builder: (context, state) {
                final wishListId = state.pathParameters['wishlistId'] ?? '';
                return CreateEditListScreen(wishListId: wishListId);
              },
            ),
            GoRoute(
              path: '/wish/add',
              builder: (context, state) {
                final wishListId = state.pathParameters['wishlistId'] ?? '';
                return AddWishScreen(wishListId: wishListId);
              },
            ),
            GoRoute(
              path: '/wish/:wishId/edit',
              builder: (context, state) {
                final wishListId = state.pathParameters['wishlistId'] ?? '';
                final wishId = state.pathParameters['wishId'] ?? '';
                return AddWishScreen(
                  wishItemId: wishId,
                  wishListId: wishListId,
                );
              },
            ),
          ]
        ),
      ],
    ),
    GoRoute(
      path: '/underConstruction',
      builder: (context, state) {
        return const UnderConstructionPage();
      }
    ),
  ],
);
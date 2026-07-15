import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/parlour_provider.dart';

// Import Screens
import 'screens/onboarding/get_started_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/customer/dashboard_screen.dart';
import 'screens/customer/services_screen.dart';
import 'screens/customer/book_appointment_screen.dart';
import 'screens/customer/service_details_screen.dart';
import 'screens/customer/quiz_screen.dart';
import 'screens/customer/loyalty_screen.dart';
import 'screens/customer/gift_cards_screen.dart';
import 'screens/customer/checkout_screen.dart';
import 'screens/customer/payment_confirm_screen.dart';
import 'screens/customer/appointments_screen.dart';
import 'screens/customer/profile_screen.dart';
import 'screens/owner/dashboard_screen.dart';
import 'screens/owner/happening_now_screen.dart';
import 'screens/owner/requests_screen.dart';
import 'screens/owner/schedule_screen.dart';
import 'screens/owner/services_screen.dart';
import 'screens/owner/service_details_screen.dart';
import 'screens/owner/directory_screen.dart';
import 'screens/owner/customer_profile_screen.dart';

class ParlourApp extends StatelessWidget {
  const ParlourApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final GoRouter router = GoRouter(
      initialLocation: '/',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggingIn = state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup' ||
            state.matchedLocation == '/forgot-password' ||
            state.matchedLocation == '/';

        final user = auth.currentUser;
        final perspective = auth.currentPerspective;

        if (user != null && loggingIn) {
          if (perspective == 'owner') {
            return '/owner/dashboard';
          } else {
            return '/customer/dashboard';
          }
        }

        if (user == null && !loggingIn) {
          return '/login';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const GetStartedScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/customer/dashboard',
          builder: (context, state) => const CustomerDashboardScreen(),
        ),
        GoRoute(
          path: '/customer/services',
          builder: (context, state) => const CustomerServicesScreen(),
        ),
        GoRoute(
          path: '/customer/quiz',
          builder: (context, state) => const CustomerQuizScreen(),
        ),
        GoRoute(
          path: '/customer/service-details',
          builder: (context, state) {
            final id = state.uri.queryParameters['id'] ?? '';
            return ServiceDetailsScreen(serviceId: id);
          },
        ),
        GoRoute(
          path: '/customer/book-appointment',
          builder: (context, state) => const BookAppointmentScreen(),
        ),
        GoRoute(
          path: '/customer/loyalty',
          builder: (context, state) => const CustomerLoyaltyScreen(),
        ),
        GoRoute(
          path: '/customer/gift-cards',
          builder: (context, state) => const CustomerGiftCardsScreen(),
        ),
        GoRoute(
          path: '/customer/checkout',
          builder: (context, state) => const CustomerCheckoutScreen(),
        ),
        GoRoute(
          path: '/customer/payment-confirm',
          builder: (context, state) {
            final id = state.uri.queryParameters['id'] ?? '';
            return PaymentConfirmScreen(bookingId: id);
          },
        ),
        GoRoute(
          path: '/customer/appointments',
          builder: (context, state) {
            final tab = state.uri.queryParameters['tab'] ?? 'upcoming';
            return CustomerAppointmentsScreen(initialTab: tab);
          },
        ),
        GoRoute(
          path: '/customer/profile',
          builder: (context, state) => const CustomerProfileScreen(),
        ),
        GoRoute(
          path: '/owner/dashboard',
          builder: (context, state) => const OwnerDashboardScreen(),
        ),
        GoRoute(
          path: '/owner/happening-now',
          builder: (context, state) => const OwnerHappeningNowScreen(),
        ),
        GoRoute(
          path: '/owner/requests',
          builder: (context, state) => const OwnerRequestsScreen(),
        ),
        GoRoute(
          path: '/owner/schedule',
          builder: (context, state) => const OwnerScheduleScreen(),
        ),
        GoRoute(
          path: '/owner/services',
          builder: (context, state) => const OwnerServicesScreen(),
        ),
        GoRoute(
          path: '/owner/service-details/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return OwnerServiceDetailsScreen(serviceId: id);
          },
        ),
        GoRoute(
          path: '/owner/directory',
          builder: (context, state) => const OwnerDirectoryScreen(),
        ),
        GoRoute(
          path: '/owner/customer-profile/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return OwnerCustomerProfileScreen(customerId: id);
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: "Selvi's Beauty Parlour",
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return ResponsivePhoneFrame(child: child);
      },
    );
  }
}

class ResponsivePhoneFrame extends StatelessWidget {
  final Widget child;

  const ResponsivePhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If screen width is mobile-sized, render normally (full screen)
        if (constraints.maxWidth < 600) {
          return child;
        }

        // On desktop web preview, wrap inside a premium phone frame mockup
        return Scaffold(
          backgroundColor: const Color(0xFF161421), // Premium dark background
          body: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              width: 393, // iPhone screen width
              height: 852, // iPhone screen height
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(44),
                border: Border.all(color: const Color(0xFF2E2E3A), width: 12), // Device bezel frame
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.55),
                    blurRadius: 36,
                    spreadRadius: 4,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

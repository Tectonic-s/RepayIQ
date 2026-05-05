import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/loans/domain/entities/loan.dart';
import '../../features/loans/presentation/screens/my_loans_screen.dart';
import '../../features/loans/presentation/screens/add_edit_loan_screen.dart';
import '../../features/loans/presentation/screens/loan_type_chooser_screen.dart';
import '../../features/loans/presentation/screens/add_existing_loan_screen.dart';
import '../../features/loans/presentation/screens/loan_detail_screen.dart';
import '../../features/loans/presentation/screens/amortisation_screen.dart';
import '../../features/loans/presentation/screens/prepayment_screen.dart';
import '../../features/emi_calculator/presentation/screens/emi_calculator_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/score/presentation/screens/score_screen.dart';
import '../../features/budget/presentation/screens/budget_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/family/presentation/screens/family_screen.dart';
import '../../features/documents/presentation/screens/document_vault_screen.dart';
import '../../features/ai/presentation/screens/ai_copilot_screen.dart';
import '../../features/payments/presentation/screens/past_payments_screen.dart';
import '../../features/payments/presentation/screens/payment_confirm_screen.dart';
import '../../features/tools/presentation/screens/tools_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/edit_profile_screen.dart';
import '../../features/onboarding/presentation/screens/welcome_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import '../../shared/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final l = loc(state);
      
      // Never redirect away from splash — it handles its own navigation
      if (l == '/') return null;
      
      // Let auth routes load without interference
      if (authState.isLoading) return null;
      
      final isAuthenticated = authState.value != null;
      final isAuthRoute = l == '/login' || l == '/forgot-password' || l == '/welcome' || l == '/onboarding';
      
      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (ctx, st) => _fadePage(st, const SplashScreen()),
      ),
      GoRoute(
        path: '/welcome',
        pageBuilder: (ctx, st) => CustomTransitionPage(
          key: st.pageKey,
          child: const WelcomeScreen(),
          transitionDuration: const Duration(milliseconds: 700),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (ctx, st) => CustomTransitionPage(
          key: st.pageKey,
          child: const OnboardingFlowScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic)),
              child: FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (ctx, st) => CustomTransitionPage(
          key: st.pageKey,
          child: const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (ctx, st) => _fadePage(st, const ForgotPasswordScreen()),
      ),

      ShellRoute(
        pageBuilder: (ctx, st, child) => _fadePage(st, MainShell(child: child)),
        routes: [
          GoRoute(path: '/home', builder: (ctx, st) => const HomeScreen()),
          GoRoute(path: '/calculator', builder: (ctx, st) => const EmiCalculatorScreen()),
          GoRoute(path: '/dashboard', builder: (ctx, st) => const DashboardScreen()),
          GoRoute(path: '/tools', builder: (ctx, st) => const ToolsScreen()),
          GoRoute(path: '/settings', builder: (ctx, st) => const SettingsScreen()),
        ],
      ),

      // Full-screen routes
      GoRoute(
        path: '/loans',
        pageBuilder: (ctx, st) => _slideRightPage(st, const MyLoansScreen()),
      ),
      GoRoute(
        path: '/reports',
        pageBuilder: (ctx, st) => _slideUpPage(st, const ReportsScreen()),
      ),
      GoRoute(
        path: '/score',
        pageBuilder: (ctx, st) => _slideUpPage(st, const ScoreScreen()),
      ),
      GoRoute(
        path: '/budget',
        pageBuilder: (ctx, st) => _slideUpPage(st, const BudgetScreen()),
      ),
      GoRoute(
        path: '/calendar',
        pageBuilder: (ctx, st) => _slideUpPage(st, const CalendarScreen()),
      ),
      GoRoute(
        path: '/family',
        pageBuilder: (ctx, st) => _slideUpPage(st, const FamilyScreen()),
      ),
      GoRoute(
        path: '/ai',
        pageBuilder: (ctx, st) => _slideUpPage(st, const AiCopilotScreen()),
      ),
      GoRoute(
        path: '/payment-confirm/:loanId',
        pageBuilder: (ctx, st) => _slideRightPage(
          st,
          PaymentConfirmScreen(loanId: st.pathParameters['loanId']!),
        ),
      ),
      GoRoute(
        path: '/past-payments',
        pageBuilder: (ctx, st) => _slideRightPage(
          st,
          PastPaymentsScreen(loan: st.extra as Loan),
        ),
      ),
      GoRoute(
        path: '/settings/edit-profile',
        pageBuilder: (ctx, st) => _slideRightPage(st, const EditProfileScreen()),
      ),
      // /loans/add now shows the chooser screen
      GoRoute(
        path: '/loans/add',
        pageBuilder: (ctx, st) => _slideUpPage(st, const LoanTypeChooserScreen()),
      ),
      GoRoute(
        path: '/loans/add/new',
        pageBuilder: (ctx, st) => _slideRightPage(
          st,
          AddEditLoanScreen(prefill: st.extra as Map<String, dynamic>?),
        ),
      ),
      GoRoute(
        path: '/loans/add/existing',
        pageBuilder: (ctx, st) => _slideRightPage(st, const AddExistingLoanScreen()),
      ),
      GoRoute(
        path: '/loans/:id',
        pageBuilder: (ctx, st) => _slideRightPage(
          st,
          LoanDetailScreen(loanId: st.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/loans/:id/edit',
        pageBuilder: (ctx, st) => _slideRightPage(
          st,
          AddEditLoanScreen(loan: st.extra as Loan?),
        ),
      ),
      GoRoute(
        path: '/loans/:id/amortisation',
        pageBuilder: (ctx, st) => _slideUpPage(
          st,
          AmortisationScreen(loan: st.extra as Loan),
        ),
      ),
      GoRoute(
        path: '/loans/:id/prepayment',
        pageBuilder: (ctx, st) => _slideUpPage(
          st,
          PrepaymentScreen(loan: st.extra as Loan),
        ),
      ),
      GoRoute(
        path: '/loans/:id/documents',
        pageBuilder: (ctx, st) => _slideRightPage(
          st,
          DocumentVaultScreen(
            loanId: st.pathParameters['id']!,
            loanName: (st.extra as String?) ?? 'Loan',
          ),
        ),
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});

String loc(GoRouterState state) => state.matchedLocation;

/// Fade transition page — used for splash → home/login to avoid slide animation
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

/// Slide up transition — used for modal-like screens
CustomTransitionPage<void> _slideUpPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      );
    },
  );
}

/// Slide right transition — used for detail/edit screens
CustomTransitionPage<void> _slideRightPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

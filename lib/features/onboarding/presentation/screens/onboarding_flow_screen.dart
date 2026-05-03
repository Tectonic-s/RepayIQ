import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../domain/entities/user_profile.dart';
import '../../data/datasources/user_profile_local_datasource.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Form data
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _incomeCtrl = TextEditingController();
  final _expensesCtrl = TextEditingController();
  bool _enableReminders = true;
  bool _enableAiNudges = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _incomeCtrl.dispose();
    _expensesCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    try {
      // Create account
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      // Save profile
      final profile = UserProfile(
        userId: credential.user!.uid,
        monthlyIncome: double.tryParse(_incomeCtrl.text) ?? 0,
        monthlyExpenses: double.tryParse(_expensesCtrl.text) ?? 0,
        debtFreeGoalDate: null,
        enableReminders: _enableReminders,
        enableAiNudges: _enableAiNudges,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await UserProfileLocalDataSource().upsertUserProfile(profile);

      // Mark welcome as seen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_welcome', true);

      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    GestureDetector(
                      onTap: _previousPage,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.arrow_back, size: 18,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentPage + 1) / 4,
                        minHeight: 6,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentPage + 1}/4',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _SignUpPage(emailCtrl: _emailCtrl, passwordCtrl: _passwordCtrl),
                  _IncomePage(incomeCtrl: _incomeCtrl),
                  _ExpensesPage(expensesCtrl: _expensesCtrl),
                  _PreferencesPage(
                    enableReminders: _enableReminders,
                    enableAiNudges: _enableAiNudges,
                    onRemindersChanged: (v) => setState(() => _enableReminders = v),
                    onAiNudgesChanged: (v) => setState(() => _enableAiNudges = v),
                  ),
                ],
              ),
            ),
            // Next button
            Padding(
              padding: const EdgeInsets.all(20),
              child: PrimaryButton(
                label: _currentPage == 3 ? 'Complete Setup' : 'Continue',
                onPressed: _nextPage,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Page 1: Sign Up
class _SignUpPage extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  const _SignUpPage({required this.emailCtrl, required this.passwordCtrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Account',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Let\'s start by setting up your account',
            style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 32),
          AppTextField(
            label: 'Email',
            hint: 'your@email.com',
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Password',
            hint: 'At least 6 characters',
            controller: passwordCtrl,
            obscureText: true,
          ),
        ],
      ),
    );
  }
}

// Page 2: Income
class _IncomePage extends StatelessWidget {
  final TextEditingController incomeCtrl;
  const _IncomePage({required this.incomeCtrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Income',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us calculate your debt-to-income ratio',
            style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 32),
          AppTextField(
            label: 'Monthly Income (₹)',
            hint: '50000',
            controller: incomeCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your income is stored locally and never shared',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Page 3: Expenses
class _ExpensesPage extends StatelessWidget {
  final TextEditingController expensesCtrl;
  const _ExpensesPage({required this.expensesCtrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Expenses',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Rent, groceries, utilities, and other regular expenses',
            style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 32),
          AppTextField(
            label: 'Monthly Expenses (₹)',
            hint: '30000',
            controller: expensesCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.success, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'We\'ll show your disposable income after EMIs',
                    style: TextStyle(fontSize: 12, color: AppColors.success),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Page 4: Preferences
class _PreferencesPage extends StatelessWidget {
  final bool enableReminders;
  final bool enableAiNudges;
  final ValueChanged<bool> onRemindersChanged;
  final ValueChanged<bool> onAiNudgesChanged;

  const _PreferencesPage({
    required this.enableReminders,
    required this.enableAiNudges,
    required this.onRemindersChanged,
    required this.onAiNudgesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preferences',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Customize your experience',
            style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 32),
          _PreferenceToggle(
            icon: Icons.notifications_outlined,
            title: 'EMI Reminders',
            subtitle: 'Get notified before due dates',
            value: enableReminders,
            onChanged: onRemindersChanged,
          ),
          const SizedBox(height: 16),
          _PreferenceToggle(
            icon: Icons.auto_awesome_outlined,
            title: 'AI Financial Nudges',
            subtitle: 'Smart suggestions to save on interest',
            value: enableAiNudges,
            onChanged: onAiNudgesChanged,
          ),
        ],
      ),
    );
  }
}

class _PreferenceToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? AppColors.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: value
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: value ? AppColors.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

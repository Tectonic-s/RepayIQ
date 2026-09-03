import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/profile_photo_provider.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../onboarding/domain/entities/user_profile.dart';
import '../../../onboarding/data/datasources/user_profile_local_datasource.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _incomeCtrl;
  late final TextEditingController _expensesCtrl;
  bool _isLoading = false;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value;
    _nameCtrl = TextEditingController(text: user?.displayName ?? '');
    _incomeCtrl = TextEditingController();
    _expensesCtrl = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    final profile = await UserProfileLocalDataSource().getUserProfile(uid);
    if (mounted && profile != null) {
      setState(() {
        _profile = profile;
        _incomeCtrl.text = profile.monthlyIncome.toStringAsFixed(0);
        _expensesCtrl.text = profile.monthlyExpenses.toStringAsFixed(0);
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _incomeCtrl.dispose();
    _expensesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take a Photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
        ]),
      ),
    );
    if (source == null) return;
    setState(() => _isLoading = true);
    try {
      final uid = ref.read(authStateProvider).value?.uid;
      if (uid == null) return;
      final base64 = await ProfilePhotoService.pickAndEncode(source);
      if (base64 != null) { await ProfilePhotoService.save(uid, base64); }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo updated'))); }
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error)); }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // Update Firebase display name
      await FirebaseAuth.instance.currentUser?.updateDisplayName(_nameCtrl.text.trim());
      await FirebaseAuth.instance.currentUser?.reload();
      
      // Update user profile (income/expenses)
      final uid = ref.read(authStateProvider).value?.uid;
      if (uid != null) {
        final updatedProfile = (_profile ?? UserProfile(
          userId: uid,
          monthlyIncome: 0,
          monthlyExpenses: 0,
          enableReminders: true,
          enableAiNudges: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )).copyWith(
          monthlyIncome: double.tryParse(_incomeCtrl.text) ?? 0,
          monthlyExpenses: double.tryParse(_expensesCtrl.text) ?? 0,
          updatedAt: DateTime.now(),
        );
        await UserProfileLocalDataSource().upsertUserProfile(updatedProfile);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
        context.pop();
      }
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error)); }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final photoBase64 = ref.watch(profilePhotoProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, top + 16, 20, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.arrow_back, size: 18,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(children: [
                  // Avatar
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Stack(children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        backgroundImage: photoBase64 != null ? MemoryImage(base64Decode(photoBase64)) : null,
                        child: photoBase64 == null
                            ? Text(
                                (user?.displayName?.isNotEmpty == true
                                        ? user!.displayName![0]
                                        : (user?.email ?? 'U')[0])
                                    .toUpperCase(),
                                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: AppColors.primary),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 30, height: 30,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    label: 'Full Name',
                    hint: 'Your name',
                    controller: _nameCtrl,
                    prefixIcon: Icons.person_outline,
                    autofocus: true,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Email',
                    hint: '',
                    controller: TextEditingController(text: user?.email ?? ''),
                    prefixIcon: Icons.email_outlined,
                    enabled: false,
                  ),
                  const SizedBox(height: 24),
                  // Budget Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Monthly Budget',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Monthly Income (₹)',
                    hint: '50000',
                    controller: _incomeCtrl,
                    prefixIcon: Icons.account_balance_wallet_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      if (double.tryParse(v) == null) return 'Enter valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Monthly Expenses (₹)',
                    hint: '30000',
                    controller: _expensesCtrl,
                    prefixIcon: Icons.shopping_cart_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      if (double.tryParse(v) == null) return 'Enter valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Used for debt-to-income ratio and budget analysis',
                            style: TextStyle(fontSize: 11, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(label: 'Save Changes', onPressed: _save, isLoading: _isLoading),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

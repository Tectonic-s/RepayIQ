import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/profile_photo_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/demo_data_seeder.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../loans/presentation/providers/loan_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final photoBase64 = ref.watch(profilePhotoProvider).value;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final top = MediaQuery.of(context).padding.top;
    final cs = Theme.of(context).colorScheme;

    final name = user?.displayName ?? 'No name set';
    final email = user?.email ?? '';
    final initial = (name.isNotEmpty ? name[0] : (email.isNotEmpty ? email[0] : 'U')).toUpperCase();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Title bar ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, top + 16, 20, 0),
              child: Text(
                'Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Profile card ──────────────────────────────────────────
                GestureDetector(
                  onTap: () => context.push('/settings/edit-profile'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04),
                          blurRadius: 12, offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        backgroundImage: photoBase64 != null ? MemoryImage(base64Decode(photoBase64)) : null,
                        child: photoBase64 == null
                            ? Text(initial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary))
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(email, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
                      ])),
                      Icon(Icons.chevron_right, size: 18, color: cs.onSurface.withValues(alpha: 0.3)),
                    ]),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Account ───────────────────────────────────────────────
                _SectionHeader('Account'),
                const SizedBox(height: 8),
                _TileGroup(isDark: isDark, tiles: [
                  _SettingsTile(
                    icon: Icons.person_outline,
                    label: 'Edit Profile',
                    onTap: () => context.push('/settings/edit-profile'),
                  ),
                  _SettingsTile(
                    icon: Icons.lock_outline,
                    label: 'Change Password',
                    onTap: () => _showChangePassword(context, ref),
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Preferences ───────────────────────────────────────────
                _SectionHeader('Preferences'),
                const SizedBox(height: 8),
                _TileGroup(isDark: isDark, tiles: [
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () {},
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeThumbColor: AppColors.primary,
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark Mode',
                    onTap: () => ref.read(themeProvider.notifier).setDark(!isDark),
                    trailing: Switch(
                      value: isDark,
                      onChanged: (v) => ref.read(themeProvider.notifier).setDark(v),
                      activeThumbColor: AppColors.primary,
                    ),
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Developer ─────────────────────────────────────────────
                _SectionHeader('Developer'),
                const SizedBox(height: 8),
                _TileGroup(isDark: isDark, tiles: [
                  _SettingsTile(
                    icon: Icons.auto_awesome,
                    label: 'Load Demo Data',
                    color: AppColors.success,
                    onTap: () => _loadDemoData(context, ref),
                    showChevron: false,
                  ),
                  _SettingsTile(
                    icon: Icons.refresh,
                    label: 'Reset Demo Data',
                    color: AppColors.warning,
                    onTap: () => _resetDemoData(context, ref),
                    showChevron: false,
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Danger zone ───────────────────────────────────────────
                _SectionHeader('Account Actions'),
                const SizedBox(height: 8),
                _TileGroup(isDark: isDark, tiles: [
                  _SettingsTile(
                    icon: Icons.logout,
                    label: 'Log Out',
                    color: AppColors.error,
                    onTap: () => _confirmLogout(context, ref),
                    showChevron: false,
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: const Text('Log Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _loadDemoData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load Demo Data'),
        content: const Text(
          'This will add 3 sample loans (Home, Vehicle, Personal) '
          'to demonstrate the app features.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loading demo data...'), duration: Duration(seconds: 2)),
                );
              }
              final repo = ref.read(loanRepositoryProvider);
              await DemoDataSeeder.forceSeed(repo);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Demo data loaded'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Load', style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );
  }

  void _resetDemoData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Demo Data'),
        content: const Text(
          'This will delete all loans and re-add 3 demo loans. '
          'Use this to quickly reset the app for demo purposes.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Show loading
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Resetting demo data...'), duration: Duration(seconds: 2)),
                );
              }
              // Delete all loans
              final loans = ref.read(loansStreamProvider).value ?? [];
              final repo = ref.read(loanRepositoryProvider);
              for (final loan in loans) {
                await repo.deleteLoan(loan.id);
              }
              // Force seed demo data
              await DemoDataSeeder.forceSeed(repo);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Demo data reset complete'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Reset', style: TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Text('A password reset link will be sent to ${user.email}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              FirebaseAuth.instance.sendPasswordResetEmail(email: user.email);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset link sent to your email')),
              );
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      );
}

// ── Grouped tile container ────────────────────────────────────────────────────

class _TileGroup extends StatelessWidget {
  final List<_SettingsTile> tiles;
  final bool isDark;
  const _TileGroup({required this.tiles, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04),
            blurRadius: 12, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: tiles.asMap().entries.map((e) {
          final isLast = e.key == tiles.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Widget? trailing;
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.trailing,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.onSurface;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: c),
      ),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c)),
      trailing: trailing ?? (showChevron
          ? Icon(Icons.chevron_right, size: 18, color: cs.onSurface.withValues(alpha: 0.3))
          : null),
    );
  }
}

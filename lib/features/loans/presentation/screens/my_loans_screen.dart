import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/loan_providers.dart';
import '../widgets/loan_card.dart';

class MyLoansScreen extends ConsumerWidget {
  const MyLoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(loansStreamProvider);
    final top = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: loansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (loans) {
          final active = loans.where((l) => l.status == 'Active').toList();
          final closed = loans.where((l) => l.status == 'Closed').toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, top + 16, 20, 0),
                  child: Text(
                    'My Loans',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              if (loans.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_outlined, size: 36, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      const Text('No loans yet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('Tap + to add your first loan',
                          style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.45))),
                    ]),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (active.isNotEmpty) ...[
                        _SectionHeader('Active Loans'),
                        const SizedBox(height: 10),
                        ...active.map((loan) => LoanCard(
                              loan: loan,
                              onTap: () => context.push('/loans/${loan.id}'),
                              onDelete: () => _confirmDelete(context, ref, loan.id),
                            )),
                      ],
                      if (closed.isNotEmpty) ...[
                        SizedBox(height: active.isNotEmpty ? 24 : 0),
                        _SectionHeader('Closed Loans'),
                        const SizedBox(height: 10),
                        ...closed.map((loan) => LoanCard(
                              loan: loan,
                              onTap: () => context.push('/loans/${loan.id}'),
                              onDelete: () => _confirmDelete(context, ref, loan.id),
                            )),
                      ],
                    ]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Loan'),
        content: const Text('This will permanently delete this loan.'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.pop();
              ref.read(loanNotifierProvider.notifier).deleteLoan(id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      );
}

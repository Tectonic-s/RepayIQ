import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../loans/domain/entities/loan.dart';
import '../../../loans/presentation/providers/loan_providers.dart';
import '../providers/family_providers.dart';
import '../../domain/entities/family_member.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(familyStreamProvider).value ?? [];
    final loans = ref.watch(loansStreamProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _showAddMember(context, ref),
          ),
        ],
      ),
      body: members.isEmpty
          ? _EmptyState(onAdd: () => _showAddMember(context, ref))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _ConsolidatedCard(members: members, loans: loans),
                const SizedBox(height: 20),
                const Text('Family Members', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...members.map((m) {
                  final memberLoans = loans.where((l) => l.memberId == m.id && l.status == 'Active').toList();
                  return _MemberCard(
                    member: m,
                    loans: memberLoans,
                    onDelete: () => ref.read(familyNotifierProvider.notifier).deleteMember(m.id),
                    onTap: () => _showMemberDetail(context, m, memberLoans),
                  );
                }),
              ],
            ),
    );
  }

  void _showAddMember(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddMemberSheet(ref: ref),
    );
  }

  void _showMemberDetail(BuildContext context, FamilyMember member, List<Loan> loans) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _MemberDetailSheet(member: member, loans: loans),
    );
  }
}

// ── Consolidated card ─────────────────────────────────────────────────────────

class _ConsolidatedCard extends StatelessWidget {
  final List<FamilyMember> members;
  final List<Loan> loans;
  const _ConsolidatedCard({required this.members, required this.loans});

  @override
  Widget build(BuildContext context) {
    final active = loans.where((l) => l.status == 'Active').toList();
    final totalEmi = active.fold(0.0, (s, l) => s + l.monthlyEmi);
    final totalOutstanding = active.fold(0.0, (s, l) => s + l.outstandingBalance);
    final totalIncome = members.fold(0.0, (s, m) => s + m.monthlyIncome);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Family Overview', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _CStat('Total Income', Formatters.currency(totalIncome))),
          Expanded(child: _CStat('Total EMI', Formatters.currency(totalEmi))),
          Expanded(child: _CStat('Outstanding', Formatters.currency(totalOutstanding))),
        ]),
        const SizedBox(height: 12),
        if (totalIncome > 0) ...[
          Text('Family EMI Ratio: ${(totalEmi / totalIncome * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (totalEmi / totalIncome).clamp(0.0, 1.0), minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(
                  totalEmi / totalIncome > 0.5 ? AppColors.error : AppColors.success),
            ),
          ),
        ],
      ]),
    );
  }
}

class _CStat extends StatelessWidget {
  final String label, value;
  const _CStat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
  ]);
}

// ── Member card ───────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  final FamilyMember member;
  final List<Loan> loans;
  final VoidCallback onDelete, onTap;
  const _MemberCard({required this.member, required this.loans, required this.onDelete, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final totalEmi = loans.fold(0.0, (s, l) => s + l.monthlyEmi);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          CircleAvatar(
            radius: 22, backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(member.name[0].toUpperCase(),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(member.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(member.relationship, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(Formatters.currency(member.monthlyIncome), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${loans.length} loan${loans.length != 1 ? 's' : ''} · ${Formatters.currency(totalEmi)}/mo',
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
          ]),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
          ),
        ]),
      ),
    );
  }
}

// ── Member detail sheet ───────────────────────────────────────────────────────

class _MemberDetailSheet extends StatelessWidget {
  final FamilyMember member;
  final List<Loan> loans;
  const _MemberDetailSheet({required this.member, required this.loans});

  @override
  Widget build(BuildContext context) {
    final totalEmi = loans.fold(0.0, (s, l) => s + l.monthlyEmi);
    final totalOutstanding = loans.fold(0.0, (s, l) => s + l.outstandingBalance);
    final emiRatio = member.monthlyIncome == 0 ? 0.0 : totalEmi / member.monthlyIncome;

    return DraggableScrollableSheet(
      initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.4,
      expand: false,
      builder: (ctx, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            CircleAvatar(radius: 28, backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(member.name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 22))),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(member.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text(member.relationship, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
            ]),
          ]),
          const SizedBox(height: 20),
          _DRow('Monthly Income', Formatters.currency(member.monthlyIncome)),
          _DRow('Total EMI', Formatters.currency(totalEmi)),
          _DRow('Outstanding', Formatters.currency(totalOutstanding)),
          _DRow('EMI Ratio', '${(emiRatio * 100).toStringAsFixed(0)}%'),
          const Divider(height: 24),
          if (loans.isEmpty)
            Text('No loans assigned to this member.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)))
          else ...[
            const Text('Assigned Loans', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ...loans.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.loanTypeColor(l.loanType), shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(l.loanName, style: const TextStyle(fontSize: 13))),
                Text(Formatters.currency(l.monthlyEmi), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            )),
          ],
        ],
      ),
    );
  }
}

class _DRow extends StatelessWidget {
  final String label, value;
  const _DRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );
}

// ── Add member sheet ──────────────────────────────────────────────────────────

class _AddMemberSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AddMemberSheet({required this.ref});
  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _incomeCtrl = TextEditingController();
  String _relationship = 'Spouse';
  bool _loading = false;

  static const _relationships = ['Spouse', 'Parent', 'Child', 'Sibling', 'Other'];

  @override
  void dispose() { _nameCtrl.dispose(); _incomeCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await widget.ref.read(familyNotifierProvider.notifier).addMember(
      name: _nameCtrl.text.trim(),
      relationship: _relationship,
      monthlyIncome: double.tryParse(_incomeCtrl.text) ?? 0,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add Family Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          AppTextField(label: 'Name', hint: 'Full name', controller: _nameCtrl,
              validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          Text('Relationship', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _relationship,
            items: _relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setState(() => _relationship = v!),
            decoration: const InputDecoration(),
          ),
          const SizedBox(height: 12),
          AppTextField(label: 'Monthly Income (₹)', hint: '50000', controller: _incomeCtrl,
              keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Add Member', onPressed: _submit, isLoading: _loading),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.group_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
      const SizedBox(height: 12),
      Text('No family members yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
      const SizedBox(height: 6),
      Text('Add members to track family-wide debt', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Member'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      ),
    ]),
  );
}

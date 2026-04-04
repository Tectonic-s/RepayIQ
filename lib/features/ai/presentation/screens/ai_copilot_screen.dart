import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/data_anonymiser.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../loans/presentation/providers/loan_providers.dart';

class AiCopilotScreen extends ConsumerStatefulWidget {
  const AiCopilotScreen({super.key});

  @override
  ConsumerState<AiCopilotScreen> createState() => _AiCopilotScreenState();
}

class _AiCopilotScreenState extends ConsumerState<AiCopilotScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _AiHeader(tabController: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _LoanCoachTab(),
                _ComparisonTab(),
                _StrategistTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _AiHeader extends StatelessWidget {
  final TabController tabController;
  const _AiHeader({required this.tabController});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1B2838)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI Co-Pilot', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              Text('Powered by Gemini', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
          ]),
          const SizedBox(height: 16),
          TabBar(
            controller: tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: '💬  Loan Coach'),
              Tab(text: '⚖️  Compare Loans'),
              Tab(text: '🎯  Strategist'),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FEATURE 1 — Loan Coach
// ══════════════════════════════════════════════════════════════════════════════

class _LoanCoachTab extends ConsumerStatefulWidget {
  const _LoanCoachTab();

  @override
  ConsumerState<_LoanCoachTab> createState() => _LoanCoachTabState();
}

class _LoanCoachTabState extends ConsumerState<_LoanCoachTab> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loading = false;
  bool _consentGiven = false;

  static const _consentKey = 'ai_copilot_consent_given';

  static const _suggestions = [
    'Can I afford a new loan?',
    'Which loan should I pay off first?',
    'What if I extend my home loan by 2 years?',
    'How much interest will I pay in total?',
  ];

  @override
  void initState() {
    super.initState();
    _loadConsent();
  }

  Future<void> _loadConsent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _consentGiven = prefs.getBool(_consentKey) ?? false);
  }

  Future<bool> _requestConsent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('AI Co-Pilot — Data Notice'),
        content: const Text(
          'To answer your questions, your loan portfolio details '
          '(loan names, amounts, interest rates) will be sent to '
          'Google Gemini AI.\n\n'
          'No personally identifiable information beyond loan '
          'figures is shared. You can review Google\'s privacy '
          'policy at ai.google.dev.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Decline'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_consentKey, true);
      if (mounted) setState(() => _consentGiven = true);
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;
    // Request consent on first use
    if (!_consentGiven) {
      final granted = await _requestConsent();
      if (!granted) return;
    }
    final loans = ref.read(activeLoansProvider);
    final userMsg = ChatMessage(text: text.trim(), isUser: true);
    setState(() { _messages.add(userMsg); _loading = true; });
    _ctrl.clear();
    _scrollToBottom();

    try {
      final reply = await AiService.chat(
        loans: loans,
        history: _messages.sublist(0, _messages.length - 1),
        userMessage: text.trim(),
      );
      setState(() => _messages.add(ChatMessage(text: reply, isUser: false)));
    } catch (e) {
      setState(() => _messages.add(ChatMessage(text: 'Error: $e', isUser: false)));
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _EmptyChat(suggestions: _suggestions, onTap: _send)
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == _messages.length) return const _TypingIndicator();
                    return _ChatBubble(message: _messages[i]);
                  },
                ),
        ),
        _ChatInput(ctrl: _ctrl, loading: _loading, onSend: _send),
      ],
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onTap;
  const _EmptyChat({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.auto_awesome, size: 48, color: AppColors.primary),
        const SizedBox(height: 12),
        const Text('Ask me anything about your loans',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('I have your full portfolio loaded as context.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
        const SizedBox(height: 24),
        ...suggestions.map((s) => GestureDetector(
          onTap: () => onTap(s),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(s, style: const TextStyle(fontSize: 13))),
              Icon(Icons.arrow_forward_ios, size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
            ]),
          ),
        )),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Text(
          isUser ? message.text : _cleanMarkdown(message.text),
          style: TextStyle(
            fontSize: 14, height: 1.5,
            color: isUser ? Colors.white : null,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 4),
          _Dot(delay: 0),
          const SizedBox(width: 4),
          _Dot(delay: 200),
          const SizedBox(width: 4),
          _Dot(delay: 400),
          const SizedBox(width: 4),
        ]),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
  );
}

class _ChatInput extends StatelessWidget {
  final TextEditingController ctrl;
  final bool loading;
  final ValueChanged<String> onSend;
  const _ChatInput({required this.ctrl, required this.loading, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 90),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            textInputAction: TextInputAction.send,
            onSubmitted: onSend,
            decoration: InputDecoration(
              hintText: 'Ask about your loans...',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 14),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: loading ? null : () => onSend(ctrl.text),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: loading ? AppColors.textHint : AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: loading
                ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FEATURE 2 — Loan Comparison
// ══════════════════════════════════════════════════════════════════════════════

class _ComparisonTab extends StatefulWidget {
  const _ComparisonTab();
  @override
  State<_ComparisonTab> createState() => _ComparisonTabState();
}

class _ComparisonTabState extends State<_ComparisonTab> {
  final _formKey = GlobalKey<FormState>();
  final _aLabel = TextEditingController(text: 'Offer A');
  final _aPrincipal = TextEditingController();
  final _aRate = TextEditingController();
  final _aTenure = TextEditingController();
  final _bLabel = TextEditingController(text: 'Offer B');
  final _bPrincipal = TextEditingController();
  final _bRate = TextEditingController();
  final _bTenure = TextEditingController();

  String? _result;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_aLabel, _aPrincipal, _aRate, _aTenure, _bLabel, _bPrincipal, _bRate, _bTenure]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _compare() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _result = null; });
    try {
      final res = await AiService.compareLoanOffers(
        offerA: LoanOffer(label: _aLabel.text, principal: double.parse(_aPrincipal.text),
            rate: double.parse(_aRate.text), tenureMonths: int.parse(_aTenure.text)),
        offerB: LoanOffer(label: _bLabel.text, principal: double.parse(_bPrincipal.text),
            rate: double.parse(_bRate.text), tenureMonths: int.parse(_bTenure.text)),
      );
      setState(() => _result = res);
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _OfferInputCard(label: 'Offer A', labelCtrl: _aLabel, principalCtrl: _aPrincipal,
              rateCtrl: _aRate, tenureCtrl: _aTenure, color: AppColors.primary),
          const SizedBox(height: 12),
          Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('VS', style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), letterSpacing: 2)),
          )),
          const SizedBox(height: 12),
          _OfferInputCard(label: 'Offer B', labelCtrl: _bLabel, principalCtrl: _bPrincipal,
              rateCtrl: _bRate, tenureCtrl: _bTenure, color: AppColors.warning),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Compare with AI', onPressed: _compare, isLoading: _loading),
          if (_result != null) ...[
            const SizedBox(height: 20),
            _AiResultCard(result: _result!),
          ],
        ]),
      ),
    );
  }
}

class _OfferInputCard extends StatelessWidget {
  final String label;
  final TextEditingController labelCtrl, principalCtrl, rateCtrl, tenureCtrl;
  final Color color;
  const _OfferInputCard({required this.label, required this.labelCtrl, required this.principalCtrl,
      required this.rateCtrl, required this.tenureCtrl, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(
            controller: labelCtrl,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _CompactField(ctrl: principalCtrl, label: 'Principal (₹)', hint: '500000',
              validator: (v) => (v!.isEmpty || double.tryParse(v) == null) ? 'Required' : null)),
          const SizedBox(width: 10),
          Expanded(child: _CompactField(ctrl: rateCtrl, label: 'Rate (%)', hint: '8.5',
              validator: (v) => (v!.isEmpty || double.tryParse(v) == null) ? 'Required' : null)),
        ]),
        const SizedBox(height: 10),
        _CompactField(ctrl: tenureCtrl, label: 'Tenure (months)', hint: '240',
            validator: (v) => (v!.isEmpty || int.tryParse(v) == null) ? 'Required' : null),
      ]),
    );
  }
}

class _CompactField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final FormFieldValidator<String>? validator;
  const _CompactField({required this.ctrl, required this.label, required this.hint, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        labelStyle: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FEATURE 3 — Repayment Strategist
// ══════════════════════════════════════════════════════════════════════════════

class _StrategistTab extends ConsumerStatefulWidget {
  const _StrategistTab();
  @override
  ConsumerState<_StrategistTab> createState() => _StrategistTabState();
}

class _StrategistTabState extends ConsumerState<_StrategistTab> {
  final _budgetCtrl = TextEditingController(text: '5000');
  String? _result;
  bool _loading = false;
  Map<String, String> _legend = {};

  @override
  void dispose() { _budgetCtrl.dispose(); super.dispose(); }

  Future<void> _analyse() async {
    FocusScope.of(context).unfocus();
    final loans = ref.read(activeLoansProvider);
    if (loans.isEmpty) {
      setState(() => _result = 'You have no active loans to analyse.');
      return;
    }
    setState(() { _loading = true; _result = null; _legend = DataAnonymiser.buildLegend(loans); });
    try {
      final res = await AiService.repaymentStrategy(
        loans: loans,
        extraMonthlyBudget: double.tryParse(_budgetCtrl.text) ?? 0,
      );
      setState(() => _result = res);
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loans = ref.watch(activeLoansProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Portfolio summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your Active Loans', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
            const SizedBox(height: 10),
            if (loans.isEmpty)
              Text('No active loans', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)))
            else
              ...loans.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.loanTypeColor(l.loanType), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l.loanName, style: const TextStyle(fontSize: 13))),
                  Text('${l.interestRate}% · ${Formatters.currency(l.outstandingBalance)}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
                ]),
              )),
          ]),
        ),
        const SizedBox(height: 16),

        // Extra budget input
        Text('Extra Monthly Budget', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(
            controller: _budgetCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: '₹ ',
              hintText: '5000',
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          )),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _loading ? null : _analyse,
            icon: _loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Analyse'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text('Amount you can put towards loans beyond your regular EMIs.',
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),

        if (_result != null) ...[
          const SizedBox(height: 20),
          _AiResultCard(result: _result!, legend: _legend),
        ],
      ]),
    );
  }
}

// ── Shared AI result card

String _cleanMarkdown(String text) {
  return text
      .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*', dotAll: true), (m) => m.group(1) ?? '')
      .replaceAllMapped(RegExp(r'\*(.+?)\*', dotAll: true), (m) => m.group(1) ?? '')
      .replaceAllMapped(RegExp(r'__(.+?)__', dotAll: true), (m) => m.group(1) ?? '')
      .replaceAllMapped(RegExp(r'_(.+?)_', dotAll: true), (m) => m.group(1) ?? '')
      .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
      .replaceAll(RegExp(r'^[\*\-]\s+', multiLine: true), '\u2022 ')
      .replaceAllMapped(RegExp(r'`(.+?)`'), (m) => m.group(1) ?? '')
      .replaceAll(RegExp(r'\$(?=\d)'), '\u20b9')
      .replaceAll('USD', '\u20b9')
      .trim();
}

class _AiResultCard extends StatelessWidget {
  final String result;
  final Map<String, String>? legend;
  const _AiResultCard({required this.result, this.legend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          const Text('AI Analysis', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ]),
        if (legend != null && legend!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Loan Reference', style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w600, color: AppColors.primary.withValues(alpha: 0.8))),
                const SizedBox(height: 6),
                ...legend!.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(children: [
                    Text(e.key, style: const TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w600, color: AppColors.primary)),
                    const Text(' \u2192 ', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                    Expanded(child: Text(e.value,
                        style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                  ]),
                )),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(_cleanMarkdown(result), style: TextStyle(fontSize: 13, height: 1.6,
            color: Theme.of(context).colorScheme.onSurface)),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static const _tools = [
    _ToolItem('EMI Calculator', 'Calculate loan EMIs', Icons.calculate_outlined, AppColors.primary, '/calculator'),
    _ToolItem('RepayIQ Score', 'Your financial health score', Icons.star_outline, AppColors.scoreGood, '/score'),
    _ToolItem('Budget Analyser', 'Income vs EMI impact', Icons.account_balance_wallet_outlined, AppColors.success, '/budget'),
    _ToolItem('EMI Calendar', 'All due dates at a glance', Icons.calendar_month_outlined, AppColors.accent, '/calendar'),
    _ToolItem('Family Manager', 'Track family-wide debt', Icons.group_outlined, AppColors.vehicle, '/family'),
    _ToolItem('Reports', 'Charts & PDF export', Icons.bar_chart_outlined, AppColors.warning, '/reports'),
    _ToolItem('AI Co-Pilot', 'Gemini-powered advisor', Icons.auto_awesome_outlined, AppColors.personal, '/ai'),
  ];

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tools', style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -0.5,
                )),
                const SizedBox(height: 4),
                Text('Everything you need to manage your finances',
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.55,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _ToolCard(tool: _tools[i]),
                childCount: _tools.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final _ToolItem tool;
  const _ToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push(tool.route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: tool.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tool.icon, color: tool.color, size: 20),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tool.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(tool.subtitle, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ],
        ),
      ),
    );
  }
}

class _ToolItem {
  final String label, subtitle, route;
  final IconData icon;
  final Color color;
  const _ToolItem(this.label, this.subtitle, this.icon, this.color, this.route);
}

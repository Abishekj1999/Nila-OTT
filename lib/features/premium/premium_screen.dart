import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/state_views.dart';
import '../auth/application/auth_controller.dart';

/// Plan cards from the approved design.
///
/// NOT BACKEND DATA: the API has no plans, purchase or receipt-verification
/// endpoints yet, so these are display-only and checkout shows "Coming soon".
/// Replace with an API-driven list once a subscription endpoint exists.
class PremiumPlan {
  const PremiumPlan({required this.name, required this.price, required this.period, required this.days, this.badge});

  final String name;
  final int price;
  final String period;
  final int days;
  final String? badge;

  String get perDay => '₹${(price / days).toStringAsFixed(2)}/day';
  String get priceLabel {
    final s = price.toString();
    return s.length > 3 ? '₹${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}' : '₹$s';
  }
}

const designPlans = [
  PremiumPlan(name: 'Monthly', price: 499, period: '/ month', days: 30),
  PremiumPlan(name: 'Quarterly', price: 799, period: '/ 3 months', days: 90, badge: 'POPULAR'),
  PremiumPlan(name: 'Yearly', price: 1499, period: '/ year', days: 365),
  PremiumPlan(name: '2 Years', price: 2199, period: '/ 2 years', days: 730),
  PremiumPlan(name: '5 Years', price: 2999, period: '/ 5 years', days: 1826, badge: 'MOST ECONOMICAL'),
];

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  int _selected = 1;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final plan = designPlans[_selected];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        actions: [
          TextButton(onPressed: () => showComingSoon(context, 'Restore purchases'), child: const Text('Restore')),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 24),
            children: [
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.35), blurRadius: 28)],
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: AppColors.goldDeep, size: 36),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Go Premium', textAlign: TextAlign.center, style: AppText.largeTitle),
              const SizedBox(height: 6),
              const Text('Every story, without limits.', textAlign: TextAlign.center, style: AppText.subhead),
              const SizedBox(height: 22),
              const _Benefit(icon: Icons.all_inclusive_rounded, text: 'Unlimited movies and series'),
              const _Benefit(icon: Icons.auto_awesome_rounded, text: 'Exclusive premium content'),
              const _Benefit(icon: Icons.block_rounded, text: 'Ad-free experience'),
              if (auth.isPremium) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0x2634C77B), borderRadius: BorderRadius.circular(12)),
                  child: const Row(children: [
                    Icon(Icons.verified_rounded, color: AppColors.success),
                    SizedBox(width: 10),
                    Expanded(child: Text("You're a Premium member. Enjoy every story!", style: AppText.bodyStrong)),
                  ]),
                ),
              ],
              const SizedBox(height: 24),
              Text('CHOOSE A PLAN', style: AppText.label.copyWith(color: AppColors.textTertiary)),
              const SizedBox(height: 10),
              for (var i = 0; i < designPlans.length; i++) ...[
                _PlanTile(plan: designPlans[i], selected: i == _selected, onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selected = i);
                }),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.hairline, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 12, AppSpacing.gutter, 8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AppButton(
                label: 'Continue',
                expand: true,
                onPressed: () => showComingSoon(context, 'Premium checkout'),
              ),
              const SizedBox(height: 8),
              Text('${plan.name} · ${plan.priceLabel} ${plan.period}', style: AppText.caption),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(color: AppColors.pinkTint, shape: BoxShape.circle),
          child: Icon(icon, size: 17, color: AppColors.pinkBright),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(text, style: AppText.bodyStrong)),
      ]),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.selected, required this.onTap});

  final PremiumPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      inMutuallyExclusiveGroup: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? const Color(0x1FE5156B) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: selected ? AppColors.pink : AppColors.hairline, width: selected ? 1.6 : 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.pink : Colors.transparent,
                    border: Border.all(color: selected ? AppColors.pink : AppColors.textTertiary, width: 1.6),
                  ),
                  child: selected ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(child: Text(plan.name, style: AppText.headline)),
                      if (plan.badge != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(5)),
                            child: Text(
                              plan.badge!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppColors.goldDeep, letterSpacing: 0.4),
                            ),
                          ),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text('About ${plan.perDay}', style: AppText.caption),
                  ]),
                ),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(plan.priceLabel, style: const TextStyle(color: AppColors.text, fontSize: 19, fontWeight: FontWeight.w800)),
                  Text(plan.period, style: AppText.caption),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

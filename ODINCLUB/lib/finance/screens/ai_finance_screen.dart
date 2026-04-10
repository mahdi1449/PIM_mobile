import 'package:flutter/material.dart';

import '../services/finance_ai_service.dart';
import '../services/finance_store.dart';
import '../theme/finance_theme.dart';
import '../widgets/finance_widgets.dart';

class AiFinanceScreen extends StatefulWidget {
  const AiFinanceScreen({super.key});

  @override
  State<AiFinanceScreen> createState() => _AiFinanceScreenState();
}

class _AiFinanceScreenState extends State<AiFinanceScreen> {
  late Future<FinanceAiBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = FinanceAiService.instance.loadRemoteInsights(FinanceStore.instance);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = FinanceAiService.instance.loadRemoteInsights(FinanceStore.instance);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FinanceAiBundle>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: FinancePalette.danger, size: 42),
                  const SizedBox(height: 12),
                  Text(
                    'AI Finance indisponible',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error ?? 'Unknown error'}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        final bundle = snapshot.data!;
        final forecast = bundle.forecastData ?? const <String, dynamic>{};
        final cashflow = bundle.cashflowData ?? const <String, dynamic>{};
        final impact = bundle.impactData ?? const <String, dynamic>{};
        final nextSeason =
            (forecast['nextSeason'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
        final scenario =
            (impact['scenario'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
        final notes = (cashflow['notes'] as List? ?? const []).map((e) => e.toString()).toList();

        String compact(dynamic value) {
          final numValue = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
          return formatCompactMoney(numValue, symbol: 'DT');
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'AI Finance',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Source: ${bundle.source}${bundle.generationTimeMs != null ? ' • ${bundle.generationTimeMs} ms' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: FinancePalette.muted,
                  ),
            ),
            const SizedBox(height: 16),
            _AiMetricCard(
              title: 'Season Forecast',
              icon: Icons.show_chart_rounded,
              lines: [
                'Season: ${nextSeason['season'] ?? 'N/A'}',
                'Revenue: ${compact(nextSeason['revenue'])}',
                'Expenses: ${compact(nextSeason['expense'])}',
                'Net: ${compact(nextSeason['net'])}',
                'Confidence: ${forecast['confidence'] ?? 'N/A'}%',
              ],
            ),
            const SizedBox(height: 12),
            _AiMetricCard(
              title: 'Cashflow Risk',
              icon: Icons.account_balance_wallet_outlined,
              lines: [
                'Level: ${cashflow['level'] ?? 'N/A'}',
                'Score: ${cashflow['score'] ?? 'N/A'}',
                'Projected cash: ${compact(cashflow['projectedCash'])}',
                'Upcoming outflows: ${compact(cashflow['upcomingOutflows'])}',
                'Upcoming inflows: ${compact(cashflow['upcomingInflows'])}',
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _AiMetricCard(
                title: 'Analysis Notes',
                icon: Icons.notes_rounded,
                lines: notes,
              ),
            ],
            const SizedBox(height: 12),
            _AiMetricCard(
              title: 'Sponsor & Transfer Impact',
              icon: Icons.swap_horiz_rounded,
              lines: [
                'Sponsor base: ${compact(impact['sponsorBase'])}',
                'Sponsors +10%: ${compact(impact['sponsorPlus10'])}',
                'Sponsors -10%: ${compact(impact['sponsorMinus10'])}',
                'Transfer net: ${compact(impact['transferNet'])}',
                'Scenario +10% impact: ${compact(scenario['sponsorImpactPlus10'])}',
                'Scenario -10% impact: ${compact(scenario['sponsorImpactMinus10'])}',
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AiMetricCard extends StatelessWidget {
  const _AiMetricCard({
    required this.title,
    required this.icon,
    required this.lines,
  });

  final String title;
  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FinancePalette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FinancePalette.soft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: FinancePalette.blue),
              const SizedBox(width: 10),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line),
            ),
          ),
        ],
      ),
    );
  }
}

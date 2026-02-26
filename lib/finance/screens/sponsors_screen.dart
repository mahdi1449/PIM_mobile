import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/finance_store.dart';
import '../theme/finance_theme.dart';
import '../widgets/finance_widgets.dart';

class SponsorsScreen extends StatelessWidget {
  const SponsorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final totalActual = store.totalRevenueActual;
        final totalForecast = store.totalRevenueForecast;
        final variance = totalActual - totalForecast;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Gestion des Revenus',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                FilledButton(
                  onPressed: () => _openRevenueDialog(context, store),
                  style: FilledButton.styleFrom(
                    backgroundColor: FinancePalette.blue,
                  ),
                  child: const Text('+ Revenu'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    label: 'Forecast',
                    value: formatCompactMoney(totalForecast, symbol: '€'),
                    icon: Icons.flag_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricTile(
                    label: 'Actual',
                    value: formatCompactMoney(totalActual, symbol: '€'),
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricTile(
                    label: 'Variance',
                    value: formatCompactMoney(variance, symbol: '€'),
                    positive: variance >= 0,
                    icon: Icons.compare_arrows_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FinanceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel(
                    title: 'Revenus par categorie',
                    subtitle:
                        'Billetterie, Sponsoring, Droits TV, Merchandising, Subventions, Academy fees, Prize money',
                  ),
                  const SizedBox(height: 12),
                  ...store.revenues.map(
                    (revenue) => _RevenueRow(
                      revenue: revenue,
                      onEdit: () =>
                          _openRevenueDialog(context, store, current: revenue),
                      onDelete: () => store.deleteRevenue(revenue.id),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openRevenueDialog(
    BuildContext context,
    FinanceStore store, {
    RevenueItem? current,
  }) async {
    final title = TextEditingController(text: current?.title ?? '');
    final season = TextEditingController(text: current?.season ?? '2025/2026');
    final competition = TextEditingController(
      text: current?.competition ?? 'ALL',
    );
    final forecast = TextEditingController(
      text: current != null ? current.forecastAmount.toStringAsFixed(0) : '',
    );
    final actual = TextEditingController(
      text: current != null ? current.actualAmount.toStringAsFixed(0) : '',
    );
    String category = current?.category ?? FinanceStore.revenueCategories.first;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                current == null ? 'Ajouter revenu' : 'Modifier revenu',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      items: FinanceStore.revenueCategories
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => category = v ?? category),
                      decoration: const InputDecoration(labelText: 'Categorie'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(
                        labelText: 'Libelle revenu',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: season,
                      decoration: const InputDecoration(labelText: 'Saison'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: competition,
                      decoration: const InputDecoration(
                        labelText: 'Competition',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: forecast,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Forecast'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: actual,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Actual'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final forecastValue =
                        double.tryParse(forecast.text.trim()) ?? 0;
                    final actualValue =
                        double.tryParse(actual.text.trim()) ?? 0;

                    if (current == null) {
                      store.addRevenue(
                        category,
                        title.text.trim(),
                        season.text.trim(),
                        competition.text.trim(),
                        forecastValue,
                        actualValue,
                      );
                    } else {
                      store.updateRevenue(
                        current.id,
                        category,
                        title.text.trim(),
                        season.text.trim(),
                        competition.text.trim(),
                        forecastValue,
                        actualValue,
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _RevenueRow extends StatelessWidget {
  const _RevenueRow({
    required this.revenue,
    required this.onEdit,
    required this.onDelete,
  });

  final RevenueItem revenue;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final variance = revenue.actualAmount - revenue.forecastAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FinancePalette.soft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${revenue.title} • ${revenue.category}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
          Text(
            '${revenue.season} • ${revenue.competition}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'Forecast ${formatCompactMoney(revenue.forecastAmount, symbol: '€')}',
              ),
              Text(
                'Actual ${formatCompactMoney(revenue.actualAmount, symbol: '€')}',
              ),
              Text(
                'Variance ${formatCompactMoney(variance, symbol: '€')}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: variance >= 0
                      ? FinancePalette.success
                      : FinancePalette.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

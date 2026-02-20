import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/finance_store.dart';
import '../theme/finance_theme.dart';
import '../widgets/finance_widgets.dart';

class AccountingScreen extends StatelessWidget {
  const AccountingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final trialBalance = store.buildTrialBalance();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Gestion Comptable Generale',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                FilledButton(
                  onPressed: () => _openLedgerDialog(context, store),
                  style: FilledButton.styleFrom(
                    backgroundColor: FinancePalette.blue,
                  ),
                  child: const Text('+ Ecriture manuelle'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _export(context, store, 'PDF'),
                  child: const Text('Export PDF'),
                ),
                OutlinedButton(
                  onPressed: () => _export(context, store, 'Excel'),
                  child: const Text('Export Excel'),
                ),
                OutlinedButton(
                  onPressed: () => _export(context, store, 'FEC'),
                  child: const Text('Export FEC'),
                ),
                OutlinedButton(
                  onPressed: () => _closePeriod(context, store),
                  child: const Text('Cloture mensuelle'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FinanceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: SectionLabel(
                          title: 'Plan comptable (Chart of Accounts)',
                          subtitle: 'CRUD des comptes comptables',
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openAccountPlanDialog(context, store),
                        child: const Text('+ Compte'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...store.chartOfAccounts.map(
                    (account) => _AccountPlanRow(
                      account: account,
                      onEdit: () => _openAccountPlanDialog(
                        context,
                        store,
                        current: account,
                      ),
                      onDelete: () => store.deleteChartAccount(account.id),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FinanceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel(
                    title: 'Journal comptable / Grand livre',
                    subtitle: 'Ecritures automatiques et manuelles',
                  ),
                  const SizedBox(height: 12),
                  ...store.ledger.map(
                    (entry) => _LedgerRow(
                      entry: entry,
                      onEdit: () =>
                          _openLedgerDialog(context, store, current: entry),
                      onPost: entry.status == 'POSTED'
                          ? null
                          : () => store.postLedgerEntry(entry.id),
                      onDelete: () => store.deleteLedger(entry.id),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FinanceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel(
                    title: 'Balance comptable (Trial Balance)',
                    subtitle: 'Debit / credit par compte',
                  ),
                  const SizedBox(height: 10),
                  ...trialBalance.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(line.accountCode)),
                          Expanded(
                            child: Text(
                              formatCompactMoney(line.debit, symbol: '€'),
                              textAlign: TextAlign.end,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              formatCompactMoney(line.credit, symbol: '€'),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    label: 'Bilan - Actif',
                    value: formatCompactMoney(store.totalAssets, symbol: '€'),
                    icon: Icons.account_balance_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricTile(
                    label: 'Bilan - Passif',
                    value: formatCompactMoney(
                      store.totalLiabilitiesAndEquity,
                      symbol: '€',
                    ),
                    icon: Icons.balance_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    label: 'Compte resultat - Revenus',
                    value: formatCompactMoney(store.pnlRevenue, symbol: '€'),
                    icon: Icons.trending_up_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricTile(
                    label: 'Compte resultat - Charges',
                    value: formatCompactMoney(store.pnlExpenses, symbol: '€'),
                    positive: false,
                    icon: Icons.trending_down_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            MetricTile(
              label: 'Resultat net',
              value: formatCompactMoney(store.netResult, symbol: '€'),
              positive: store.netResult >= 0,
              icon: Icons.summarize_outlined,
            ),
          ],
        );
      },
    );
  }

  void _export(BuildContext context, FinanceStore store, String kind) {
    store.exportAccountingDocument(kind);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Export $kind genere')));
  }

  void _closePeriod(BuildContext context, FinanceStore store) {
    final month = DateTime.now();
    final label = '${month.month}/${month.year}';
    store.closeAccountingPeriod(label);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cloture comptable effectuee pour $label')),
    );
  }

  Future<void> _openAccountPlanDialog(
    BuildContext context,
    FinanceStore store, {
    AccountPlanItem? current,
  }) async {
    final code = TextEditingController(text: current?.code ?? '');
    final label = TextEditingController(text: current?.label ?? '');
    final parentCode = TextEditingController(text: current?.parentCode ?? '');
    String type = current?.type ?? 'ASSET';
    bool active = current?.active ?? true;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                current == null ? 'Ajouter compte' : 'Modifier compte',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: code,
                      decoration: const InputDecoration(labelText: 'Code'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: label,
                      decoration: const InputDecoration(labelText: 'Libelle'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      items:
                          const [
                                'ASSET',
                                'LIABILITY',
                                'EQUITY',
                                'REVENUE',
                                'EXPENSE',
                              ]
                              .map(
                                (v) =>
                                    DropdownMenuItem(value: v, child: Text(v)),
                              )
                              .toList(),
                      onChanged: (v) => type = v ?? type,
                      decoration: const InputDecoration(labelText: 'Type'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: parentCode,
                      decoration: const InputDecoration(
                        labelText: 'Parent code (optionnel)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: active,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Actif'),
                      onChanged: (v) => setState(() => active = v),
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
                    if (current == null) {
                      store.addChartAccount(
                        code.text.trim(),
                        label.text.trim(),
                        type,
                        parentCode: parentCode.text.trim().isEmpty
                            ? null
                            : parentCode.text.trim(),
                      );
                    } else {
                      store.updateChartAccount(
                        current.id,
                        code.text.trim(),
                        label.text.trim(),
                        type,
                        parentCode: parentCode.text.trim().isEmpty
                            ? null
                            : parentCode.text.trim(),
                        active: active,
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

  Future<void> _openLedgerDialog(
    BuildContext context,
    FinanceStore store, {
    LedgerEntryItem? current,
  }) async {
    final date = TextEditingController(
      text: current == null
          ? _formatDate(DateTime.now())
          : _formatDate(current.entryDate),
    );
    final accountCode = TextEditingController(text: current?.accountCode ?? '');
    final description = TextEditingController(text: current?.description ?? '');
    final amount = TextEditingController(
      text: current != null ? current.amount.toStringAsFixed(0) : '',
    );
    String nature = current?.nature ?? 'DEBIT';
    String source = current?.source ?? 'MANUAL';
    String status = current?.status ?? 'DRAFT';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                current == null ? 'Ajouter ecriture' : 'Modifier ecriture',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: date,
                      decoration: const InputDecoration(
                        labelText: 'Date (dd/MM/yyyy)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: accountCode,
                      decoration: const InputDecoration(labelText: 'Compte'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: description,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Montant'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: nature,
                      items: const ['DEBIT', 'CREDIT']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (v) => nature = v ?? nature,
                      decoration: const InputDecoration(labelText: 'Nature'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: source,
                      items: const ['MANUAL', 'AUTO']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (v) => source = v ?? source,
                      decoration: const InputDecoration(labelText: 'Source'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      items: const ['DRAFT', 'POSTED']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (v) => status = v ?? status,
                      decoration: const InputDecoration(labelText: 'Status'),
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
                    final parsedAmount =
                        double.tryParse(amount.text.trim()) ?? 0;
                    final parsedDate =
                        _parseDate(date.text.trim()) ?? DateTime.now();
                    if (current == null) {
                      store.addLedger(
                        parsedDate,
                        accountCode.text.trim(),
                        description.text.trim(),
                        parsedAmount,
                        nature,
                        source,
                        status,
                      );
                    } else {
                      store.updateLedger(
                        current.id,
                        parsedDate,
                        accountCode.text.trim(),
                        description.text.trim(),
                        parsedAmount,
                        nature,
                        source,
                        status,
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

  static String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  static DateTime? _parseDate(String input) {
    final parts = input.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }
}

class _AccountPlanRow extends StatelessWidget {
  const _AccountPlanRow({
    required this.account,
    required this.onEdit,
    required this.onDelete,
  });

  final AccountPlanItem account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FinancePalette.soft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${account.code} - ${account.label}'),
                Text(
                  '${account.type}${account.parentCode != null ? ' • parent ${account.parentCode}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
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
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.entry,
    required this.onEdit,
    required this.onPost,
    required this.onDelete,
  });

  final LedgerEntryItem entry;
  final VoidCallback onEdit;
  final VoidCallback? onPost;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FinancePalette.soft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${entry.accountCode} • ${entry.description}',
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
            '${AccountingScreen._formatDate(entry.entryDate)} • ${entry.nature} • ${entry.source} • ${entry.status}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                formatCompactMoney(entry.amount, symbol: '€'),
                style: TextStyle(
                  color: entry.nature == 'CREDIT'
                      ? FinancePalette.success
                      : FinancePalette.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (entry.status != 'POSTED')
                TextButton(onPressed: onPost, child: const Text('Post entry')),
            ],
          ),
        ],
      ),
    );
  }
}

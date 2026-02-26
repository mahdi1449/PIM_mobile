import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/finance_store.dart';
import '../theme/finance_theme.dart';
import '../widgets/finance_widgets.dart';

class PayrollScreen extends StatelessWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final totalNet = store.totalSalaryExpense;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Gestion des Salaires (Paie complete)',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                FilledButton(
                  onPressed: () => _openSalaryDialog(context, store),
                  style: FilledButton.styleFrom(
                    backgroundColor: FinancePalette.blue,
                  ),
                  child: const Text('+ Fiche paie'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () {
                    store.exportPayrollBankBatch();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Export virement bancaire genere'),
                      ),
                    );
                  },
                  child: const Text('Export virement'),
                ),
                OutlinedButton(
                  onPressed: () {
                    for (final item in store.salaries.where(
                      (s) => s.status != 'PAID',
                    )) {
                      store.markSalaryPaid(item.id);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cycle paie execute')),
                    );
                  },
                  child: const Text('Executer paie'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    label: 'Joueurs + staff',
                    value: '${store.salaries.length}',
                    icon: Icons.groups_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricTile(
                    label: 'Total net a payer',
                    value: formatCompactMoney(totalNet, symbol: '€'),
                    icon: Icons.payments_rounded,
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
                    title: 'Registre paie',
                    subtitle:
                        'Salaire fixe, primes, penalites, avantages, cotisations, impots, net',
                  ),
                  const SizedBox(height: 12),
                  ...store.salaries.map(
                    (salary) => _PayrollRow(
                      salary: salary,
                      onEdit: () =>
                          _openSalaryDialog(context, store, current: salary),
                      onDelete: () => store.deleteSalary(salary.id),
                      onMarkPaid: () => store.markSalaryPaid(salary.id),
                      onPayslip: () {
                        store.generatePayslip(salary.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Fiche PDF generee: ${salary.employee}',
                            ),
                          ),
                        );
                      },
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
                    title: 'Historique paiements',
                    subtitle: 'Traitees par virement',
                  ),
                  const SizedBox(height: 10),
                  ...store.salaryPayments.map(
                    (history) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${history.employee}\n${_formatDate(history.paidAt)} • ${history.reference}',
                            ),
                          ),
                          Text(
                            formatCompactMoney(history.amount, symbol: '€'),
                            style: TextStyle(
                              color: FinancePalette.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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

  Future<void> _openSalaryDialog(
    BuildContext context,
    FinanceStore store, {
    SalaryRecord? current,
  }) async {
    final employee = TextEditingController(text: current?.employee ?? '');
    final role = TextEditingController(text: current?.role ?? 'PLAYER');
    final fixedSalary = TextEditingController(
      text: current != null ? current.fixedSalary.toStringAsFixed(0) : '',
    );
    final matchBonus = TextEditingController(
      text: current != null ? current.matchBonus.toStringAsFixed(0) : '0',
    );
    final performanceBonus = TextEditingController(
      text: current != null ? current.performanceBonus.toStringAsFixed(0) : '0',
    );
    final signingBonus = TextEditingController(
      text: current != null ? current.signingBonus.toStringAsFixed(0) : '0',
    );
    final penalties = TextEditingController(
      text: current != null ? current.penalties.toStringAsFixed(0) : '0',
    );
    final benefits = TextEditingController(
      text: current != null ? current.benefits.toStringAsFixed(0) : '0',
    );
    final socialContributions = TextEditingController(
      text: current != null
          ? current.socialContributions.toStringAsFixed(0)
          : '0',
    );
    final taxes = TextEditingController(
      text: current != null ? current.taxes.toStringAsFixed(0) : '0',
    );
    String status = current?.status ?? 'READY';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                current == null ? 'Ajouter fiche paie' : 'Modifier fiche paie',
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: employee,
                        decoration: const InputDecoration(labelText: 'Employe'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: role,
                        decoration: const InputDecoration(labelText: 'Role'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: fixedSalary,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Salaire fixe',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: matchBonus,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Prime match',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: performanceBonus,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Prime performance',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: signingBonus,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Prime signature',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: penalties,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Penalites/amendes',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: benefits,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Avantages (voiture/logement)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: socialContributions,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Cotisations sociales',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: taxes,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Impots'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        items: const ['READY', 'PAID']
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => status = value ?? status),
                        decoration: const InputDecoration(labelText: 'Status'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final fixed = double.tryParse(fixedSalary.text.trim()) ?? 0;
                    final match = double.tryParse(matchBonus.text.trim()) ?? 0;
                    final performance =
                        double.tryParse(performanceBonus.text.trim()) ?? 0;
                    final signing =
                        double.tryParse(signingBonus.text.trim()) ?? 0;
                    final penalty = double.tryParse(penalties.text.trim()) ?? 0;
                    final benefit = double.tryParse(benefits.text.trim()) ?? 0;
                    final social =
                        double.tryParse(socialContributions.text.trim()) ?? 0;
                    final tax = double.tryParse(taxes.text.trim()) ?? 0;

                    if (current == null) {
                      store.addSalary(
                        employee.text.trim(),
                        role.text.trim(),
                        fixed,
                        match,
                        performance,
                        signing,
                        penalty,
                        benefit,
                        social,
                        tax,
                        status,
                      );
                    } else {
                      store.updateSalary(
                        current.id,
                        employee.text.trim(),
                        role.text.trim(),
                        fixed,
                        match,
                        performance,
                        signing,
                        penalty,
                        benefit,
                        social,
                        tax,
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
}

class _PayrollRow extends StatelessWidget {
  const _PayrollRow({
    required this.salary,
    required this.onEdit,
    required this.onDelete,
    required this.onMarkPaid,
    required this.onPayslip,
  });

  final SalaryRecord salary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMarkPaid;
  final VoidCallback onPayslip;

  @override
  Widget build(BuildContext context) {
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
                  '${salary.employee} • ${salary.role}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: salary.status == 'PAID'
                      ? FinancePalette.success.withValues(alpha: 0.18)
                      : FinancePalette.warning.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  salary.status,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: salary.status == 'PAID'
                        ? FinancePalette.success
                        : FinancePalette.warning,
                  ),
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'Fixe ${formatCompactMoney(salary.fixedSalary, symbol: '€')}',
              ),
              Text(
                'Primes ${formatCompactMoney(salary.matchBonus + salary.performanceBonus + salary.signingBonus, symbol: '€')}',
              ),
              Text(
                'Penalites ${formatCompactMoney(salary.penalties, symbol: '€')}',
              ),
              Text(
                'Avantages ${formatCompactMoney(salary.benefits, symbol: '€')}',
              ),
              Text(
                'Cotisations ${formatCompactMoney(salary.socialContributions, symbol: '€')}',
              ),
              Text('Impots ${formatCompactMoney(salary.taxes, symbol: '€')}'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Net a payer: ${formatCompactMoney(salary.netToPay, symbol: '€')}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: FinancePalette.blue,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: onPayslip,
                child: const Text('Fiche PDF'),
              ),
              if (salary.status != 'PAID')
                FilledButton(
                  onPressed: onMarkPaid,
                  child: const Text('Mark paid'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

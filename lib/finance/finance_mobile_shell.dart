import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'screens/accounting_screen.dart';
import 'screens/audit_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/payroll_screen.dart';
import 'screens/sponsors_screen.dart';
import 'screens/transfers_screen.dart';
import 'screens/treasury_screen.dart';
import 'theme/finance_theme.dart';
import 'widgets/finance_widgets.dart';

class FinanceMobileShell extends StatefulWidget {
  const FinanceMobileShell({
    super.key,
    this.onLogout,
    this.avatarLabel = 'S',
    this.roleLabel = 'SERVER: OPERATIONAL',
    this.profileImage,
  });

  final VoidCallback? onLogout;
  final String avatarLabel;
  final String roleLabel;
  final String? profileImage;

  @override
  State<FinanceMobileShell> createState() => _FinanceMobileShellState();
}

class _FinanceMobileShellState extends State<FinanceMobileShell> {
  int _index = 0;

  static const _tabs = [
    ('Dashboard', Icons.grid_view_rounded),
    ('Revenus', Icons.trending_up_rounded),
    ('Accounting', Icons.receipt_long_rounded),
    ('Payroll', Icons.payments_rounded),
    ('Transfers', Icons.swap_horiz_rounded),
    ('Treasury', Icons.account_balance_rounded),
    ('Depenses', Icons.money_off_csred_rounded),
    ('Audit', Icons.verified_user_rounded),
  ];

  final _screens = const [
    DashboardScreen(),
    SponsorsScreen(),
    AccountingScreen(),
    PayrollScreen(),
    TransfersScreen(),
    TreasuryScreen(),
    BudgetScreen(),
    AuditScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = _tabs[_index];
    final profileImageProvider = _resolveProfileImage(widget.profileImage);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finance & Accounting',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '${tab.$1.toUpperCase()}  •  ${widget.roleLabel}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                letterSpacing: 1.3,
                color: FinancePalette.blue,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: FinancePalette.blue,
              backgroundImage: profileImageProvider,
              child: profileImageProvider == null
                  ? Text(widget.avatarLabel)
                  : null,
            ),
          ),
          if (widget.onLogout != null)
            IconButton(
              onPressed: widget.onLogout,
              tooltip: 'Logout',
              icon: const Icon(Icons.logout_rounded),
            ),
        ],
      ),
      body: GradientShell(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          child: KeyedSubtree(key: ValueKey(_index), child: _screens[_index]),
        ),
      ),
      bottomNavigationBar: Container(
        color: FinancePalette.card,
        padding: const EdgeInsets.only(bottom: 10, top: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final selected = i == _index;
              final entry = _tabs[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  selected: selected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        entry.$2,
                        size: 16,
                        color: selected ? Colors.white : FinancePalette.blue,
                      ),
                      const SizedBox(width: 6),
                      Text(entry.$1),
                    ],
                  ),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : FinancePalette.blue,
                    fontWeight: FontWeight.w700,
                  ),
                  selectedColor: FinancePalette.blue,
                  backgroundColor: FinancePalette.soft,
                  onSelected: (_) => setState(() => _index = i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

ImageProvider? _resolveProfileImage(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final raw = value.trim();
  if (raw.startsWith('data:image')) {
    try {
      final commaIndex = raw.indexOf(',');
      if (commaIndex == -1) {
        return null;
      }
      final base64Data = raw.substring(commaIndex + 1);
      final bytes = base64Decode(base64Data);
      return MemoryImage(Uint8List.fromList(bytes));
    } catch (_) {
      return null;
    }
  }

  return NetworkImage(raw);
}

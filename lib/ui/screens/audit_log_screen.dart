import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../user_management/api/user_management_api.dart';
import '../../user_management/models/user_management_models.dart';
import '../components/app_card.dart';
import '../components/app_section_header.dart';
import '../components/empty_state.dart';
import '../components/loading_state.dart';
import '../shell/app_shell.dart';
import '../theme/app_spacing.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final UserManagementApi _api = UserManagementApi();
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _clubIdController = TextEditingController();
  final TextEditingController _actionController = TextEditingController();
  final TextEditingController _entityTypeController = TextEditingController();

  AuditLogsPage? _page;
  AuditStatsModel? _stats;
  io.Socket? _auditSocket;
  bool _loading = true;
  bool _liveConnected = false;
  String? _error;
  String? _module;
  int _pageIndex = 1;

  static const List<String> _modules = [
    'USER',
    'MESSAGE',
    'FINANCE',
    'PERFORMANCE',
    'CALL',
    'NOTIFICATION',
    'SYSTEM',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(resetPage: true));
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _userIdController.dispose();
    _clubIdController.dispose();
    _actionController.dispose();
    _entityTypeController.dispose();
    _auditSocket?.dispose();
    super.dispose();
  }

  Future<void> _load({bool resetPage = false}) async {
    final session = AppShellScope.of(context)?.session;
    if (session == null) return;
    _connectRealtimeAudit(session.token);
    if (resetPage) _pageIndex = 1;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getAuditLogs(
          session.token,
          page: _pageIndex,
          limit: 25,
          keyword: _keywordController.text,
          userId: _userIdController.text,
          clubId: _clubIdController.text,
          action: _actionController.text,
          module: _module,
          entityType: _entityTypeController.text,
        ),
        _api.getAuditStats(session.token),
      ]);
      if (!mounted) return;
      setState(() {
        _page = results[0] as AuditLogsPage;
        _stats = results[1] as AuditStatsModel;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearFilters() {
    _keywordController.clear();
    _userIdController.clear();
    _clubIdController.clear();
    _actionController.clear();
    _entityTypeController.clear();
    setState(() => _module = null);
    _load(resetPage: true);
  }

  void _connectRealtimeAudit(String token) {
    if (_auditSocket != null) return;
    _auditSocket = _api.connectAuditSocket(
      token: token,
      onConnect: () {
        if (mounted) setState(() => _liveConnected = true);
      },
      onDisconnect: (_) {
        if (mounted) setState(() => _liveConnected = false);
      },
      onConnectError: (_) {
        if (mounted) setState(() => _liveConnected = false);
      },
      onAuditLogCreated: _handleRealtimeAuditLog,
    );
  }

  void _handleRealtimeAuditLog(AuditLogModel log) {
    if (!mounted || !_matchesCurrentFilters(log)) return;
    final current = _page;
    final nextItems = <AuditLogModel>[
      log,
      if (current != null)
        ...current.items.where((item) => item.id != log.id).take(24),
    ];

    setState(() {
      _page = AuditLogsPage(
        items: nextItems,
        page: current?.page ?? 1,
        limit: current?.limit ?? 25,
        total: (current?.total ?? 0) + 1,
        totalPages: current?.totalPages ?? 1,
      );
      _stats = AuditStatsModel(
        total: (_stats?.total ?? current?.total ?? 0) + 1,
        last24h: (_stats?.last24h ?? 0) + 1,
        suspicious: (_stats?.suspicious ?? 0) + (log.suspicious ? 1 : 0),
      );
    });
  }

  bool _matchesCurrentFilters(AuditLogModel log) {
    final keyword = _keywordController.text.trim().toLowerCase();
    final userId = _userIdController.text.trim();
    final clubId = _clubIdController.text.trim();
    final action = _actionController.text.trim().toLowerCase();
    final entityType = _entityTypeController.text.trim().toLowerCase();

    if (_module != null && _module!.isNotEmpty && log.module != _module) {
      return false;
    }
    if (userId.isNotEmpty && log.userId != userId) return false;
    if (clubId.isNotEmpty && log.clubId != clubId) return false;
    if (action.isNotEmpty && !log.action.toLowerCase().contains(action)) {
      return false;
    }
    if (entityType.isNotEmpty &&
        !log.entityType.toLowerCase().contains(entityType)) {
      return false;
    }
    if (keyword.isEmpty) return true;

    final haystack = [
      log.action,
      log.module,
      log.entityType,
      log.entityId,
      log.userId,
      log.route,
      log.method,
      log.metadata?.toString(),
    ].whereType<String>().join(' ').toLowerCase();
    return haystack.contains(keyword);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _page == null) {
      return const LoadingState(message: 'Loading audit report...');
    }

    if (_error != null && _page == null) {
      return EmptyState(
        title: 'Audit unavailable',
        message: _error!,
        icon: Icons.receipt_long_outlined,
      );
    }

    final page = _page;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Audit Trail Report',
          subtitle: _liveConnected
              ? 'Live stream active - every application action appears instantly.'
              : 'Traçabilité complète des actions administratives et sensibles.',
        ),
        const SizedBox(height: AppSpacing.s16),
        Wrap(
          spacing: AppSpacing.s12,
          runSpacing: AppSpacing.s12,
          children: [
            _MetricCard(
              title: 'Total logs',
              value: '${_stats?.total ?? page?.total ?? 0}',
              icon: Icons.receipt_long_outlined,
            ),
            _MetricCard(
              title: 'Last 24h',
              value: '${_stats?.last24h ?? 0}',
              icon: Icons.schedule_outlined,
            ),
            _MetricCard(
              title: 'Suspicious',
              value: '${_stats?.suspicious ?? 0}',
              icon: Icons.warning_amber_outlined,
              danger: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        _FiltersCard(
          keywordController: _keywordController,
          userIdController: _userIdController,
          clubIdController: _clubIdController,
          actionController: _actionController,
          entityTypeController: _entityTypeController,
          module: _module,
          modules: _modules,
          onModuleChanged: (value) => setState(() => _module = value),
          onSearch: () => _load(resetPage: true),
          onClear: _clearFilters,
        ),
        const SizedBox(height: AppSpacing.s16),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: AppSpacing.s8),
        Expanded(
          child: page == null || page.items.isEmpty
              ? const EmptyState(
                  title: 'No audit logs found',
                  message: 'Try changing your advanced search filters.',
                  icon: Icons.manage_search_outlined,
                )
              : _AuditTable(logs: page.items),
        ),
        if (page != null) _PaginationBar(page: page, onPage: _changePage),
      ],
    );
  }

  void _changePage(int nextPage) {
    if (nextPage < 1 || (_page != null && nextPage > _page!.totalPages)) return;
    _pageIndex = nextPage;
    _load();
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.keywordController,
    required this.userIdController,
    required this.clubIdController,
    required this.actionController,
    required this.entityTypeController,
    required this.module,
    required this.modules,
    required this.onModuleChanged,
    required this.onSearch,
    required this.onClear,
  });

  final TextEditingController keywordController;
  final TextEditingController userIdController;
  final TextEditingController clubIdController;
  final TextEditingController actionController;
  final TextEditingController entityTypeController;
  final String? module;
  final List<String> modules;
  final ValueChanged<String?> onModuleChanged;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced search',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s12,
            runSpacing: AppSpacing.s12,
            children: [
              _FilterField(controller: keywordController, label: 'Keyword'),
              _FilterField(controller: userIdController, label: 'User ID'),
              _FilterField(controller: clubIdController, label: 'Club ID'),
              _FilterField(controller: actionController, label: 'Action'),
              _FilterField(controller: entityTypeController, label: 'Entity'),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  initialValue: module,
                  decoration: const InputDecoration(labelText: 'Module'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All modules'),
                    ),
                    ...modules.map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    ),
                  ],
                  onChanged: onModuleChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Search'),
              ),
              const SizedBox(width: AppSpacing.s8),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.danger = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? Colors.orange
        : Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 180,
      child: AppCard(
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.headlineSmall),
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditTable extends StatelessWidget {
  const _AuditTable({required this.logs});

  final List<AuditLogModel> logs;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Time')),
              DataColumn(label: Text('Action')),
              DataColumn(label: Text('Module')),
              DataColumn(label: Text('User')),
              DataColumn(label: Text('Club')),
              DataColumn(label: Text('Entity')),
              DataColumn(label: Text('Route')),
              DataColumn(label: Text('Risk')),
            ],
            rows: logs.map((log) {
              return DataRow(
                cells: [
                  DataCell(Text(_formatDate(log.createdAt))),
                  DataCell(Text(log.action)),
                  DataCell(_Badge(text: log.module)),
                  DataCell(
                    Tooltip(
                      message: log.userId ?? 'System',
                      child: Text(log.displayUser),
                    ),
                  ),
                  DataCell(
                    Tooltip(
                      message: log.clubId ?? 'No club id',
                      child: Text(log.displayClub),
                    ),
                  ),
                  DataCell(
                    Tooltip(
                      message: log.entityId ?? 'No entity id',
                      child: Text(
                        [
                          log.entityType,
                          if (log.displayTeam != '—') log.displayTeam,
                        ].join(' · '),
                      ),
                    ),
                  ),
                  DataCell(Text(log.route ?? '—')),
                  DataCell(
                    log.suspicious
                        ? Tooltip(
                            message:
                                log.suspiciousReason ?? 'Suspicious action',
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.page, required this.onPage});

  final AuditLogsPage page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Page ${page.page} / ${page.totalPages} · ${page.total} logs'),
          IconButton(
            onPressed: page.page <= 1 ? null : () => onPage(page.page - 1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            onPressed: page.page >= page.totalPages
                ? null
                : () => onPage(page.page + 1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

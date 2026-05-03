import 'package:flutter/material.dart';

import '../../user_management/api/user_management_api.dart';
import '../../user_management/models/user_management_models.dart';
import '../components/app_card.dart';
import '../components/app_section_header.dart';
import '../components/empty_state.dart';
import '../components/loading_state.dart';
import '../shell/app_shell.dart';
import '../theme/app_spacing.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  final UserManagementApi _api = UserManagementApi();
  late final TabController _tabController;
  List<UserModel> _users = const [];
  List<UserModel> _pendingUsers = const [];
  List<ClubModel> _clubs = const [];
  List<ClubModel> _pendingClubs = const [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final session = AppShellScope.of(context)?.session;
    if (session == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getUsers(session.token),
        _api.getPendingUsers(session.token),
        _api.getAllClubs(session.token),
        _api.getPendingClubs(session.token),
      ]);
      if (!mounted) return;
      setState(() {
        _users = results[0] as List<UserModel>;
        _pendingUsers = results[1] as List<UserModel>;
        _clubs = results[2] as List<ClubModel>;
        _pendingClubs = results[3] as List<ClubModel>;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approveClub(ClubModel club, bool approve) async {
    final session = AppShellScope.of(context)?.session;
    if (session == null) return;
    final verb = approve ? 'approve' : 'reject';
    final confirmed = await _confirm(
      '$verb club',
      'Do you want to $verb ${club.name}?',
    );
    if (!confirmed) return;
    try {
      await _api.approveClub(session.token, club.id, approve);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Club ${approve ? 'approved' : 'rejected'}')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _approveUser(UserModel user, bool approve) async {
    final session = AppShellScope.of(context)?.session;
    if (session == null) return;
    final verb = approve ? 'approve' : 'reject';
    final confirmed = await _confirm(
      '$verb user',
      'Do you want to $verb ${user.fullName}?',
    );
    if (!confirmed) return;
    try {
      if (approve) {
        await _api.approveUser(session.token, user.id, true);
      } else {
        await _api.approveUser(session.token, user.id, false);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ${approve ? 'approved' : 'rejected'}')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  List<UserModel> get _filteredUsers {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _users;
    return _users.where((user) {
      final clubName = _clubName(user.clubId).toLowerCase();
      return user.fullName.toLowerCase().contains(q) ||
          user.email.toLowerCase().contains(q) ||
          user.role.toLowerCase().contains(q) ||
          user.status.toLowerCase().contains(q) ||
          clubName.contains(q) ||
          (user.clubId ?? '').toLowerCase().contains(q);
    }).toList();
  }

  List<ClubModel> get _filteredClubs {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _clubs;
    return _clubs.where((club) {
      return club.name.toLowerCase().contains(q) ||
          club.league.toLowerCase().contains(q) ||
          club.status.toLowerCase().contains(q) ||
          (club.country ?? '').toLowerCase().contains(q) ||
          (club.city ?? '').toLowerCase().contains(q);
    }).toList();
  }

  String _clubName(String? clubId) {
    if (clubId == null || clubId.isEmpty) return 'No club';
    for (final club in _clubs) {
      if (club.id == clubId) return club.name.isEmpty ? club.id : club.name;
    }
    return clubId;
  }

  Map<String, List<UserModel>> _usersByClub(List<UserModel> users) {
    final grouped = <String, List<UserModel>>{};
    for (final user in users) {
      final key = _clubName(user.clubId);
      grouped.putIfAbsent(key, () => []).add(user);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingState(message: 'Loading admin data...');
    if (_error != null) {
      return EmptyState(
        title: 'Admin data unavailable',
        message: _error!,
        icon: Icons.cloud_off_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Users & Clubs Administration',
          subtitle:
              'Approve pending clubs, manage app clubs, and review users grouped by club.',
        ),
        const SizedBox(height: AppSpacing.s16),
        Wrap(
          spacing: AppSpacing.s12,
          runSpacing: AppSpacing.s12,
          children: [
            _MetricCard(
              title: 'All clubs',
              value: '${_clubs.length}',
              icon: Icons.shield_outlined,
            ),
            _MetricCard(
              title: 'Pending clubs',
              value: '${_pendingClubs.length}',
              icon: Icons.pending_actions_outlined,
            ),
            _MetricCard(
              title: 'All users',
              value: '${_users.length}',
              icon: Icons.people_alt_outlined,
            ),
            _MetricCard(
              title: 'Pending users',
              value: '${_pendingUsers.length}',
              icon: Icons.person_add_alt_1_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            labelText: 'Search clubs, users, roles, status...',
          ),
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: AppSpacing.s16),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Clubs'),
            Tab(text: 'Users'),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ClubsSection(
                clubs: _filteredClubs,
                pendingClubs: _pendingClubs,
                onApprove: (club) => _approveClub(club, true),
                onReject: (club) => _approveClub(club, false),
              ),
              _UsersGroupedSection(
                groupedUsers: _usersByClub(_filteredUsers),
                pendingUserIds: _pendingUsers.map((user) => user.id).toSet(),
                onApprove: (user) => _approveUser(user, true),
                onReject: (user) => _approveUser(user, false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: AppCard(
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
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

class _ClubsSection extends StatelessWidget {
  const _ClubsSection({
    required this.clubs,
    required this.pendingClubs,
    required this.onApprove,
    required this.onReject,
  });

  final List<ClubModel> clubs;
  final List<ClubModel> pendingClubs;
  final ValueChanged<ClubModel> onApprove;
  final ValueChanged<ClubModel> onReject;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (pendingClubs.isNotEmpty) ...[
          Text(
            'Pending club approvals',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.s8),
          for (final club in pendingClubs)
            _ClubCard(
              club: club,
              actions: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () => onReject(club),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Reject'),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  FilledButton.icon(
                    onPressed: () => onApprove(club),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Approve'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.s16),
        ],
        Text('All clubs', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.s8),
        if (clubs.isEmpty)
          const EmptyState(
            title: 'No clubs found',
            message: 'Try changing the search filter.',
            icon: Icons.shield_outlined,
          )
        else
          for (final club in clubs) _ClubCard(club: club),
      ],
    );
  }
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.club, this.actions});

  final ClubModel club;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: AppCard(
        child: Row(
          children: [
            CircleAvatar(
              child: Text(
                club.name.isEmpty
                    ? 'C'
                    : club.name.substring(0, 1).toUpperCase(),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club.name.isEmpty ? 'Unnamed club' : club.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    '${club.league.isEmpty ? 'No league' : club.league} · ${club.country ?? 'No country'} · ${club.city ?? 'No city'}',
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  _Badge(text: club.status, status: club.status),
                ],
              ),
            ),
            if (actions != null) actions!,
          ],
        ),
      ),
    );
  }
}

class _UsersGroupedSection extends StatelessWidget {
  const _UsersGroupedSection({
    required this.groupedUsers,
    required this.pendingUserIds,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, List<UserModel>> groupedUsers;
  final Set<String> pendingUserIds;
  final ValueChanged<UserModel> onApprove;
  final ValueChanged<UserModel> onReject;

  @override
  Widget build(BuildContext context) {
    if (groupedUsers.isEmpty) {
      return const EmptyState(
        title: 'No users found',
        message: 'Try changing the search filter.',
        icon: Icons.people_outline,
      );
    }

    final entries = groupedUsers.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return ListView(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s8),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                initiallyExpanded: true,
                title: Text('${entry.key} (${entry.value.length})'),
                children: [
                  for (final user in entry.value)
                    _UserTile(
                      user: user,
                      pending: pendingUserIds.contains(user.id),
                      onApprove: () => onApprove(user),
                      onReject: () => onReject(user),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.pending,
    required this.onApprove,
    required this.onReject,
  });

  final UserModel user;
  final bool pending;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          user.firstName.isEmpty
              ? 'U'
              : user.firstName.substring(0, 1).toUpperCase(),
        ),
      ),
      title: Text(user.fullName.trim().isEmpty ? user.email : user.fullName),
      subtitle: Text('${user.email} · ${user.role}'),
      trailing: Wrap(
        spacing: AppSpacing.s8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Badge(text: user.status, status: user.status),
          if (pending) ...[
            TextButton(onPressed: onReject, child: const Text('Reject')),
            FilledButton(onPressed: onApprove, child: const Text('Approve')),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.status});

  final String text;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final normalized = (status ?? text).toUpperCase();
    final color = normalized.contains('ACTIVE')
        ? Colors.green
        : normalized.contains('PENDING')
        ? Colors.orange
        : normalized.contains('REJECT')
        ? Colors.red
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:odinclub/user_management/api/user_management_api.dart';
import 'package:odinclub/user_management/models/user_management_models.dart';

import '../theme/admin_theme.dart';

enum _AdminView { dashboard, users, clubs, audit }

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.onLogout,
    required this.onToggleTheme,
    required this.adminName,
    required this.token,
    required this.api,
  });

  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;
  final String adminName;
  final String token;
  final UserManagementApi api;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  _AdminView _currentView = _AdminView.dashboard;
  bool _menuOpen = true;

  bool _loading = true;
  String? _error;
  String? _actionUserId;

  final TextEditingController _userSearchController = TextEditingController();
  String? _selectedClubId;

  List<ClubModel> _pendingClubs = [];
  List<ClubModel> _activeClubs = [];
  List<UserModel> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pending = await widget.api.getPendingClubs(widget.token);
      final active = await widget.api.getActiveClubs();
      final users = await widget.api.getUsers(widget.token);

      if (mounted) {
        setState(() {
          _pendingClubs = pending;
          _activeClubs = active;
          _allUsers = users;
          if (_selectedClubId == null && active.isNotEmpty) {
            _selectedClubId = active.first.id;
          }
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _handleApproval(String clubId, bool approve) async {
    try {
      await widget.api.approveClub(widget.token, clubId, approve);
      await _loadData();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user'),
        content: Text('Delete ${user.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _actionUserId = user.id);

    try {
      await widget.api.deleteUser(widget.token, user.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${user.fullName} deleted.')));
      }
      await _loadData();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _actionUserId = null);
      }
    }
  }

  Future<void> _openEditUserDialog(UserModel user) async {
    final firstName = TextEditingController(text: user.firstName);
    final lastName = TextEditingController(text: user.lastName);
    final email = TextEditingController(text: user.email);
    final phone = TextEditingController(text: user.phone);
    final photoUrl = TextEditingController(text: user.photoUrl ?? '');

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update ${user.fullName}'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: firstName,
                    decoration: const InputDecoration(labelText: 'First name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: lastName,
                    decoration: const InputDecoration(labelText: 'Last name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: email,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: photoUrl,
                    decoration: const InputDecoration(
                      labelText: 'Photo URL / data-url',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (updated != true) {
      return;
    }

    setState(() => _actionUserId = user.id);

    try {
      await widget.api.updateUser(widget.token, user.id, {
        'firstName': firstName.text.trim(),
        'lastName': lastName.text.trim(),
        'email': email.text.trim(),
        'phone': phone.text.trim(),
        'photoUrl': photoUrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${user.fullName} updated.')));
      }

      await _loadData();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _actionUserId = null);
      }
    }
  }

  List<UserModel> _filteredUsers(List<UserModel> sourceUsers) {
    final query = _userSearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return sourceUsers;
    }

    return sourceUsers.where((user) {
      final fullName = user.fullName.toLowerCase();
      final email = user.email.toLowerCase();
      final phone = user.phone.toLowerCase();
      final role = user.role.toLowerCase();
      final clubName = _clubNameForUser(user).toLowerCase();
      return fullName.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          role.contains(query) ||
          clubName.contains(query);
    }).toList();
  }

  String _clubNameForUser(UserModel user) {
    final club = _findClubById(user.clubId);
    return club?.name ?? '-';
  }

  String _clubCountryForUser(UserModel user) {
    final club = _findClubById(user.clubId);
    return (club?.country?.trim().isNotEmpty ?? false) ? club!.country! : '-';
  }

  ClubModel? _findClubById(String? clubId) {
    if (clubId == null || clubId.isEmpty) {
      return null;
    }
    return [..._activeClubs, ..._pendingClubs].cast<ClubModel?>().firstWhere(
      (club) => club?.id == clubId,
      orElse: () => null,
    );
  }

  Future<void> _toggleUserEnabled(UserModel user) async {
    final targetStatus = user.status == 'ACTIVE' ? 'REJECTED' : 'ACTIVE';
    final actionLabel = targetStatus == 'ACTIVE' ? 'enabled' : 'disabled';

    setState(() => _actionUserId = user.id);
    try {
      await widget.api.updateUser(widget.token, user.id, {
        'status': targetStatus,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.fullName} $actionLabel.')),
        );
      }
      await _loadData();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _actionUserId = null);
      }
    }
  }

  ImageProvider? _resolveAvatar(String? photoUrl) {
    if (photoUrl == null || photoUrl.trim().isEmpty) {
      return null;
    }

    final raw = photoUrl.trim();

    if (raw.startsWith('data:image')) {
      try {
        final comma = raw.indexOf(',');
        if (comma == -1) {
          return null;
        }
        final b64 = raw.substring(comma + 1);
        final bytes = base64Decode(b64);
        return MemoryImage(Uint8List.fromList(bytes));
      } catch (_) {
        return null;
      }
    }

    return NetworkImage(raw);
  }

  @override
  Widget build(BuildContext context) {
    final responsableUsers = _allUsers
        .where((u) => u.role == 'CLUB_RESPONSABLE')
        .toList();
    final filteredUsers = _filteredUsers(responsableUsers);
    final allClubs = [..._activeClubs, ..._pendingClubs];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedClub = allClubs.cast<ClubModel?>().firstWhere(
      (club) => club?.id == _selectedClubId,
      orElse: () => allClubs.isNotEmpty ? allClubs.first : null,
    );
    final clubUsers = selectedClub == null
        ? <UserModel>[]
        : _allUsers.where((user) => user.clubId == selectedClub.id).toList();

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: _menuOpen ? 250 : 88,
          color: AdminPalette.night,
          padding: EdgeInsets.fromLTRB(_menuOpen ? 20 : 12, 24, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: AdminPalette.electric,
                    child: const Text('F'),
                  ),
                  if (_menuOpen) ...[
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'FOOTBALL ADMIN',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  IconButton(
                    tooltip: _menuOpen ? 'Close menu' : 'Open menu',
                    onPressed: () => setState(() => _menuOpen = !_menuOpen),
                    icon: Icon(
                      _menuOpen ? Icons.menu_open_rounded : Icons.menu_rounded,
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _navItem(
                'Dashboard',
                _currentView == _AdminView.dashboard,
                () => setState(() => _currentView = _AdminView.dashboard),
                icon: Icons.grid_view_rounded,
              ),
              _navItem(
                'Users',
                _currentView == _AdminView.users,
                () => setState(() => _currentView = _AdminView.users),
                icon: Icons.people_alt_rounded,
              ),
              _navItem(
                'Clubs',
                _currentView == _AdminView.clubs,
                () => setState(() => _currentView = _AdminView.clubs),
                icon: Icons.shield_outlined,
              ),
              _navItem(
                'Approvals',
                false,
                null,
                icon: Icons.fact_check_outlined,
              ),
              _navItem(
                'Audit',
                _currentView == _AdminView.audit,
                () => setState(() => _currentView = _AdminView.audit),
                icon: Icons.verified_user_outlined,
              ),
              const Spacer(),
              if (_menuOpen)
                Text(
                  widget.adminName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (_menuOpen) const SizedBox(height: 10),
              _menuActionButton(
                icon: isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                label: isDark ? 'Light mode' : 'Dark mode',
                onTap: widget.onToggleTheme,
                primary: false,
              ),
              const SizedBox(height: 10),
              _menuActionButton(
                icon: Icons.logout_rounded,
                label: 'Logout',
                onTap: widget.onLogout,
                primary: true,
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : switch (_currentView) {
                    _AdminView.dashboard => _buildDashboardView(),
                    _AdminView.users => _buildUsersView(filteredUsers),
                    _AdminView.clubs => _buildClubsView(
                      selectedClub,
                      clubUsers,
                    ),
                    _AdminView.audit => _buildAuditView(),
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardView() {
    final surface = Theme.of(context).colorScheme.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Admin Control Center',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Global supervision of clubs, approvals and operational finance',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AdminPalette.ink.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Pending Responsable Requests',
                value: '${_pendingClubs.length}',
                trend: 'Awaiting review',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Approved Clubs',
                value: '${_activeClubs.length}',
                trend: 'Active list',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Total Clubs',
                value: '${_activeClubs.length + _pendingClubs.length}',
                trend: 'Registered by responsables',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Approve Responsable Requests',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 14),
                      if (_pendingClubs.isEmpty)
                        const Text('No pending responsable requests.'),
                      ..._pendingClubs.map(
                        (club) => _PendingApprovalRow(
                          club: club,
                          onApprove: () => _handleApproval(club.id, true),
                          onReject: () => _handleApproval(club.id, false),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Club List (Responsable Entries)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 14),
                      if (_activeClubs.isEmpty)
                        const Text('No active clubs yet.'),
                      ..._activeClubs.map(
                        (club) => _ApprovedRow(
                          item: '${club.name} • ${club.league}',
                          time: 'ACTIVE',
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
  }

  Widget _buildUsersView(List<UserModel> filteredUsers) {
    final activeResponsables = _allUsers
        .where((u) => u.role == 'CLUB_RESPONSABLE')
        .where((u) => u.status == 'ACTIVE')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Responsable Clubs Registry',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Only CLUB_RESPONSABLE accounts with club details and account controls',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AdminPalette.ink.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Responsables',
                value:
                    '${_allUsers.where((u) => u.role == 'CLUB_RESPONSABLE').length}',
                trend: 'Club owners',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Active Responsables',
                value: '$activeResponsables',
                trend: 'Account enabled',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Displayed',
                value: '${filteredUsers.length}',
                trend: 'After search',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _userSearchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search by club, prenom, email, phone...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _userSearchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _userSearchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.all(18),
            child: filteredUsers.isEmpty
                ? const Center(child: Text('No responsable users found.'))
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final avatar = _resolveAvatar(user.photoUrl);
                      return _ResponsableManagementRow(
                        user: user,
                        clubName: _clubNameForUser(user),
                        clubCountry: _clubCountryForUser(user),
                        loading: _actionUserId == user.id,
                        avatar: avatar,
                        onEdit: () => _openEditUserDialog(user),
                        onDelete: () => _handleDeleteUser(user),
                        onToggleEnabled: () => _toggleUserEnabled(user),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildClubsView(ClubModel? selectedClub, List<UserModel> clubUsers) {
    final clubs = [..._activeClubs, ..._pendingClubs];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Clubs',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Click on a club to display all users in that club',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AdminPalette.ink.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 14),
                if (clubs.isEmpty) const Text('No active clubs available.'),
                Expanded(
                  child: ListView.builder(
                    itemCount: clubs.length,
                    itemBuilder: (context, index) {
                      final club = clubs[index];
                      final selected = club.id == selectedClub?.id;
                      return InkWell(
                        onTap: () => setState(() => _selectedClubId = club.id),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selected
                                ? AdminPalette.electric.withValues(alpha: 0.2)
                                : AdminPalette.panel,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? AdminPalette.electric
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      club.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${club.country ?? '-'} • ${club.league} • ${club.status}',
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedClub == null
                      ? 'Club Users'
                      : 'Users • ${selectedClub.name}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  selectedClub == null
                      ? 'Select a club on the left.'
                      : 'Country: ${selectedClub.country ?? '-'} • League: ${selectedClub.league}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AdminPalette.ink.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 14),
                if (selectedClub == null)
                  const Expanded(
                    child: Center(child: Text('No club selected.')),
                  )
                else if (clubUsers.isEmpty)
                  const Expanded(
                    child: Center(child: Text('No users in this club.')),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: clubUsers.length,
                      itemBuilder: (context, index) {
                        final user = clubUsers[index];
                        final avatar = _resolveAvatar(user.photoUrl);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AdminPalette.panel,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: avatar,
                                child: avatar == null
                                    ? Text(
                                        user.firstName.isEmpty
                                            ? 'U'
                                            : user.firstName[0].toUpperCase(),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text('${user.email} • ${user.phone}'),
                                    Text(
                                      '${user.role} • ${user.status}',
                                      style: TextStyle(
                                        color: AdminPalette.ink.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _navItem(
    String title,
    bool active,
    VoidCallback? onTap, {
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: active
              ? AdminPalette.electric.withValues(alpha: 0.24)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: _menuOpen
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: Colors.white.withValues(alpha: active ? 1 : 0.72),
            ),
            if (_menuOpen) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: active ? 1 : 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _menuActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool primary,
  }) {
    final background = primary
        ? AdminPalette.deep
        : AdminPalette.electric.withValues(alpha: 0.2);
    final foreground = Colors.white;

    if (_menuOpen) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          ),
          icon: Icon(icon, size: 18),
          label: Text(label),
        ),
      );
    }

    return Align(
      alignment: Alignment.center,
      child: IconButton.filled(
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
        ),
        icon: Icon(icon),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.trend,
  });

  final String label;
  final String value;
  final String trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AdminPalette.ink.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            trend,
            style: TextStyle(
              color: AdminPalette.ok,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingApprovalRow extends StatelessWidget {
  const _PendingApprovalRow({
    required this.club,
    required this.onApprove,
    required this.onReject,
  });

  final ClubModel club;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AdminPalette.panel,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              club.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('League: ${club.league} • Status: ${club.status}'),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton(
                  onPressed: onReject,
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onApprove,
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovedRow extends StatelessWidget {
  const _ApprovedRow({required this.item, required this.time});

  final String item;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AdminPalette.panel,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(child: Text(item)),
            Text(
              time,
              style: TextStyle(color: AdminPalette.ink.withValues(alpha: 0.55)),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AdminPalette.ok.withValues(alpha: 0.15),
              ),
              child: Text(
                'APPROVED',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.ok,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsableManagementRow extends StatelessWidget {
  const _ResponsableManagementRow({
    required this.user,
    required this.clubName,
    required this.clubCountry,
    required this.loading,
    required this.avatar,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleEnabled,
  });

  final UserModel user;
  final String clubName;
  final String clubCountry;
  final bool loading;
  final ImageProvider? avatar;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AdminPalette.panel,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AdminPalette.electric.withValues(alpha: 0.2),
              backgroundImage: avatar,
              child: avatar == null
                  ? Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : 'U',
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.firstName} ${user.lastName}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text('$clubName • $clubCountry'),
                  const SizedBox(height: 2),
                  Text('${user.email} • ${user.phone}'),
                  const SizedBox(height: 2),
                  Text(
                    '${user.status == 'ACTIVE' ? 'Enabled' : 'Disabled'} • ${user.status}',
                    style: TextStyle(
                      color: AdminPalette.ink.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: loading ? null : onToggleEnabled,
              style: FilledButton.styleFrom(
                backgroundColor: user.status == 'ACTIVE'
                    ? AdminPalette.danger.withValues(alpha: 0.18)
                    : AdminPalette.ok.withValues(alpha: 0.18),
                foregroundColor: user.status == 'ACTIVE'
                    ? AdminPalette.danger
                    : AdminPalette.ok,
              ),
              child: Text(user.status == 'ACTIVE' ? 'Disable' : 'Enable'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: loading ? null : onEdit,
              child: Text(loading ? '...' : 'Update'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: loading ? null : onDelete,
              style: FilledButton.styleFrom(
                backgroundColor: AdminPalette.danger,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}

  Widget _buildAuditView() {
    final surface = Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2B356A) : const Color(0xFFE2E8F0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Audit Trail Report',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Live stream active',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 240,
              height: 40,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Quick search logs...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.notifications_none),
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              onPressed: () {},
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                ),
                const SizedBox(width: 8),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _AuditStatCard(
                title: 'TOTAL LOGS',
                value: '759',
                icon: Icons.bar_chart,
                iconColor: const Color(0xFF3B82F6),
                bgColor: const Color(0xFFEFF6FF),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _AuditStatCard(
                title: 'LAST 24H',
                value: '740',
                icon: Icons.trending_up,
                iconColor: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _AuditStatCard(
                title: 'SUSPICIOUS',
                value: '0',
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFFFBEB),
                isDark: isDark,
                borderColor: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tune,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Advanced Filter',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _FilterInput(label: 'Keyword', hint: 'Search...', isDark: isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: _FilterInput(label: 'User ID', hint: 'e.g. 8831', isDark: isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: _FilterInput(label: 'Club ID', hint: 'e.g. 502', isDark: isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: _FilterInput(label: 'Action', hint: 'e.g. login', isDark: isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: _FilterInput(label: 'Entity', hint: 'e.g. session', isDark: isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: _FilterDropdown(label: 'Module', value: 'All Modules', isDark: isDark)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    child: const Text('Clear Filters', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Search', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: _TableHeaderText('TIME', isDark)),
                      Expanded(flex: 3, child: _TableHeaderText('ACTION', isDark)),
                      Expanded(flex: 2, child: _TableHeaderText('MODULE', isDark)),
                      Expanded(flex: 3, child: _TableHeaderText('USER', isDark)),
                      Expanded(flex: 2, child: _TableHeaderText('STATUS', isDark)),
                    ],
                  ),
                ),
                Divider(height: 1, color: borderColor),
                Expanded(
                  child: ListView(
                    children: [
                      _AuditLogItem(
                        timeDate: '2023-11-24',
                        timeHour: '14:22:05 UTC',
                        actionTitle: 'USER_LOGIN_SUCCESS',
                        actionSub: '192.168.1.105',
                        module: 'AUTH',
                        moduleColor: const Color(0xFF3B82F6),
                        userInitial: 'JD',
                        userName: 'John Doe',
                        userDetail: 'john.d@enterprise.com • ID: 8831',
                        status: 'Success',
                        statusColor: const Color(0xFF10B981),
                        isDark: isDark,
                      ),
                      Divider(height: 1, color: borderColor),
                      _AuditLogItem(
                        timeDate: '2023-11-24',
                        timeHour: '14:18:12 UTC',
                        actionTitle: 'REPORT_EXPORT_GENERATED',
                        actionSub: '192.168.1.42',
                        module: 'REPORTS',
                        moduleColor: const Color(0xFFA855F7),
                        userInitial: 'SC',
                        userName: 'Sarah Connor',
                        userDetail: 's.connor@audit.io • ID: 4420',
                        status: 'Success',
                        statusColor: const Color(0xFF10B981),
                        isDark: isDark,
                      ),
                      Divider(height: 1, color: borderColor),
                      _AuditLogItem(
                        timeDate: '2023-11-24',
                        timeHour: '14:05:44 UTC',
                        actionTitle: 'SETTINGS_UPDATE_DENIED',
                        actionSub: '203.0.113.12',
                        module: 'SYSTEM',
                        moduleColor: const Color(0xFFF59E0B),
                        userInitial: 'UK',
                        userName: 'Unknown User',
                        userDetail: 'guest_access_99 • ID: 0000',
                        status: 'Permission Denied',
                        statusColor: const Color(0xFFEF4444),
                        isDark: isDark,
                      ),
                      Divider(height: 1, color: borderColor),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.chevron_left, size: 16, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.chevron_right, size: 16, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                      const Spacer(),
                      Text(
                        'Page 1 / 31 • ',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '759 logs',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

class _TableHeaderText extends StatelessWidget {
  const _TableHeaderText(this.text, this.isDark);
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: isDark ? Colors.white54 : const Color(0xFF64748B),
      ),
    );
  }
}

class _AuditStatCard extends StatelessWidget {
  const _AuditStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.isDark,
    this.borderColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final bool isDark;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? (isDark ? const Color(0xFF2B356A) : const Color(0xFFE2E8F0)),
          width: borderColor != null ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withOpacity(0.2) : bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
        ],
      ),
    );
  }
}

class _FilterInput extends StatelessWidget {
  const _FilterInput({required this.label, required this.hint, required this.isDark});
  final String label;
  final String hint;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: TextField(
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF2B356A) : const Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF2B356A) : const Color(0xFFE2E8F0),
                ),
              ),
              filled: false,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({required this.label, required this.value, required this.isDark});
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF2B356A) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuditLogItem extends StatelessWidget {
  const _AuditLogItem({
    required this.timeDate,
    required this.timeHour,
    required this.actionTitle,
    required this.actionSub,
    required this.module,
    required this.moduleColor,
    required this.userInitial,
    required this.userName,
    required this.userDetail,
    required this.status,
    required this.statusColor,
    required this.isDark,
  });

  final String timeDate;
  final String timeHour;
  final String actionTitle;
  final String actionSub;
  final String module;
  final Color moduleColor;
  final String userInitial;
  final String userName;
  final String userDetail;
  final String status;
  final Color statusColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? Colors.white54 : const Color(0xFF94A3B8);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timeDate, style: TextStyle(fontWeight: FontWeight.w600, color: titleColor)),
                const SizedBox(height: 4),
                Text(timeHour, style: TextStyle(fontSize: 12, color: subColor)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(actionTitle, style: TextStyle(fontWeight: FontWeight.w700, color: titleColor)),
                const SizedBox(height: 4),
                Text(actionSub, style: TextStyle(fontSize: 12, color: subColor)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: moduleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  module,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: moduleColor,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: moduleColor.withOpacity(0.15),
                  child: Text(
                    userInitial,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: moduleColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: TextStyle(fontWeight: FontWeight.w600, color: titleColor)),
                      const SizedBox(height: 4),
                      Text(userDetail, style: TextStyle(fontSize: 12, color: subColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


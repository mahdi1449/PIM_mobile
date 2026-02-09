import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/theme_toggle_button.dart';
import 'login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'account_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _userEmail;
  String? _userRole;
  String? _userFirstName;
  String? _userLastName;

  int _selectedIndex = 2;

  double _scale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = width / 390.0;
    return scale.clamp(0.85, 1.2);
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      // Get user profile from API
      final result = await _apiService.getUserProfile();

      if (result['success'] && result['data'] != null) {
        final userData = result['data'];
        setState(() {
          _userEmail = userData['email'];
          _userRole = userData['role'];
          _userFirstName = userData['firstName'];
          _userLastName = userData['lastName'];
        });
      } else {
        // Fallback: try to decode token
        final token = await _apiService.getToken();
        if (token != null) {
          try {
            final parts = token.split('.');
            if (parts.length == 3) {
              final payload = parts[1];
              final normalized = base64.normalize(payload);
              final decoded = utf8.decode(base64.decode(normalized));
              final Map<String, dynamic> payloadMap = jsonDecode(decoded);

              setState(() {
                _userEmail = payloadMap['email'];
                _userRole = payloadMap['role'];
              });
            }
          } catch (e) {
            // If decoding fails, just show placeholder
            setState(() {
              _userEmail = 'user@example.com';
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _userEmail = 'user@example.com';
      });
    }
  }

  Future<void> _handleLogout() async {
    await _apiService.removeToken();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.blueFonce,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          tooltip: 'Menu',
        ),
        title: Text(
          'Club Management',
          style: TextStyle(
            color: AppTheme.blueFonce,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          Padding(
            padding: EdgeInsets.only(right: 16 * scale),
            child: CircleAvatar(
              radius: 18 * scale,
              backgroundColor: AppTheme.blueCiel.withOpacity(0.3),
              child: Text(
                _initials(),
                style: TextStyle(
                  color: AppTheme.blueFonce,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, scale),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDrawer(BuildContext context, double scale) {
    final isDark = ThemeController.isDark(context);
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20 * scale, 24 * scale, 20 * scale, 16 * scale),
              decoration: BoxDecoration(
                color: AppTheme.blueFonce.withOpacity(0.08),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.strokeDark,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32 * scale,
                    backgroundColor: AppTheme.blueCiel.withOpacity(0.3),
                    child: Text(
                      _initials(),
                      style: TextStyle(
                        color: AppTheme.blueFonce,
                        fontWeight: FontWeight.bold,
                        fontSize: 22 * scale,
                      ),
                    ),
                  ),
                  SizedBox(height: 12 * scale),
                  Text(
                    '${_userFirstName ?? ''} ${_userLastName ?? ''}'.trim().isEmpty
                        ? 'User'
                        : '${_userFirstName ?? ''} ${_userLastName ?? ''}'.trim(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.blueFonce,
                    ),
                  ),
                  if (_userEmail != null) ...[
                    SizedBox(height: 4 * scale),
                    Text(
                      _userEmail!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                  ],
                  if (_userRole != null) ...[
                    SizedBox(height: 6 * scale),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
                      decoration: BoxDecoration(
                        color: AppTheme.blueCiel.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _userRole!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.blueFonce,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 8 * scale),
                children: [
                  ListTile(
                    leading: Icon(Icons.settings, color: AppTheme.blueFonce),
                    title: Text(
                      'Account & Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.blueFonce,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AccountSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: AppTheme.blueFonce,
                    ),
                    title: Text(
                      isDark ? 'Dark mode (On)' : 'Light mode',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.blueFonce,
                      ),
                    ),
                    trailing: Switch(
                      value: isDark,
                      onChanged: (_) {
                        ThemeController.toggle();
                        setState(() {});
                      },
                      activeColor: AppTheme.blueCiel,
                    ),
                  ),
                  if (_userRole == 'Administrateur')
                    ListTile(
                      leading: Icon(Icons.admin_panel_settings, color: AppTheme.blueFonce),
                      title: Text(
                        'Admin Panel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.blueFonce,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminDashboardScreen(),
                          ),
                        );
                      },
                    ),
                  const Divider(height: 24),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red.shade700),
                    title: Text(
                      'Logout',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade700,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _handleLogout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials() {
    final first = _userFirstName?.trim();
    final last = _userLastName?.trim();
    if (first != null && first.isNotEmpty) {
      final firstChar = first[0].toUpperCase();
      final lastChar = (last != null && last.isNotEmpty) ? last[0].toUpperCase() : '';
      return '$firstChar$lastChar';
    }
    return 'OC';
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildPlayersView();
      case 1:
        return _buildStaffView();
      case 2:
        return _buildDashboardView();
      case 3:
        return _buildFinanceView();
      case 4:
        return _buildReportsView();
      default:
        return _buildDashboardView();
    }
  }

  Widget _buildDashboardView() {
    final scale = _scale(context);
    final greetingName = _userFirstName ?? 'Coach';

    return ListView(
      padding: EdgeInsets.fromLTRB(20 * scale, 16 * scale, 20 * scale, 100 * scale),
      children: [
        Text(
          'Welcome, $greetingName',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.blueFonce,
          ),
        ),
        if (_userRole != null) ...[
          const SizedBox(height: 6),
          Text(
            _userRole!,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.darkGrey.withOpacity(0.7),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _statCard(
          icon: Icons.people,
          title: 'Total Players',
          value: '124',
          change: '+12%',
          changePositive: true,
        ),
        SizedBox(height: 12 * scale),
        _statCard(
          icon: Icons.shield,
          title: 'Club Staff',
          value: '42',
          change: '+5%',
          changePositive: true,
          iconColor: const Color(0xFFFFB020),
        ),
        SizedBox(height: 12 * scale),
        _statCard(
          icon: Icons.attach_money,
          title: 'Budget Utilization',
          value: '78%',
          change: '-2%',
          changePositive: false,
          iconColor: const Color(0xFF1CC98A),
        ),
        SizedBox(height: 12 * scale),
        _statCard(
          icon: Icons.monitor_heart,
          title: 'Active Injuries',
          value: '8',
          change: '-15%',
          changePositive: false,
          iconColor: const Color(0xFFE95464),
        ),
        SizedBox(height: 20 * scale),
        _sectionTitle('Performance Trends'),
        SizedBox(height: 12 * scale),
        _chartPlaceholder(height: 220 * scale),
        SizedBox(height: 20 * scale),
        _sectionTitle('Budget Allocation'),
        SizedBox(height: 12 * scale),
        _chartPlaceholder(height: 180 * scale),
        SizedBox(height: 12 * scale),
        _logoutRow(),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.blueFonce,
            ),
          ),
        ),
        Icon(
          Icons.more_horiz,
          color: AppTheme.blueFonce.withOpacity(0.6),
        ),
      ],
    );
  }

  Widget _chartPlaceholder({double height = 220}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.area_chart,
          size: 64,
          color: AppTheme.blueCiel.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required String change,
    required bool changePositive,
    Color? iconColor,
  }) {
    final accent = iconColor ?? AppTheme.blueCiel;
    final scale = _scale(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 14 * scale),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44 * scale,
            height: 44 * scale,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            child: Icon(icon, color: accent, size: 22 * scale),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: AppTheme.darkGrey.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.blueFonce,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(
                changePositive ? Icons.trending_up : Icons.trending_down,
                color: changePositive ? const Color(0xFF1CC98A) : const Color(0xFFE95464),
                size: 16 * scale,
              ),
              SizedBox(width: 4 * scale),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w600,
                  color: changePositive ? const Color(0xFF1CC98A) : const Color(0xFFE95464),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logoutRow() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Sign out'),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.blueFonce,
        ),
      ),
    );
  }

  Widget _buildPlayersView() {
    return _simplePlaceholder(
      title: 'Players',
      subtitle: 'Manage your squad and player profiles.',
      icon: Icons.people_outline,
    );
  }

  Widget _buildStaffView() {
    return _simplePlaceholder(
      title: 'Staff',
      subtitle: 'Track coaches, scouts, and support staff.',
      icon: Icons.badge_outlined,
    );
  }

  Widget _buildFinanceView() {
    return _simplePlaceholder(
      title: 'Finance',
      subtitle: 'Monitor budgets, payroll, and transfers.',
      icon: Icons.account_balance_wallet_outlined,
    );
  }

  Widget _buildReportsView() {
    return _simplePlaceholder(
      title: 'Reports',
      subtitle: 'Review performance and operational reports.',
      icon: Icons.insert_chart_outlined,
    );
  }

  Widget _simplePlaceholder({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final scale = _scale(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24 * scale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72 * scale,
              height: 72 * scale,
              decoration: BoxDecoration(
                color: AppTheme.blueCiel.withOpacity(0.2),
                borderRadius: BorderRadius.circular(18 * scale),
              ),
              child: Icon(icon, color: AppTheme.blueFonce, size: 36 * scale),
            ),
            SizedBox(height: 16 * scale),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.blueFonce,
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14 * scale,
                color: AppTheme.darkGrey.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final scale = _scale(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12 * scale, 10 * scale, 12 * scale, 12 * scale),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navItem(
                index: 0,
                icon: Icons.group_outlined,
                label: 'Players',
              ),
              _navItem(
                index: 1,
                icon: Icons.badge_outlined,
                label: 'Staff',
              ),
              _centerNavItem(),
              _navItem(
                index: 3,
                icon: Icons.account_balance_wallet_outlined,
                label: 'Finance',
              ),
              _navItem(
                index: 4,
                icon: Icons.insert_chart_outlined,
                label: 'Reports',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final scale = _scale(context);
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppTheme.blueFonce : AppTheme.darkGrey.withOpacity(0.6);
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: SizedBox(
        width: 64 * scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22 * scale),
            SizedBox(height: 4 * scale),
            Text(
              label,
              style: TextStyle(
                fontSize: 11 * scale,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centerNavItem() {
    final scale = _scale(context);
    final isSelected = _selectedIndex == 2;
    final color = isSelected ? AppTheme.blueFonce : AppTheme.blueFonce.withOpacity(0.7);
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = 2;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56 * scale,
            height: 56 * scale,
            decoration: BoxDecoration(
              color: AppTheme.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.blueCiel.withOpacity(0.6), width: 1.5 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10 * scale,
                  offset: Offset(0, 4 * scale),
                ),
              ],
            ),
            child: Icon(
              Icons.dashboard,
              color: color,
              size: 26 * scale,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 11 * scale,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

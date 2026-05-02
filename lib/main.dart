import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'services/api_service.dart';
import 'user_management/api/user_management_api.dart';
import 'user_management/models/user_management_models.dart';
import 'utils/role_router.dart';
import 'screens/login_screen.dart';
import 'theme/theme_controller.dart';
import 'ui/theme/app_theme.dart';

// Providers
import 'providers/campaign_provider.dart';
import 'erp/providers/events_provider.dart';
import 'erp/providers/teams_provider.dart';
import 'erp/providers/clubs_provider.dart';
import 'erp/providers/players_provider.dart';
import 'erp/providers/staff_provider.dart';
import 'erp/providers/notifications_provider.dart';
import 'erp/providers/readiness_provider.dart';
import 'erp/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const RootApp());
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CampaignProvider()),
        ChangeNotifierProvider(create: (_) => EventsProvider()),
        ChangeNotifierProvider(create: (_) => TeamsProvider()),
        ChangeNotifierProvider(create: (_) => ClubsProvider()),
        ChangeNotifierProvider(create: (_) => PlayersProvider()),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => ReadinessProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.mode,
        builder: (context, themeMode, _) {
          return MaterialApp(
            title: 'ODINCLUB PIM',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const AuthCheck(),
          );
        },
      ),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final ApiService _apiService = ApiService();
  final UserManagementApi _userApi = UserManagementApi();
  bool _checking = true;
  SessionModel? _session;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        if (mounted) setState(() => _checking = false);
        return;
      }

      // Try to get profile to verify token and get user info
      final profileResponse = await _apiService.getUserProfile();
      if (profileResponse['success'] == true) {
        final userData = profileResponse['data'];
        
        // Construct SessionModel from profile and token
        _session = SessionModel(
          token: token,
          userId: (userData['_id'] ?? userData['id'] ?? '').toString(),
          role: (userData['role'] ?? '').toString(),
          email: (userData['email'] ?? '').toString(),
          status: (userData['status'] ?? '').toString(),
          clubId: (userData['clubId'] ?? (userData['club'] is Map ? userData['club']['_id'] : null))?.toString(),
          firstName: userData['firstName']?.toString(),
          lastName: userData['lastName']?.toString(),
          photoUrl: userData['photoUrl']?.toString(),
        );
      }
    } catch (e) {
      debugPrint('Auth check failed: $e');
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_session != null) {
      return buildRoleHome(_session!);
    }

    return const LoginScreen();
  }
}

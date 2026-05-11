import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'services/api_service.dart';
import 'user_management/models/user_management_models.dart';
import 'utils/role_router.dart';
import 'screens/login_screen.dart';
import 'theme/dark_theme.dart';
import 'theme/light_theme.dart';
import 'theme/theme_controller.dart';

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
import 'sports_performance/gamification/providers/gamification_provider.dart';
import 'sports_performance/cognitive_lab/providers/cognitive_lab_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await ThemeController.load();
  runApp(const ProviderScope(child: RootApp()));
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
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
        ChangeNotifierProvider(create: (_) => CognitiveLabProvider()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.mode,
        builder: (context, themeMode, _) {
          return MaterialApp(
            title: 'ODINCLUB PIM',
            debugShowCheckedModeBanner: false,
            themeAnimationDuration: const Duration(milliseconds: 280),
            themeAnimationCurve: Curves.easeOutCubic,
            themeMode: themeMode,
            theme: LightTheme.data,
            darkTheme: DarkTheme.data,
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
  bool _checking = true;
  SessionModel? _session;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn = await authProvider.tryAutoLogin();
      
      if (isLoggedIn) {
        final userData = authProvider.user!;
        final token = await _apiService.getToken();
        
        _session = SessionModel(
          token: token ?? '',
          userId: userData.id,
          role: userData.role,
          email: userData.email,
          status: userData.status,
          clubId: userData.clubId,
          firstName: userData.firstName,
          lastName: userData.lastName,
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_session != null) {
      return buildRoleHome(_session!);
    }

    return const LoginScreen();
  }
}

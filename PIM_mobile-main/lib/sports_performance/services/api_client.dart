import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Client HTTP centralisé basé sur [Dio] pour toutes les communications avec le backend.
/// Configure automatiquement :
/// - L'URL de base depuis [AppConfig]
/// - L'injection du token JWT via un intercepteur
/// - Le logging des requêtes et réponses en mode développement
class ApiClient {
  // Android Emulator accesses host machine via 10.0.2.2
  // For physical device, use your local IP e.g., 192.168.1.X
  static String get baseUrl => AppConfig.apiBaseUrl;
  
  final Dio dio;

  ApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    // Intercepteur pour l'authentification : injecte le JWT dans chaque requête
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    // Ajouter intercepteurs pour logging en développement
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );
  }

  /// Effectue une requête GET vers le backend.
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Effectue une requête POST pour créer une ressource ou déclencher une action.
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Effectue une requête PATCH pour une mise à jour partielle d'une ressource.
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Effectue une requête DELETE pour supprimer une ressource.
  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.delete(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Convertit les erreurs Dio en exceptions lisibles pour l'utilisateur.
  /// Distingue les timeouts, les erreurs serveur (4xx/5xx) et les erreurs réseau génériques.
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Délai d\'attente dépassé. Vérifiez votre connexion.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['message'] ?? 'Erreur serveur';
        return Exception('Erreur $statusCode: $message');
      case DioExceptionType.cancel:
        return Exception('Requête annulée');
      default:
        return Exception('Erreur de connexion: ${error.message}');
    }
  }
}

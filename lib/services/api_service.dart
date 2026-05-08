import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  late final Dio dio;

  ApiService() {
    dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['BASE_URL'] ?? 'https://api.themoviedb.org/3',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );

    // 2. Add an Interceptor (This is your "Global Header" logic)
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // This runs BEFORE every request
          options.headers['accept'] = 'application/json';
          options.headers['Authorization'] =
              'Bearer ${dotenv.env['TMDB_API_KEY']}';

          return handler.next(options); // Continue the request
        },
        onError: (DioException e, handler) {
          // Centralized Error Handling (Log out if 401, etc.)
          if (e.response?.statusCode == 401) {
            print("System Alert: Unauthorized. Check API Key.");
          }
          return handler.next(e);
        },
      ),
    );
  }
}

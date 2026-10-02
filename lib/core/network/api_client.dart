import 'package:dio/dio.dart';

/// API Client for handling HTTP requests
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        responseType: ResponseType.json,
      ),
    );

    // Add interceptors
    _dio?.interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) {
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    ]);
  }

  late Dio? _dio;

  Dio get dio => _dio!;

  // GET request
  Future<dynamic> get(String url, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio!.get(url, queryParameters: queryParameters);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // POST request
  Future<dynamic> post(String url, dynamic data, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio!.post(
        url,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // PUT request
  Future<dynamic> put(String url, dynamic data, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio!.put(
        url,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // DELETE request
  Future<dynamic> delete(String url, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio!.delete(url, queryParameters: queryParameters);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // Handle successful response
  dynamic _handleResponse(Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data;
    }
    throw Exception('Request failed with status: ${response.statusCode}');
  }
}

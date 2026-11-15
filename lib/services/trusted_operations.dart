import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrustedOperations {
  static const _backendUrl = String.fromEnvironment('FOODFIGHT_BACKEND_URL');
  static final _http = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 75),
    receiveTimeout: const Duration(seconds: 75),
    followRedirects: false,
    validateStatus: (_) => true,
  ));

  static Future<dynamic> call(
      String operation, Map<String, dynamic> data) async {
    if (_backendUrl.isEmpty) {
      final result =
          await FirebaseFunctions.instance.httpsCallable(operation).call(data);
      return result.data;
    }
    final base = Uri.tryParse(_backendUrl);
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        (base.path.isNotEmpty && base.path != '/')) {
      throw StateError('Expected an HTTPS origin for the Food Fight backend.');
    }
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw FirebaseFunctionsException(
          code: 'unauthenticated', message: 'Sign in to continue.');
    }
    Response<dynamic> response;
    try {
      response = await _http.postUri(
        base.replace(pathSegments: ['v1', operation]),
        data: {'data': data},
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException {
      throw FirebaseFunctionsException(
          code: 'unavailable', message: 'The service could not be reached.');
    }
    final body = response.data;
    if (response.statusCode == 200 &&
        body is Map &&
        body.containsKey('result')) {
      return body['result'];
    }
    final error = body is Map ? body['error'] : null;
    throw FirebaseFunctionsException(
      code: error is Map && error['code'] is String
          ? error['code'] as String
          : 'unavailable',
      message: error is Map && error['message'] is String
          ? error['message'] as String
          : 'The service could not complete the request.',
      details: error is Map ? error['details'] : null,
    );
  }
}

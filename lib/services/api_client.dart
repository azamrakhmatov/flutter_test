import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: Duration(seconds: 5),
      receiveTimeout: Duration(seconds: 5),
    ),
  );

  // GET Request
  Future<Response> getRequest(String endpoint) async {
    try {
      return await _dio.get(endpoint);
    } catch (e) {
      throw Exception("API Error: $e");
    }
  }

  // POST Request (CREATE)
  Future<Response> postRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      return await _dio.post(endpoint, data: data);
    } catch (e) {
      throw Exception("API POST Error: $e");
    }
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

class AppHttpClient {
  final String baseUrl;

  // stabilization-layer: do not extend yet
  AppHttpClient({required this.baseUrl});

  Uri uri(String path) => Uri.parse('$baseUrl$path');

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) {
    return http.get(uri, headers: headers);
  }

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return http.post(uri, headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return http.put(uri, headers: headers, body: body, encoding: encoding);
  }

  Future<http.StreamedResponse> sendMultipart(http.MultipartRequest request) {
    return request.send();
  }
}

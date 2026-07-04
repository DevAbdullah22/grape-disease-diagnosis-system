import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final http.Client _http;

  ApiClient(this.baseUrl, [http.Client? client])
    : _http = client ?? http.Client();

  Uri uri(String path) => Uri.parse('$baseUrl$path');

  Future<http.StreamedResponse> sendMultipart(
    http.MultipartRequest request,
  ) async {
    return _http.send(request);
  }

  Future<http.Response> get(String path, {Duration? timeout}) async {
    final requestUri = uri(path);
    if (timeout != null) {
      return _http.get(requestUri).timeout(timeout);
    }
    return _http.get(requestUri);
  }

  void dispose() {
    _http.close();
  }
}

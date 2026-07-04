class InvalidImageException implements Exception {
  final String message;
  InvalidImageException([this.message = '']);
  @override
  String toString() => 'InvalidImageException: $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = '']);
  @override
  String toString() => 'NetworkException: $message';
}

class RemoteTimeoutException implements Exception {
  final String message;
  RemoteTimeoutException([this.message = '']);
  @override
  String toString() => 'RemoteTimeoutException: $message';
}

class UnknownRemoteException implements Exception {
  final String message;
  UnknownRemoteException([this.message = '']);
  @override
  String toString() => 'UnknownRemoteException: $message';
}

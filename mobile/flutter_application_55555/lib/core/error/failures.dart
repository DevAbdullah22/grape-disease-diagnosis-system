class Failure {
  final String message;
  Failure([this.message = '']);
}

class InvalidImageFailure extends Failure {
  InvalidImageFailure([String message = '']) : super(message);
}

class NetworkFailure extends Failure {
  NetworkFailure([String message = '']) : super(message);
}

class TimeoutFailure extends Failure {
  TimeoutFailure([String message = '']) : super(message);
}

class UnknownFailure extends Failure {
  UnknownFailure([String message = '']) : super(message);
}

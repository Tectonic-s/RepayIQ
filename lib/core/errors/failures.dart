abstract class AppFailure {
  final String message;
  const AppFailure(this.message);

  @override
  String toString() => message;
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class AuthFailure extends AppFailure {
  const AuthFailure(super.message);
}

class ServerFailure extends AppFailure {
  const ServerFailure([super.message = 'Something went wrong']);
}

class CacheFailure extends AppFailure {
  const CacheFailure([super.message = 'Local data error']);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

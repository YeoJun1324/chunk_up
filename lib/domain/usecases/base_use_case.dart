// lib/domain/usecases/base_use_case.dart

/// Base usecase interface
/// T: Return type
/// P: Parameters type
abstract class UseCase<T, P> {
  Future<T> call(P params);
}

/// Use Case with no parameters
abstract class NoParamsUseCase<T> {
  Future<T> call();
}
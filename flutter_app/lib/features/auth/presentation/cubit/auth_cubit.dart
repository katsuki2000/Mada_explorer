import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final AuthRepository authRepository;

  AuthCubit({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.authRepository,
  }) : super(const AuthInitial());

  /// Called once on app start to restore a previous session (from cache
  /// if offline, from the API if online) without forcing a fresh login.
  Future<void> restoreSession() async {
    emit(const AuthLoading());
    final result = await authRepository.getCurrentUser();
    result.fold(
      (failure) => emit(const AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading());
    final result = await loginUseCase(LoginParams(email: email, password: password));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> register({required String name, required String email, required String password}) async {
    emit(const AuthLoading());
    final result = await registerUseCase(RegisterParams(name: name, email: email, password: password));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> logout() async {
    await logoutUseCase(const NoParams());
    emit(const AuthUnauthenticated());
  }

  /// Called by the DioClient when a token refresh fails irrecoverably.
  void forceLogout() {
    emit(const AuthUnauthenticated());
  }
}

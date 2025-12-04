import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _authRepository.signInWithEmailAndPassword(email, password));
  }

  Future<void> register(String email, String password, String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        _authRepository.createUserWithEmailAndPassword(email, password, name));
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.signInWithGoogle());
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.signOut());
  }

  Future<void> forgotPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _authRepository.sendPasswordResetEmail(email));
  }

  Future<String?> uploadImage(File file, String userId) async {
    state = const AsyncValue.loading();
    try {
      final url = await _authRepository.uploadProfileImage(file, userId);
      state = const AsyncValue.data(null);
      return url;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.updateProfile(
          displayName: displayName,
          photoURL: photoURL,
        ));
  }
}

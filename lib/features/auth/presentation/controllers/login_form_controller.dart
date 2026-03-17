import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/auth_models.dart';
import 'auth_controller.dart';

class LoginFormController extends StateNotifier<AsyncValue<void>> {
  LoginFormController(this.ref) : super(const AsyncData(null));

  final Ref ref;

  Future<void> submit(LoginPayload payload) async {
    if (!mounted) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(authControllerProvider.notifier).login(payload);
    });
    if (!mounted) return;
    state = result;
  }
}

final loginFormControllerProvider =
    StateNotifierProvider.autoDispose<LoginFormController, AsyncValue<void>>(
  LoginFormController.new,
  name: 'LoginFormControllerProvider',
);

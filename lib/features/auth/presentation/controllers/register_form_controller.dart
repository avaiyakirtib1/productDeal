import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/auth_models.dart';
import 'auth_controller.dart';

class RegisterFormController extends StateNotifier<AsyncValue<void>> {
  RegisterFormController(this.ref) : super(const AsyncData(null));

  final Ref ref;

  Future<void> submit(RegisterPayload payload) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authControllerProvider.notifier).register(payload);
    });
  }
}

final registerFormControllerProvider =
    StateNotifierProvider.autoDispose<RegisterFormController, AsyncValue<void>>(
  RegisterFormController.new,
  name: 'RegisterFormControllerProvider',
);

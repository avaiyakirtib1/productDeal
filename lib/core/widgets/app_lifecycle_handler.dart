import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/manager/presentation/screens/manager_dashboard_screen.dart';

/// Listens to app lifecycle and invalidates manager stats when app resumes.
/// Ensures manager dashboard shows fresh data when user returns from background
/// (e.g. after placing order from another device).
class AppLifecycleHandler extends ConsumerStatefulWidget {
  const AppLifecycleHandler({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends ConsumerState<AppLifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(managerStatsProvider);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

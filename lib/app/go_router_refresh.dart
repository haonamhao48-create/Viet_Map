import 'dart:async';

import 'package:flutter/foundation.dart';

/// Báo cho GoRouter refresh khi auth stream thay đổi.
class GoRouterAuthRefreshNotifier extends ChangeNotifier {
  GoRouterAuthRefreshNotifier(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

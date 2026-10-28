import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/viewer.dart';
import '../../auth/application/auth_controller.dart';
import '../../catalog/application/catalog_providers.dart';
import '../data/viewer_repository.dart';

class ContinueWatchingController extends AsyncNotifier<List<ContinueWatchingItem>> {
  @override
  Future<List<ContinueWatchingItem>> build() async {
    if (!ref.watch(isSignedInProvider)) return const [];
    return ref.read(viewerRepositoryProvider).continueWatching();
  }

  /// Optimistically removes the item; restores it if the request fails.
  Future<void> remove(ContinueWatchingItem item) async {
    final before = state.value ?? const [];
    state = AsyncData(before.where((i) => i.id != item.id).toList());
    try {
      await ref.read(viewerRepositoryProvider).removeContinueWatching(item.id);
      ref.invalidate(homeFeedProvider);
    } catch (_) {
      if (ref.mounted) state = AsyncData(before);
      rethrow;
    }
  }
}

final continueWatchingProvider =
    AsyncNotifierProvider<ContinueWatchingController, List<ContinueWatchingItem>>(ContinueWatchingController.new);

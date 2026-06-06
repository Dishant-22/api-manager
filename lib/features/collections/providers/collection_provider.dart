import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/storage/hive_service.dart';
import '../models/collection.dart';
import '../../requests/models/api_request.dart';

class CollectionNotifier extends StateNotifier<List<Collection>> {
  CollectionNotifier() : super([]) {
    _load();
  }

  void _load() {
    var collections = HiveService.getCollections();
    if (collections.isEmpty) {
      collections = [
        Collection(
          name: 'Sample Requests',
          description: 'Example API requests to get started',
          requests: [
            SavedRequest(
              name: 'Get Posts',
              request: ApiRequest(
                name: 'Get Posts',
                url: 'https://jsonplaceholder.typicode.com/posts',
              ),
            ),
            SavedRequest(
              name: 'Get Users',
              request: ApiRequest(
                name: 'Get Users',
                url: 'https://jsonplaceholder.typicode.com/users',
              ),
            ),
            SavedRequest(
              name: 'HTTPBin GET',
              request: ApiRequest(
                name: 'HTTPBin GET',
                url: 'https://httpbin.org/get',
              ),
            ),
          ],
        ),
      ];
      HiveService.saveCollections(collections);
    }
    state = collections;
  }

  Future<void> addCollection(Collection collection) async {
    state = [...state, collection];
    await HiveService.saveCollections(state);
  }

  Future<void> updateCollection(Collection collection) async {
    state = state.map((c) => c.id == collection.id ? collection : c).toList();
    await HiveService.saveCollections(state);
  }

  Future<void> deleteCollection(String id) async {
    state = state.where((c) => c.id != id).toList();
    await HiveService.saveCollections(state);
  }

  Future<void> saveRequestToCollection({
    required String collectionId,
    required String? folderId,
    required ApiRequest request,
    required String name,
  }) async {
    final saved = SavedRequest(name: name, request: request.copyWith(name: name));
    state = state.map((c) {
      if (c.id != collectionId) return c;
      if (folderId == null) {
        return c.copyWith(requests: [...c.requests, saved]);
      }
      return c.copyWith(
        folders: c.folders.map((f) {
          if (f.id != folderId) return f;
          return f.copyWith(requests: [...f.requests, saved]);
        }).toList(),
      );
    }).toList();
    await HiveService.saveCollections(state);
  }

  Future<void> deleteRequest({
    required String collectionId,
    required String requestId,
    String? folderId,
  }) async {
    state = state.map((c) {
      if (c.id != collectionId) return c;
      if (folderId == null) {
        return c.copyWith(
          requests: c.requests.where((r) => r.id != requestId).toList(),
        );
      }
      return c.copyWith(
        folders: c.folders.map((f) {
          if (f.id != folderId) return f;
          return f.copyWith(
            requests: f.requests.where((r) => r.id != requestId).toList(),
          );
        }).toList(),
      );
    }).toList();
    await HiveService.saveCollections(state);
  }

  Future<void> renameRequest({
    required String collectionId,
    required String requestId,
    required String newName,
    String? folderId,
  }) async {
    state = state.map((c) {
      if (c.id != collectionId) return c;
      if (folderId == null) {
        return c.copyWith(
          requests: c.requests
              .map((r) =>
                  r.id == requestId ? r.copyWith(name: newName) : r)
              .toList(),
        );
      }
      return c.copyWith(
        folders: c.folders.map((f) {
          if (f.id != folderId) return f;
          return f.copyWith(
            requests: f.requests
                .map((r) =>
                    r.id == requestId ? r.copyWith(name: newName) : r)
                .toList(),
          );
        }).toList(),
      );
    }).toList();
    await HiveService.saveCollections(state);
  }

  Future<void> addFolder({
    required String collectionId,
    required CollectionFolder folder,
  }) async {
    state = state.map((c) {
      if (c.id != collectionId) return c;
      return c.copyWith(folders: [...c.folders, folder]);
    }).toList();
    await HiveService.saveCollections(state);
  }
}

final collectionProvider =
    StateNotifierProvider<CollectionNotifier, List<Collection>>((ref) {
  return CollectionNotifier();
});

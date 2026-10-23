abstract class StorageAdapter {
  Future<String?> load();
  Future<void> save(String data);
}

class InMemoryStorageAdapter implements StorageAdapter {
  String? _data;

  @override
  Future<String?> load() async => _data;

  @override
  Future<void> save(String data) async {
    _data = data;
  }
}

StorageAdapter getStorageAdapter() => InMemoryStorageAdapter();

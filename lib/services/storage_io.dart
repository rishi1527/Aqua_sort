import 'dart:io';

import 'storage_stub.dart';
export 'storage_stub.dart';

class IoStorageAdapter implements StorageAdapter {
  File? _cachedFile;

  File _getSaveFile() {
    if (_cachedFile != null) return _cachedFile!;

    // 1. Android sandboxed application storage
    try {
      if (Platform.isAndroid) {
        final baseDir = Directory.systemTemp.parent;
        final filesDir = Directory(
          '${baseDir.path}${Platform.pathSeparator}files',
        );
        if (!filesDir.existsSync()) {
          filesDir.createSync(recursive: true);
        }
        _cachedFile = File(
          '${filesDir.path}${Platform.pathSeparator}aquasort_savedata.json',
        );
        return _cachedFile!;
      }
    } catch (_) {
      // Fallback to desktop / unit-test current directory
    }

    // 2. Desktop & unit tests: current working directory
    try {
      final appSupportDir = Directory.current;
      _cachedFile = File(
        '${appSupportDir.path}${Platform.pathSeparator}aquasort_savedata.json',
      );
    } catch (_) {
      _cachedFile = File('aquasort_savedata.json');
    }
    return _cachedFile!;
  }

  @override
  Future<String?> load() async {
    try {
      final file = _getSaveFile();
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (_) {
      // Fallback silently if disk access is restricted
    }
    return null;
  }

  @override
  Future<void> save(String data) async {
    try {
      final file = _getSaveFile();
      await file.writeAsString(data, flush: true);
    } catch (_) {
      // Fallback silently
    }
  }
}

StorageAdapter getStorageAdapter() => IoStorageAdapter();

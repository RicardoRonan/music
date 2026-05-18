import 'dart:js_interop';
import 'dart:typed_data';

import 'package:idb_shim/idb_browser.dart';
import 'package:web/web.dart' as web;

export 'web_audio_storage_stub.dart'
    show isWebAudioUri, kWebAudioScheme, webAudioStorageId;

import 'web_audio_storage_stub.dart' show webAudioStorageId;

const _dbName = 'music_web_audio_v1';
const _storeName = 'tracks';

class WebAudioStorage {
  WebAudioStorage._();
  static final WebAudioStorage instance = WebAudioStorage._();

  Database? _db;
  final Map<String, String> _blobUrlCache = {};

  Future<void> init() async {
    if (_db != null) return;
    final factory = getIdbFactory();
    if (factory == null) return;
    _db = await factory.open(
      _dbName,
      version: 1,
      onUpgradeNeeded: (event) {
        final db = event.database;
        if (!db.objectStoreNames.contains(_storeName)) {
          db.createObjectStore(_storeName);
        }
      },
    );
  }

  Future<void> put({
    required String id,
    required Uint8List bytes,
    required String fileName,
    required String extension,
  }) async {
    await init();
    final db = _db;
    if (db == null) return;
    final txn = db.transaction(_storeName, idbModeReadWrite);
    await txn.objectStore(_storeName).put({
      'bytes': bytes,
      'fileName': fileName,
      'extension': extension,
    }, id);
    await txn.completed;
    _revoke(id);
  }

  Future<String?> getOrCreateBlobUrl(String id) async {
    final cached = _blobUrlCache[id];
    if (cached != null) return cached;

    await init();
    final db = _db;
    if (db == null) return null;

    final txn = db.transaction(_storeName, idbModeReadOnly);
    final record = await txn.objectStore(_storeName).getObject(id);
    await txn.completed;
    if (record is! Map) return null;

    final bytes = record['bytes'];
    if (bytes is! Uint8List || bytes.isEmpty) return null;
    final ext = (record['extension'] as String?) ?? '';
    final mime = _mimeForExtension(ext);
    final url = _createBlobUrl(bytes, mime);
    _blobUrlCache[id] = url;
    return url;
  }

  Future<void> warmUrls(Iterable<String> storedUris) async {
    for (final uri in storedUris) {
      final id = webAudioStorageId(uri);
      if (id != null) {
        await getOrCreateBlobUrl(id);
      }
    }
  }

  Future<void> delete(String id) async {
    await init();
    final db = _db;
    if (db == null) return;
    final txn = db.transaction(_storeName, idbModeReadWrite);
    await txn.objectStore(_storeName).delete(id);
    await txn.completed;
    _revoke(id);
  }

  Future<void> clear() async {
    await init();
    final db = _db;
    if (db == null) return;
    for (final id in _blobUrlCache.keys.toList()) {
      _revoke(id);
    }
    final txn = db.transaction(_storeName, idbModeReadWrite);
    await txn.objectStore(_storeName).clear();
    await txn.completed;
  }

  void _revoke(String id) {
    final url = _blobUrlCache.remove(id);
    if (url != null) {
      web.URL.revokeObjectURL(url);
    }
  }

  String _createBlobUrl(Uint8List bytes, String mime) {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mime),
    );
    return web.URL.createObjectURL(blob);
  }

  String _mimeForExtension(String extension) {
    switch (extension.toLowerCase()) {
      case '.mp3':
        return 'audio/mpeg';
      case '.m4a':
      case '.aac':
        return 'audio/mp4';
      case '.wav':
        return 'audio/wav';
      case '.flac':
        return 'audio/flac';
      case '.ogg':
        return 'audio/ogg';
      case '.opus':
        return 'audio/opus';
      case '.wma':
        return 'audio/x-ms-wma';
      case '.aiff':
      case '.aif':
        return 'audio/aiff';
      default:
        return 'audio/mpeg';
    }
  }
}

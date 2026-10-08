import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Persists the user's wishlist (a set of post IDs) as JSON in the app
/// documents directory.
class WishlistRepository {
  static const _fileName = 'antinna_wishlist.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Loads the list of wishlisted post IDs from disk.
  ///
  /// Returns an empty list if no file is found or it cannot be parsed.
  Future<List<String>> _load() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return [];
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.cast<String>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<String> ids) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(ids));
  }

  /// Adds [postId] to the wishlist if it is not already present.
  ///
  /// Returns the updated list.
  Future<List<String>> add(String postId) async {
    final ids = await _load();
    if (!ids.contains(postId)) {
      ids.add(postId);
      await _save(ids);
    }
    return List<String>.unmodifiable(ids);
  }

  /// Removes [postId] from the wishlist.
  ///
  /// Returns the updated list.
  Future<List<String>> remove(String postId) async {
    final ids = await _load();
    ids.remove(postId);
    await _save(ids);
    return List<String>.unmodifiable(ids);
  }

  /// Returns `true` if [postId] is in the wishlist.
  Future<bool> contains(String postId) async {
    final ids = await _load();
    return ids.contains(postId);
  }
}

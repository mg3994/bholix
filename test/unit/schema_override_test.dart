import 'package:flutter_test/flutter_test.dart';
import 'package:bholix/core/schema/schema_override.dart';

void main() {
  group('SchemaOverride.resolveId', () {
    test('resolves full URL when id starts with http:// or https://', () {
      final res = SchemaOverride.resolveId('', 'https://example.com/post/1');
      expect(res.url, 'https://example.com/post/1');
      expect(res.blogId, isNull);
      expect(res.postId, isNull);
    });

    test('resolves blogId and postId when idValue contains exactly two non-empty segments', () {
      final res = SchemaOverride.resolveId('', '1774904866501098696/5522904867501094455');
      expect(res.blogId, '1774904866501098696');
      expect(res.postId, '5522904867501094455');
      expect(res.url, isNull);
    });

    test('inherits blogId from base when base has slash and idValue is postId', () {
      final res = SchemaOverride.resolveId('1774904866501098696/post1', 'post2');
      expect(res.blogId, '1774904866501098696');
      expect(res.postId, 'post2');
      expect(res.url, isNull);
    });

    test('falls back to URL when other conditions are not met', () {
      final res = SchemaOverride.resolveId('', 'fragment-id');
      expect(res.url, 'fragment-id');
    });
  });

  group('SchemaOverride.deepMerge', () {
    test('deeply merges nested maps and source overwrites scalars', () {
      final target = <String, dynamic>{
        'a': 1,
        'b': {'c': 2, 'd': 3},
        'e': 'target',
      };
      final source = <String, dynamic>{
        'b': {'d': 4, 'f': 5},
        'e': 'source',
        'g': 10,
      };

      final merged = SchemaOverride.deepMerge(target, source);

      expect(merged['a'], 1);
      expect(merged['b'], {'c': 2, 'd': 4, 'f': 5});
      expect(merged['e'], 'source');
      expect(merged['g'], 10);
    });
  });
}

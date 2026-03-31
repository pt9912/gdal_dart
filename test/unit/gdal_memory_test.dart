import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:gdal_dart/src/native/gdal_memory.dart';
import 'package:test/test.dart';

void main() {
  group('readNativeString', () {
    test('returns empty string for nullptr', () {
      expect(readNativeString(nullptr), '');
    });

    test('reads an ASCII string', () {
      final ptr = 'hello'.toNativeUtf8(allocator: calloc);
      try {
        expect(readNativeString(ptr), 'hello');
      } finally {
        calloc.free(ptr);
      }
    });

    test('reads a UTF-8 string with multi-byte characters', () {
      final ptr = 'Ströme – Ñ'.toNativeUtf8(allocator: calloc);
      try {
        expect(readNativeString(ptr), 'Ströme – Ñ');
      } finally {
        calloc.free(ptr);
      }
    });

    test('reads an empty string', () {
      final ptr = ''.toNativeUtf8(allocator: calloc);
      try {
        expect(readNativeString(ptr), '');
      } finally {
        calloc.free(ptr);
      }
    });
  });

  group('withNativeString', () {
    test('passes a native pointer to the callback', () {
      final result = withNativeString('test', (ptr) {
        return ptr.toDartString();
      });
      expect(result, 'test');
    });

    test('returns the callback result', () {
      final length = withNativeString('four', (ptr) {
        return ptr.toDartString().length;
      });
      expect(length, 4);
    });

    test('frees memory even when callback throws', () {
      // If this leaks, valgrind / ASAN would catch it, but at minimum
      // we verify the exception propagates cleanly.
      expect(
        () => withNativeString('boom', (_) => throw StateError('fail')),
        throwsStateError,
      );
    });
  });
}

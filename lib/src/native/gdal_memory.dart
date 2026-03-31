import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// Reads a null-terminated native UTF-8 string without taking ownership.
///
/// Returns an empty string if [ptr] is [nullptr].
String readNativeString(Pointer<Utf8> ptr) {
  if (ptr == nullptr) return '';
  return ptr.toDartString();
}

/// Executes [body] with a temporary native UTF-8 string allocated via [calloc].
///
/// The allocated memory is freed after [body] returns or throws.
T withNativeString<T>(String value, T Function(Pointer<Utf8> ptr) body) {
  final ptr = value.toNativeUtf8(allocator: calloc);
  try {
    return body(ptr);
  } finally {
    calloc.free(ptr);
  }
}

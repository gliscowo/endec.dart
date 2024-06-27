import 'dart:collection';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:endec/endec.dart';
import 'package:meta/meta.dart';

enum EdmElementType {
  i8,
  u8,
  i16,
  u16,
  i32,
  u32,
  i64,
  u64,
  f32,
  f64,

  boolean,
  string,
  bytes,
  optional,

  sequence,
  map
}

final class EdmElement<T> {
  final T value;
  final EdmElementType type;

  EdmElement._(this.value, this.type);

  @factory
  static EdmElement<int> i8(int value) => EdmElement._(value, EdmElementType.i8);
  @factory
  static EdmElement<int> u8(int value) => EdmElement._(value, EdmElementType.u8);

  @factory
  static EdmElement<int> i16(int value) => EdmElement._(value, EdmElementType.i16);
  @factory
  static EdmElement<int> u16(int value) => EdmElement._(value, EdmElementType.u16);

  @factory
  static EdmElement<int> i32(int value) => EdmElement._(value, EdmElementType.i32);
  @factory
  static EdmElement<int> u32(int value) => EdmElement._(value, EdmElementType.u32);

  @factory
  static EdmElement<int> i64(int value) => EdmElement._(value, EdmElementType.i64);
  @factory
  static EdmElement<int> u64(int value) => EdmElement._(value, EdmElementType.u64);

  @factory
  static EdmElement<double> f32(double value) => EdmElement._(value, EdmElementType.f32);
  @factory
  static EdmElement<double> f64(double value) => EdmElement._(value, EdmElementType.f64);

  @factory
  static EdmElement<bool> boolean(bool value) => EdmElement._(value, EdmElementType.boolean);
  @factory
  static EdmElement<String> string(String value) => EdmElement._(value, EdmElementType.string);
  @factory
  static EdmElement<Uint8List> bytes(Uint8List value) => EdmElement._(value, EdmElementType.bytes);
  @factory
  static EdmElement<EdmElement<T>?> optional<T>(EdmElement<T>? value) => EdmOptional._(value);

  @factory
  static EdmElement<List<EdmElement>> sequence(List<EdmElement> value) => EdmSequence._(List.unmodifiable(value));
  @factory
  static EdmElement<List<EdmElement>> wrapSequence(List<EdmElement> value) => EdmSequence._(value);

  @factory
  static EdmElement<Map<String, EdmElement>> map(Map<String, EdmElement> value) => EdmMap._(Map.unmodifiable(value));
  @factory
  static EdmElement<Map<String, EdmElement>> wrapMap(Map<String, EdmElement> value) => EdmMap._(value);

  V cast<V>() => this.value as V;

  Object? unwrap() => switch (type) {
        EdmElementType.sequence => (value as List<EdmElement>).map((e) => e.unwrap()).toList(),
        EdmElementType.map => (value as Map<String, EdmElement>).map((key, value) => MapEntry(key, value.unwrap())),
        EdmElementType.optional => (value as EdmElement?)?.unwrap(),
        _ => value
      };

  @override
  bool operator ==(Object other) => other is EdmElement && type == other.type && value == other.value;
  @override
  int get hashCode => Object.hash(type, value);

  @override
  String toString() {
    final formatter = BlockWriter();
    _format(formatter);
    return formatter.buildResult();
  }

  void _format(BlockWriter formatter) => formatter.write("${type.name}($value)");
}

final class EdmMap extends EdmElement<Map<String, EdmElement>> {
  EdmMap._(Map<String, EdmElement> value) : super._(value, EdmElementType.map);

  @override
  bool operator ==(Object other) => other is EdmElement && const MapEquality().equals(value, other.value);
  @override
  int get hashCode => Object.hash(type, const MapEquality().hash(value));

  @override
  void _format(BlockWriter formatter) {
    formatter.startBlock('map({', '})');

    for (final (idx, MapEntry(:key, :value)) in value.entries.indexed) {
      formatter.write("$key: ");
      value._format(formatter);

      if (idx < this.value.length - 1) formatter.writeln(",");
    }

    formatter.endBlock();
  }
}

final class EdmSequence extends EdmElement<List<EdmElement>> {
  EdmSequence._(List<EdmElement> value) : super._(value, EdmElementType.sequence);

  @override
  bool operator ==(Object other) => other is EdmElement && const ListEquality().equals(value, other.value);
  @override
  int get hashCode => Object.hash(type, const ListEquality().hash(value));

  @override
  void _format(BlockWriter formatter) {
    formatter.startBlock('sequence([', '])');

    for (final (idx, value) in value.indexed) {
      value._format(formatter);
      if (idx < this.value.length - 1) formatter.writeln(",");
    }

    formatter.endBlock();
  }
}

final class EdmOptional<T> extends EdmElement<EdmElement<T>?> {
  EdmOptional._(EdmElement<T>? value) : super._(value, EdmElementType.optional);

  @override
  void _format(BlockWriter formatter) {
    formatter.write("optional(");
    if (value != null) {
      value!._format(formatter);
    } else {
      formatter.write("null");
    }
    formatter.write(")");
  }
}

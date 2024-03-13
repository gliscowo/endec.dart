import 'dart:typed_data';

import 'package:endec/endec.dart';

Object toJson<T, S extends T>(Endec<T> endec, S value) {
  final serializer = JsonSerializer();
  endec.encode(serializer, value);
  return serializer.result;
}

class JsonSerializer extends RecursiveSerializer<Object?> implements Serializer {
  @override
  final bool selfDescribing = true;

  JsonSerializer() : super(null);

  @override
  void i8(int value) => consume(value);
  @override
  void u8(int value) => consume(value);

  @override
  void i16(int value) => consume(value);
  @override
  void u16(int value) => consume(value);

  @override
  void i32(int value) => consume(value);
  @override
  void u32(int value) => consume(value);

  @override
  void i64(int value) => consume(value);
  @override
  void u64(int value) => consume(value);

  @override
  void f32(double value) => consume(value);
  @override
  void f64(double value) => consume(value);

  @override
  void boolean(bool value) => consume(value);
  @override
  void string(String value) => consume(value);
  @override
  void bytes(Uint8List bytes) => consume(bytes);
  @override
  void optional<E>(Endec<E> endec, E? value) {
    if (value != null) {
      endec.encode(this, value);
    } else if (!isWritingOptionalStructField) {
      consume(null);
    }
  }

  @override
  SequenceSerializer<E> sequence<E>(Endec<E> elementEndec, int length) => _JsonSequenceSerializer(this, elementEndec);
  @override
  MapSerializer<V> map<V>(Endec<V> valueEndec, int length) => _JsonMapSerializer.map(this, valueEndec);
  @override
  StructSerializer struct() => _JsonMapSerializer.struct(this);

  @override
  Object get result => super.result ?? const <String, dynamic>{};
}

class _JsonMapSerializer<V> implements MapSerializer<V>, StructSerializer {
  final JsonSerializer _context;
  final Endec<V>? _valueEndec;
  final Map<String, Object?> _result = {};

  _JsonMapSerializer.map(this._context, Endec<V> valueEndec) : _valueEndec = valueEndec;
  _JsonMapSerializer.struct(this._context) : _valueEndec = null;

  @override
  void entry(String key, V value) => _context.frame((holder) {
        _valueEndec!.encode(_context, value);
        _result[key] = holder.require("map value");
      });

  @override
  void field<F, _V extends F>(String key, Endec<F> endec, _V value, {bool optional = false}) => _context.frame(
        (holder) {
          endec.encode(_context, value);

          if (optional && !holder.wasEncoded) return;
          _result[key] = holder.require("struct field");
        },
        isOptionalStructField: optional,
      );

  @override
  void end() => _context.consume(_result);
}

class _JsonSequenceSerializer<V> implements SequenceSerializer<V> {
  final JsonSerializer _context;
  final Endec<V> _elementEndec;
  final List<Object?> _result = [];

  _JsonSequenceSerializer(this._context, this._elementEndec);

  @override
  void element(V value) => _context.frame((holder) {
        _elementEndec.encode(_context, value);
        _result.add(holder.require("sequence element"));
      });

  @override
  void end() => _context.consume(_result);
}

class JsonEncodeError extends Error {
  final String message;
  JsonEncodeError(this.message);

  @override
  String toString() => "JSON encoding failed: $message";
}

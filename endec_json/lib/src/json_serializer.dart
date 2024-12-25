import 'dart:typed_data';

import 'package:endec/endec.dart';

Object toJson<T, S extends T>(Endec<T> endec, S value, {SerializationContext? ctx}) {
  ctx ??= SerializationContext(attributes: [humanReadable]);

  final serializer = JsonSerializer();
  endec.encode(ctx, serializer, value);
  return serializer.result;
}

class JsonSerializer extends RecursiveSerializer<Object?> implements SelfDescribingSerializer {
  JsonSerializer() : super(null);

  @override
  void i8(SerializationContext ctx, int value) => consume(value);
  @override
  void u8(SerializationContext ctx, int value) => consume(value);

  @override
  void i16(SerializationContext ctx, int value) => consume(value);
  @override
  void u16(SerializationContext ctx, int value) => consume(value);

  @override
  void i32(SerializationContext ctx, int value) => consume(value);
  @override
  void u32(SerializationContext ctx, int value) => consume(value);

  @override
  void i64(SerializationContext ctx, int value) => consume(value);
  @override
  void u64(SerializationContext ctx, int value) => consume(value);

  @override
  void f32(SerializationContext ctx, double value) => consume(value);
  @override
  void f64(SerializationContext ctx, double value) => consume(value);

  @override
  void boolean(SerializationContext ctx, bool value) => consume(value);
  @override
  void string(SerializationContext ctx, String value) => consume(value);
  @override
  void bytes(SerializationContext ctx, Uint8List bytes) => consume(bytes);
  @override
  void optional<E>(SerializationContext ctx, Endec<E> endec, E? value) {
    if (value != null) {
      endec.encode(ctx, this, value);
    } else {
      consume(null);
    }
  }

  @override
  SequenceSerializer<E> sequence<E>(SerializationContext ctx, Endec<E> elementEndec, int length) =>
      _JsonSequenceSerializer(this, ctx, elementEndec);
  @override
  MapSerializer<V> map<V>(SerializationContext ctx, Endec<V> valueEndec, int length) =>
      _JsonMapSerializer.map(this, ctx, valueEndec);
  @override
  StructSerializer struct() => _JsonMapSerializer.struct(this);

  @override
  Object get result => super.result ?? const <String, dynamic>{};
}

class _JsonMapSerializer<V> implements MapSerializer<V>, StructSerializer {
  final JsonSerializer _serializer;
  final SerializationContext? _ctx;
  final Endec<V>? _valueEndec;
  final Map<String, Object?> _result = {};

  _JsonMapSerializer.map(this._serializer, this._ctx, Endec<V> valueEndec) : _valueEndec = valueEndec;
  _JsonMapSerializer.struct(this._serializer)
      : _ctx = null,
        _valueEndec = null;

  @override
  void entry(String key, V value) => _serializer.frame((holder) {
        _valueEndec!.encode(_ctx!.pushField(key), _serializer, value);
        _result[key] = holder.require('map value');
      });

  @override
  void field<F, _V extends F>(String key, SerializationContext ctx, Endec<F> endec, _V value, {bool mayOmit = false}) =>
      _serializer.frame((holder) {
        endec.encode(ctx.pushField(key), _serializer, value);

        final encoded = holder.require('struct field');
        if (mayOmit && encoded == null) return;

        _result[key] = encoded;
      });

  @override
  void end() => _serializer.consume(_result);
}

class _JsonSequenceSerializer<V> implements SequenceSerializer<V> {
  final JsonSerializer _deserializer;
  final SerializationContext _ctx;
  final Endec<V> _elementEndec;
  final List<Object?> _result = [];

  _JsonSequenceSerializer(this._deserializer, this._ctx, this._elementEndec);

  @override
  void element(V value) => _deserializer.frame((holder) {
        _elementEndec.encode(_ctx.pushIndex(_result.length), _deserializer, value);
        _result.add(holder.require('sequence element'));
      });

  @override
  void end() => _deserializer.consume(_result);
}

class JsonEncodeError extends Error {
  final String message;
  JsonEncodeError(this.message);

  @override
  String toString() => 'JSON encoding failed: $message';
}

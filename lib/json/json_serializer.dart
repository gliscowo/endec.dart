import 'dart:collection';
import 'dart:typed_data';

import 'package:codec/codec.dart';
import 'package:codec/serializer.dart';

Object toJson<T>(Codec<T> codec, T value) {
  final serializer = JsonSerializer();
  codec.encode(serializer, value);
  return serializer.result;
}

typedef JsonSink = void Function(Object? jsonValue);

class JsonSerializer implements Serializer<Object> {
  @override
  final bool selfDescribing = true;

  final Queue<JsonSink> _sinks = Queue();
  Object? _result;

  JsonSerializer() {
    _sinks.add((jsonValue) => _result = jsonValue);
  }

  void _sink(Object? jsonValue) => _sinks.last(jsonValue);

  @override
  void boolean(bool value) => _sink(value);
  @override
  void optional<E>(Codec<E> codec, E? value) {
    if (value != null) {
      codec.encode(this, value);
    } else {
      _sink(null);
    }
  }

  @override
  void i8(int value) => _sink(value);
  @override
  void u8(int value) => _sink(value);

  @override
  void i16(int value) => _sink(value);
  @override
  void u16(int value) => _sink(value);

  @override
  void i32(int value) => _sink(value);
  @override
  void u32(int value) => _sink(value);

  @override
  void i64(int value) => _sink(value);
  @override
  void u64(int value) => _sink(value);

  @override
  void f32(double value) => _sink(value);
  @override
  void f64(double value) => _sink(value);

  @override
  void string(String value) => _sink(value);
  @override
  void bytes(Uint8List bytes) => _sink(bytes);

  @override
  SequenceSerializer<E> sequence<E>(Codec<E> elementCodec, int length) => _JsonSequenceSerializer(this, elementCodec);
  @override
  MapSerializer<V> map<V>(Codec<V> valueCodec, int length) => _JsonMapSerializer.map(this, valueCodec);
  @override
  StructSerializer struct() => _JsonMapSerializer.struct(this);

  @override
  Object get result => _result ?? const <String, dynamic>{};

  void _pushSink(JsonSink sink) => _sinks.addLast(sink);
  void _popSink() => _sinks.removeLast();
}

class _JsonMapSerializer<V> implements MapSerializer<V>, StructSerializer {
  final JsonSerializer _context;
  final Codec<V>? _valueCodec;
  final Map<String, Object?> _result = {};

  _JsonMapSerializer.map(this._context, Codec<V> valueCodec) : _valueCodec = valueCodec;
  _JsonMapSerializer.struct(this._context) : _valueCodec = null;

  @override
  void entry(String key, V value) => _kvPair(key, _valueCodec!, value);
  @override
  void field<F, _V extends F>(String key, Codec<F> codec, _V value) => _kvPair(key, codec, value);

  void _kvPair<T>(String key, Codec<T> codec, T value) {
    var serialized = false;
    Object? encodedValue;

    _context._pushSink((jsonValue) {
      serialized = true;
      encodedValue = jsonValue;
    });
    codec.encode(_context, value);
    _context._popSink();

    if (!serialized) throw JsonEncodeError("No field was serialized");
    _result[key] = encodedValue;
  }

  @override
  void end() => _context._sink(_result);
}

class _JsonSequenceSerializer<V> implements SequenceSerializer<V> {
  final JsonSerializer _context;
  final Codec<V> _elementCodec;
  final List<Object?> _result = [];

  _JsonSequenceSerializer(this._context, this._elementCodec);

  @override
  void element(V value) {
    var serialized = false;
    Object? encodedValue;

    _context._pushSink((jsonValue) {
      serialized = true;
      encodedValue = jsonValue;
    });
    _elementCodec.encode(_context, value);
    _context._popSink();

    if (!serialized) throw JsonEncodeError("No value was serialized");
    _result.add(encodedValue);
  }

  @override
  void end() => _context._sink(_result);
}

class JsonEncodeError extends Error {
  final String message;
  JsonEncodeError(this.message);

  @override
  String toString() => "JSON encoding failed: $message";
}

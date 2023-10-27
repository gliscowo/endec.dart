import 'dart:collection';
import 'dart:typed_data';

import '../endec.dart';
import '../serializer.dart';

Object toJson<T>(Endec<T> endec, T value) {
  final serializer = JsonSerializer();
  endec.encode(serializer, value);
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
  void optional<E>(Endec<E> endec, E? value) {
    if (value != null) {
      endec.encode(this, value);
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
  SequenceSerializer<E> sequence<E>(Endec<E> elementEndec, int length) => _JsonSequenceSerializer(this, elementEndec);
  @override
  MapSerializer<V> map<V>(Endec<V> valueEndec, int length) => _JsonMapSerializer.map(this, valueEndec);
  @override
  StructSerializer struct() => _JsonMapSerializer.struct(this);

  @override
  Object get result => _result ?? const <String, dynamic>{};

  void _pushSink(JsonSink sink) => _sinks.addLast(sink);
  void _popSink() => _sinks.removeLast();
}

class _JsonMapSerializer<V> implements MapSerializer<V>, StructSerializer {
  final JsonSerializer _context;
  final Endec<V>? _valueEndec;
  final Map<String, Object?> _result = {};

  _JsonMapSerializer.map(this._context, Endec<V> valueEndec) : _valueEndec = valueEndec;
  _JsonMapSerializer.struct(this._context) : _valueEndec = null;

  @override
  void entry(String key, V value) => _kvPair(key, _valueEndec!, value);
  @override
  void field<F, _V extends F>(String key, Endec<F> endec, _V value) => _kvPair(key, endec, value);

  void _kvPair<T>(String key, Endec<T> endec, T value) {
    var serialized = false;
    Object? encodedValue;

    _context._pushSink((jsonValue) {
      serialized = true;
      encodedValue = jsonValue;
    });
    endec.encode(_context, value);
    _context._popSink();

    if (!serialized) throw JsonEncodeError("No field was serialized");
    _result[key] = encodedValue;
  }

  @override
  void end() => _context._sink(_result);
}

class _JsonSequenceSerializer<V> implements SequenceSerializer<V> {
  final JsonSerializer _context;
  final Endec<V> _elementEndec;
  final List<Object?> _result = [];

  _JsonSequenceSerializer(this._context, this._elementEndec);

  @override
  void element(V value) {
    var serialized = false;
    Object? encodedValue;

    _context._pushSink((jsonValue) {
      serialized = true;
      encodedValue = jsonValue;
    });
    _elementEndec.encode(_context, value);
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

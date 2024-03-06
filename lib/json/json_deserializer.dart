import 'dart:collection';
import 'dart:typed_data';

import 'package:endec/json/json_endec.dart';
import 'package:endec/serializer.dart';

import '../deserializer.dart';
import '../endec.dart';

T fromJson<T>(Endec<T> endec, Object json) {
  final deserializer = JsonDeserializer(json);
  return endec.decode(deserializer);
}

typedef JsonSource = Object? Function();

class JsonDeserializer implements SelfDescribingDeserializer<Object?> {
  final Queue<JsonSource> _sources = Queue();
  final Object? _serialized;

  JsonDeserializer(this._serialized) {
    _sources.add(() => _serialized);
  }

  T _getObject<T>() => _sources.last() as T;

  @override
  void any<S>(Serializer<S> visitor) => _decodeElement(visitor, _getObject());
  void _decodeElement(Serializer visitor, Object? element) {
    switch (element) {
      case null:
        visitor.optional(jsonEndec, element);
      case int value:
        visitor.i64(value);
      case double value:
        visitor.f64(value);
      case bool value:
        visitor.boolean(value);
      case String value:
        visitor.string(value);
        visitor.string(value);
      case List<dynamic> value:
        final state = visitor.sequence(Endec<Object?>.of(_decodeElement, (deserializer) => null), value.length);
        for (final element in value) {
          state.element(element);
        }
        state.end();
      case Map<String, dynamic> value:
        final state = visitor.map(Endec<Object?>.of(_decodeElement, (deserializer) => null), value.length);
        for (final MapEntry(:key, :value) in value.entries) {
          state.entry(key, value);
        }
        state.end();
      case _:
        throw ArgumentError.value(element, "element", "Non-standard, unrecognized JSON element cannot be decoded");
    }
  }

  @override
  bool boolean() => _getObject();
  @override
  E? optional<E>(Endec<E> endec) => _getObject() != null ? endec.decode(this) : null;

  @override
  int i8() => _getObject();
  @override
  int u8() => _getObject();

  @override
  int i16() => _getObject();
  @override
  int u16() => _getObject();

  @override
  int i32() => _getObject();
  @override
  int u32() => _getObject();

  @override
  int i64() => _getObject();
  @override
  int u64() => _getObject();

  @override
  double f32() => _getObject();
  @override
  double f64() => _getObject();

  @override
  String string() => _getObject();
  @override
  Uint8List bytes() => Uint8List.fromList(_getObject<List<dynamic>>().cast<int>());

  @override
  SequenceDeserializer<E> sequence<E>(Endec<E> elementEndec) =>
      _JsonSequenceDeserializer(this, elementEndec, _getObject<List<dynamic>>());
  @override
  MapDeserializer<V> map<V>(Endec<V> valueEndec) =>
      _JsonMapDeserializer.map(this, valueEndec, _getObject<Map<String, dynamic>>());
  @override
  StructDeserializer struct() => _JsonMapDeserializer.struct(this, _getObject<Map<String, dynamic>>());

  void _pushSource(JsonSource source) => _sources.addLast(source);
  void _popSource() => _sources.removeLast();
}

class _JsonMapDeserializer<V> implements MapDeserializer<V>, StructDeserializer {
  final JsonDeserializer _context;
  final Endec<V>? _valueEndec;

  final Map<String, dynamic> _map;
  final Iterator<MapEntry<String, dynamic>> _entries;

  _JsonMapDeserializer.map(this._context, Endec<V> valueEndec, this._map)
      : _valueEndec = valueEndec,
        _entries = _map.entries.iterator;

  _JsonMapDeserializer.struct(this._context, this._map)
      : _valueEndec = null,
        _entries = _map.entries.iterator;

  @override
  bool moveNext() => _entries.moveNext();

  @override
  (String, V) entry() {
    _context._pushSource(() => _entries.current.value);
    final decoded = _valueEndec!.decode(_context);
    _context._popSource();

    return (_entries.current.key, decoded);
  }

  @override
  F field<F>(String name, Endec<F> endec, {F? defaultValue}) {
    if (!_map.containsKey(name)) {
      if (defaultValue == null) {
        throw JsonDecodeError("Field $name was missing from serialized data, but no default ");
      }

      return defaultValue;
    }

    _context._pushSource(() => _map[name]!);
    final decoded = endec.decode(_context);
    _context._popSource();

    return decoded;
  }
}

class _JsonSequenceDeserializer<V> implements SequenceDeserializer<V> {
  final JsonDeserializer _context;
  final Endec<V> _elementEndec;
  final Iterator<dynamic> _entries;

  _JsonSequenceDeserializer(this._context, this._elementEndec, List<dynamic> list) : _entries = list.iterator;

  @override
  bool moveNext() => _entries.moveNext();

  @override
  V element() {
    _context._pushSource(() => _entries.current);
    final decoded = _elementEndec.decode(_context);
    _context._popSource();

    return decoded;
  }
}

class JsonDecodeError extends Error {
  final String message;
  JsonDecodeError(this.message);

  @override
  String toString() => "JSON decoding failed: $message";
}

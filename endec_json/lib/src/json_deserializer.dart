import 'dart:typed_data';

import 'package:endec/endec.dart';

import 'json_endec.dart';

T fromJson<T>(Endec<T> endec, Object json) {
  final deserializer = JsonDeserializer(json);
  return endec.decode(deserializer);
}

typedef JsonSource = Object? Function();

class JsonDeserializer extends RecursiveDeserializer<Object?> implements SelfDescribingDeserializer {
  JsonDeserializer(super._serialized);

  @override
  void any(Serializer visitor) => _decodeElement(visitor, currentValue());
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
  bool boolean() => currentValue();
  @override
  E? optional<E>(Endec<E> endec) => currentValue() != null ? endec.decode(this) : null;

  @override
  int i8() => currentValue();
  @override
  int u8() => currentValue();

  @override
  int i16() => currentValue();
  @override
  int u16() => currentValue();

  @override
  int i32() => currentValue();
  @override
  int u32() => currentValue();

  @override
  int i64() => currentValue();
  @override
  int u64() => currentValue();

  @override
  double f32() => currentValue();
  @override
  double f64() => currentValue();

  @override
  String string() => currentValue();
  @override
  Uint8List bytes() => Uint8List.fromList(currentValue<List<dynamic>>().cast<int>());

  @override
  SequenceDeserializer<E> sequence<E>(Endec<E> elementEndec) =>
      _JsonSequenceDeserializer(this, elementEndec, currentValue<List<dynamic>>());
  @override
  MapDeserializer<V> map<V>(Endec<V> valueEndec) =>
      _JsonMapDeserializer.map(this, valueEndec, currentValue<Map<String, dynamic>>());
  @override
  StructDeserializer struct() => _JsonMapDeserializer.struct(this, currentValue<Map<String, dynamic>>());
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
  (String, V) entry() => _context.frame(
        () => _entries.current.value,
        () => (_entries.current.key, _valueEndec!.decode(_context)),
        false,
      );

  @override
  F field<F>(String name, Endec<F> endec) {
    if (!_map.containsKey(name)) {
      throw JsonDecodeException("Required Field $name is missing from serialized data");
    }

    return _context.frame(
      () => _map[name]!,
      () => endec.decode(_context),
      true,
    );
  }

  @override
  F optionalField<F>(String name, Endec<F> endec, F defaultValue) {
    if (!_map.containsKey(name)) {
      return defaultValue;
    }

    return _context.frame(
      () => _map[name]!,
      () => endec.decode(_context),
      true,
    );
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
  V element() => _context.frame(
        () => _entries.current,
        () => _elementEndec.decode(_context),
        false,
      );
}

class JsonDecodeException implements Exception {
  final String message;
  JsonDecodeException(this.message);

  @override
  String toString() => "JSON decoding failed: $message";
}

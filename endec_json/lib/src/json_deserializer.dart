import 'dart:typed_data';

import 'package:endec/endec.dart';

import 'json_endec.dart';

T fromJson<T>(Endec<T> endec, Object json, {SerializationContext ctx = SerializationContext.empty}) {
  final deserializer = JsonDeserializer(json);
  return endec.decode(ctx, deserializer);
}

typedef JsonSource = Object? Function();

class JsonDeserializer extends RecursiveDeserializer<Object?> implements SelfDescribingDeserializer {
  JsonDeserializer(super._serialized);

  @override
  void any(SerializationContext ctx, Serializer visitor) => _decodeElement(ctx, visitor, currentValue());
  void _decodeElement(SerializationContext ctx, Serializer visitor, Object? element) {
    switch (element) {
      case null:
        visitor.optional(ctx, jsonEndec, element);
      case int value:
        visitor.i64(ctx, value);
      case double value:
        visitor.f64(ctx, value);
      case bool value:
        visitor.boolean(ctx, value);
      case String value:
        visitor.string(ctx, value);
        visitor.string(ctx, value);
      case List<dynamic> value:
        final state =
            visitor.sequence(ctx, Endec<Object?>.of(_decodeElement, (ctx, deserializer) => null), value.length);
        for (final element in value) {
          state.element(element);
        }
        state.end();
      case Map<String, dynamic> value:
        final state = visitor.map(ctx, Endec<Object?>.of(_decodeElement, (ctx, deserializer) => null), value.length);
        for (final MapEntry(:key, :value) in value.entries) {
          state.entry(key, value);
        }
        state.end();
      case _:
        throw ArgumentError.value(element, "element", "Non-standard, unrecognized JSON element cannot be decoded");
    }
  }

  @override
  int i8(SerializationContext ctx) => currentValue();
  @override
  int u8(SerializationContext ctx) => currentValue();

  @override
  int i16(SerializationContext ctx) => currentValue();
  @override
  int u16(SerializationContext ctx) => currentValue();

  @override
  int i32(SerializationContext ctx) => currentValue();
  @override
  int u32(SerializationContext ctx) => currentValue();

  @override
  int i64(SerializationContext ctx) => currentValue();
  @override
  int u64(SerializationContext ctx) => currentValue();

  @override
  double f32(SerializationContext ctx) => currentValue();
  @override
  double f64(SerializationContext ctx) => currentValue();

  @override
  bool boolean(SerializationContext ctx) => currentValue();
  @override
  String string(SerializationContext ctx) => currentValue();
  @override
  Uint8List bytes(SerializationContext ctx) => Uint8List.fromList(currentValue<List<dynamic>>().cast<int>());
  @override
  E? optional<E>(SerializationContext ctx, Endec<E> endec) => currentValue() != null ? endec.decode(ctx, this) : null;

  @override
  SequenceDeserializer<E> sequence<E>(SerializationContext ctx, Endec<E> elementEndec) =>
      _JsonSequenceDeserializer(this, ctx, elementEndec, currentValue<List<dynamic>>());
  @override
  MapDeserializer<V> map<V>(SerializationContext ctx, Endec<V> valueEndec) =>
      _JsonMapDeserializer.map(this, ctx, valueEndec, currentValue<Map<String, dynamic>>());
  @override
  StructDeserializer struct() => _JsonMapDeserializer.struct(this, currentValue<Map<String, dynamic>>());
}

class _JsonMapDeserializer<V> implements MapDeserializer<V>, StructDeserializer {
  final JsonDeserializer _deserializer;
  final SerializationContext? _ctx;
  final Endec<V>? _valueEndec;

  final Map<String, dynamic> _map;
  final Iterator<MapEntry<String, dynamic>> _entries;

  _JsonMapDeserializer.map(this._deserializer, this._ctx, Endec<V> valueEndec, this._map)
      : _valueEndec = valueEndec,
        _entries = _map.entries.iterator;

  _JsonMapDeserializer.struct(this._deserializer, this._map)
      : _ctx = null,
        _valueEndec = null,
        _entries = _map.entries.iterator;

  @override
  bool moveNext() => _entries.moveNext();

  @override
  (String, V) entry() => _deserializer.frame(
        () => _entries.current.value,
        () => (_entries.current.key, _valueEndec!.decode(_ctx!, _deserializer)),
        false,
      );

  @override
  F field<F>(String name, SerializationContext ctx, Endec<F> endec) {
    if (!_map.containsKey(name)) {
      throw JsonDecodeException("Required Field $name is missing from serialized data");
    }

    return _deserializer.frame(
      () => _map[name],
      () => endec.decode(ctx, _deserializer),
      true,
    );
  }

  @override
  F optionalField<F>(String name, SerializationContext ctx, Endec<F> endec, F Function() defaultValueFactory) {
    if (!_map.containsKey(name)) {
      return defaultValueFactory();
    }

    return _deserializer.frame(
      () => _map[name]!,
      () => endec.decode(ctx, _deserializer),
      true,
    );
  }
}

class _JsonSequenceDeserializer<V> implements SequenceDeserializer<V> {
  final JsonDeserializer _deserializer;
  final SerializationContext _ctx;
  final Endec<V> _elementEndec;
  final Iterator<dynamic> _entries;

  _JsonSequenceDeserializer(this._deserializer, this._ctx, this._elementEndec, List<dynamic> list)
      : _entries = list.iterator;

  @override
  bool moveNext() => _entries.moveNext();

  @override
  V element() => _deserializer.frame(
        () => _entries.current,
        () => _elementEndec.decode(_ctx, _deserializer),
        false,
      );
}

class JsonDecodeException implements Exception {
  final String message;
  JsonDecodeException(this.message);

  @override
  String toString() => "JSON decoding failed: $message";
}

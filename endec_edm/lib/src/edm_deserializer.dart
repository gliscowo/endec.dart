import 'dart:typed_data';

import 'package:endec_edm/endec_edm.dart';

import 'package:endec/endec.dart';

T fromEdm<T>(Endec<T> endec, EdmElement serialized, {SerializationContext ctx = SerializationContext.empty}) =>
    endec.decode(ctx, EdmDeserializer(serialized));

class EdmDeserializer extends RecursiveDeserializer<EdmElement> {
  EdmDeserializer(super.serialized);

  @override
  int i8(SerializationContext ctx) => _expectType(ctx, EdmElementType.i8).cast();
  @override
  int u8(SerializationContext ctx) => _expectType(ctx, EdmElementType.u8).cast();

  @override
  int i16(SerializationContext ctx) => _expectType(ctx, EdmElementType.i16).cast();
  @override
  int u16(SerializationContext ctx) => _expectType(ctx, EdmElementType.u16).cast();

  @override
  int i32(SerializationContext ctx) => _expectType(ctx, EdmElementType.i32).cast();
  @override
  int u32(SerializationContext ctx) => _expectType(ctx, EdmElementType.u32).cast();

  @override
  int i64(SerializationContext ctx) => _expectType(ctx, EdmElementType.i64).cast();
  @override
  int u64(SerializationContext ctx) => _expectType(ctx, EdmElementType.u64).cast();

  @override
  double f32(SerializationContext ctx) => _expectType(ctx, EdmElementType.f32).cast();
  @override
  double f64(SerializationContext ctx) => _expectType(ctx, EdmElementType.f64).cast();

  @override
  bool boolean(SerializationContext ctx) => _expectType(ctx, EdmElementType.boolean).cast();
  @override
  String string(SerializationContext ctx) => _expectType(ctx, EdmElementType.string).cast();
  @override
  Uint8List bytes(SerializationContext ctx) => _expectType(ctx, EdmElementType.bytes).cast();

  @override
  E? optional<E>(SerializationContext ctx, Endec<E> endec) {
    final element = _expectType(ctx, EdmElementType.optional);
    if (element.value != null) {
      return frame(() => element.value, () => endec.decode(ctx, this));
    }

    return null;
  }

  @override
  SequenceDeserializer<E> sequence<E>(SerializationContext ctx, Endec<E> elementEndec) =>
      _EdmSequenceDeserializer(this, ctx, elementEndec, _expectType(ctx, EdmElementType.sequence).cast());

  @override
  MapDeserializer<V> map<V>(SerializationContext ctx, Endec<V> valueEndec) =>
      _EdmMapDeserializer.map(this, ctx, valueEndec, _expectType(ctx, EdmElementType.map).cast());

  @override
  StructDeserializer struct(SerializationContext ctx) =>
      _EdmMapDeserializer.struct(this, _expectType(ctx, EdmElementType.map).cast());

  EdmElement _expectType(SerializationContext ctx, EdmElementType type) {
    final value = currentValue(ctx);
    if (value.type != type) ctx.malformedInput('Expected a ${type.name}, got a ${value.type.name}');

    return value;
  }
}

class _EdmSequenceDeserializer<V> implements SequenceDeserializer<V> {
  final EdmDeserializer _deserializer;
  final SerializationContext _ctx;
  final Endec<V> _elementEndec;

  final Iterator<(int, EdmElement)> _elements;

  _EdmSequenceDeserializer(this._deserializer, this._ctx, this._elementEndec, List<EdmElement> elements)
      : _elements = elements.indexed.iterator;

  @override
  bool moveNext() => _elements.moveNext();

  @override
  V element() => _deserializer.frame(
        () => _elements.current.$2,
        () => _elementEndec.decode(_ctx.pushIndex(_elements.current.$1), _deserializer),
      );
}

class _EdmMapDeserializer<V> implements MapDeserializer<V>, StructDeserializer {
  final EdmDeserializer _deserializer;
  final SerializationContext? _ctx;
  final Endec<V>? _valueEndec;

  final Map<String, EdmElement> _map;
  final Iterator<MapEntry<String, EdmElement>>? _entries;

  _EdmMapDeserializer.map(this._deserializer, this._ctx, this._valueEndec, this._map)
      : _entries = _map.entries.iterator;

  _EdmMapDeserializer.struct(this._deserializer, this._map)
      : _ctx = null,
        _valueEndec = null,
        _entries = null;

  @override
  bool moveNext() => _entries!.moveNext();

  @override
  (String, V) entry() => _deserializer.frame(
        () => _entries!.current.value,
        () => (_entries!.current.key, _valueEndec!.decode(_ctx!.pushField(_entries.current.key), _deserializer)),
      );

  @override
  F field<F>(String name, SerializationContext ctx, Endec<F> endec, {F Function()? defaultValueFactory}) {
    final value = _map[name];
    if (value == null) {
      if (defaultValueFactory != null) return defaultValueFactory();
      ctx.malformedInput('Required Field $name is missing from serialized data');
    }

    return _deserializer.frame(
      () => value,
      () => endec.decode(ctx.pushField(name), _deserializer),
    );
  }
}

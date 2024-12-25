import 'dart:typed_data';

import 'package:endec/endec.dart';

import 'nbt_types.dart';

T fromNbt<T>(Endec<T> endec, NbtElement nbt, {SerializationContext ctx = SerializationContext.empty}) {
  final deserializer = NbtDeserializer(nbt);
  return endec.decode(ctx, deserializer);
}

final _potentialFlattenedOptional = Expando<()>();

class NbtDeserializer extends RecursiveDeserializer<NbtElement> implements SelfDescribingDeserializer {
  NbtDeserializer(super._serialized);
  @override
  void any(SerializationContext ctx, Serializer visitor) => _decodeElement(ctx, visitor, currentValue(ctx));
  void _decodeElement(SerializationContext ctx, Serializer visitor, NbtElement element) {
    switch (element) {
      case NbtByte _:
        visitor.i8(ctx, element.value);
      case NbtShort _:
        visitor.i16(ctx, element.value);
      case NbtInt _:
        visitor.i32(ctx, element.value);
      case NbtLong _:
        visitor.i64(ctx, element.value);
      case NbtFloat _:
        visitor.f32(ctx, element.value);
      case NbtDouble _:
        visitor.f64(ctx, element.value);
      case NbtString _:
        visitor.string(ctx, element.value);
      case NbtByteArray _:
        visitor.bytes(ctx, Uint8List.view(element.value.buffer));
      case NbtIntArray _:
        final list = element.value;

        var state = visitor.sequence(ctx, Endec.i32, list.length);
        for (final element in list) {
          state.element(element);
        }
        state.end();
      case NbtLongArray _:
        final list = element.value;

        var state = visitor.sequence(ctx, Endec.i64, list.length);
        for (final element in list) {
          state.element(element);
        }
        state.end();
      case NbtList _:
        final list = element.value;

        var state =
            visitor.sequence(ctx, Endec<NbtElement>.of(_decodeElement, (ctx, deserializer) => NbtByte(0)), list.length);
        for (final element in list) {
          state.element(element);
        }
        state.end();
      case NbtCompound _:
        final map = element.value;

        var state =
            visitor.map(ctx, Endec<NbtElement>.of(_decodeElement, (ctx, deserializer) => NbtByte(0)), map.length);
        for (final MapEntry(:key, :value) in map.entries) {
          state.entry(key, value);
        }
        state.end();
    }
  }

  @override
  int i8(SerializationContext ctx) => currentValue<NbtByte>(ctx).value;
  @override
  int u8(SerializationContext ctx) => currentValue<NbtByte>(ctx).value;

  @override
  int i16(SerializationContext ctx) => currentValue<NbtShort>(ctx).value;
  @override
  int u16(SerializationContext ctx) => currentValue<NbtShort>(ctx).value;

  @override
  int i32(SerializationContext ctx) => currentValue<NbtInt>(ctx).value;
  @override
  int u32(SerializationContext ctx) => currentValue<NbtInt>(ctx).value;

  @override
  int i64(SerializationContext ctx) => currentValue<NbtLong>(ctx).value;
  @override
  int u64(SerializationContext ctx) => currentValue<NbtLong>(ctx).value;

  @override
  double f32(SerializationContext ctx) => currentValue<NbtFloat>(ctx).value;
  @override
  double f64(SerializationContext ctx) => currentValue<NbtDouble>(ctx).value;

  @override
  bool boolean(SerializationContext ctx) => currentValue<NbtByte>(ctx).value == 1;
  @override
  String string(SerializationContext ctx) => currentValue<NbtString>(ctx).value;
  @override
  Uint8List bytes(SerializationContext ctx) => Uint8List.view(currentValue<NbtByteArray>(ctx).value.buffer);
  @override
  E? optional<E>(SerializationContext ctx, Endec<E> endec) {
    final frameValue = currentValue(ctx);
    if (_potentialFlattenedOptional[frameValue] != null) {
      return endec.decode(ctx, this);
    }

    final state = struct(ctx);
    return state.field("present", ctx, Endec.bool) ? state.field("value", ctx, endec) : null;
  }

  @override
  SequenceDeserializer<E> sequence<E>(SerializationContext ctx, Endec<E> elementEndec) =>
      _NbtSequenceDeserializer(this, ctx, elementEndec, currentValue<NbtList>(ctx));
  @override
  MapDeserializer<V> map<V>(SerializationContext ctx, Endec<V> valueEndec) =>
      _NbtMapDeserializer.map(this, ctx, valueEndec, currentValue<NbtCompound>(ctx));
  @override
  StructDeserializer struct(SerializationContext ctx) =>
      _NbtMapDeserializer.struct(this, currentValue<NbtCompound>(ctx));
}

class _NbtMapDeserializer<V> implements MapDeserializer<V>, StructDeserializer {
  final NbtDeserializer _deserializer;
  final SerializationContext? _ctx;
  final Endec<V>? _valueEndec;

  final Map<String, NbtElement> _map;
  final Iterator<MapEntry<String, NbtElement>> _entries;

  _NbtMapDeserializer.map(this._deserializer, this._ctx, Endec<V> valueEndec, NbtCompound compound)
      : _valueEndec = valueEndec,
        _map = compound.value,
        _entries = compound.value.entries.iterator;

  _NbtMapDeserializer.struct(this._deserializer, NbtCompound compound)
      : _ctx = null,
        _valueEndec = null,
        _map = compound.value,
        _entries = compound.value.entries.iterator;

  @override
  bool moveNext() => _entries.moveNext();

  @override
  (String, V) entry() => _deserializer.frame(
        () => _entries.current.value,
        () => (_entries.current.key, _valueEndec!.decode(_ctx!.pushField(_entries.current.key), _deserializer)),
      );

  @override
  F field<F>(String name, SerializationContext ctx, Endec<F> endec, {F Function()? defaultValueFactory}) {
    final value = _map[name];
    if (value == null) {
      if (defaultValueFactory != null) return defaultValueFactory();
      ctx.malformedInput('Required field $name is missing from serialized data');
    }

    if (defaultValueFactory != null) {
      _potentialFlattenedOptional[value] = const ();
    }

    return _deserializer.frame(
      () => value,
      () => endec.decode(ctx.pushField(name), _deserializer),
    );
  }
}

class _NbtSequenceDeserializer<V> implements SequenceDeserializer<V> {
  final NbtDeserializer _deserializer;
  final SerializationContext _ctx;
  final Endec<V> _elementEndec;
  final Iterator<(int, NbtElement)> _entries;

  _NbtSequenceDeserializer(this._deserializer, this._ctx, this._elementEndec, NbtList list)
      : _entries = list.value.indexed.iterator;

  @override
  bool moveNext() => _entries.moveNext();

  @override
  V element() => _deserializer.frame(
        () => _entries.current.$2,
        () => _elementEndec.decode(_ctx.pushIndex(_entries.current.$1), _deserializer),
      );
}

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
  void any(SerializationContext ctx, Serializer visitor) => _decodeElement(ctx, visitor, currentValue());
  void _decodeElement(SerializationContext ctx, Serializer visitor, NbtElement element) {
    switch (element.type) {
      case NbtElementType.byte:
        visitor.i8(ctx, (element as NbtByte).value);
      case NbtElementType.short:
        visitor.i16(ctx, (element as NbtShort).value);
      case NbtElementType.int:
        visitor.i32(ctx, (element as NbtInt).value);
      case NbtElementType.long:
        visitor.i64(ctx, (element as NbtLong).value);
      case NbtElementType.float:
        visitor.f32(ctx, (element as NbtFloat).value);
      case NbtElementType.double:
        visitor.f64(ctx, (element as NbtDouble).value);
      case NbtElementType.string:
        visitor.string(ctx, (element as NbtString).value);
      case NbtElementType.byteArray:
        visitor.bytes(ctx, Uint8List.view((element as NbtByteArray).value.buffer));
      case NbtElementType.intArray:
        final list = (element as NbtIntArray).value;

        var state = visitor.sequence(ctx, Endec.i32, list.length);
        for (final element in list) {
          state.element(element);
        }
        state.end();
      case NbtElementType.longArray:
        final list = (element as NbtLongArray).value;

        var state = visitor.sequence(ctx, Endec.i64, list.length);
        for (final element in list) {
          state.element(element);
        }
        state.end();
      case NbtElementType.list:
        final list = (element as NbtList).value;

        var state =
            visitor.sequence(ctx, Endec<NbtElement>.of(_decodeElement, (ctx, deserializer) => NbtByte(0)), list.length);
        for (final element in list) {
          state.element(element);
        }
        state.end();
      case NbtElementType.compound:
        final map = (element as NbtCompound).value;

        var state =
            visitor.map(ctx, Endec<NbtElement>.of(_decodeElement, (ctx, deserializer) => NbtByte(0)), map.length);
        for (final MapEntry(:key, :value) in map.entries) {
          state.entry(key, value);
        }
        state.end();
      case _:
        throw ArgumentError.value(element, "element", "Non-standard, unrecognized NbtElement cannot be decoded");
    }
  }

  @override
  int i8(SerializationContext ctx) => currentValue<NbtByte>().value;
  @override
  int u8(SerializationContext ctx) => currentValue<NbtByte>().value;

  @override
  int i16(SerializationContext ctx) => currentValue<NbtShort>().value;
  @override
  int u16(SerializationContext ctx) => currentValue<NbtShort>().value;

  @override
  int i32(SerializationContext ctx) => currentValue<NbtInt>().value;
  @override
  int u32(SerializationContext ctx) => currentValue<NbtInt>().value;

  @override
  int i64(SerializationContext ctx) => currentValue<NbtLong>().value;
  @override
  int u64(SerializationContext ctx) => currentValue<NbtLong>().value;

  @override
  double f32(SerializationContext ctx) => currentValue<NbtFloat>().value;
  @override
  double f64(SerializationContext ctx) => currentValue<NbtDouble>().value;

  @override
  bool boolean(SerializationContext ctx) => currentValue<NbtByte>().value == 1;
  @override
  String string(SerializationContext ctx) => currentValue<NbtString>().value;
  @override
  Uint8List bytes(SerializationContext ctx) => Uint8List.view(currentValue<NbtByteArray>().value.buffer);
  @override
  E? optional<E>(SerializationContext ctx, Endec<E> endec) {
    final frameValue = currentValue();
    if (_potentialFlattenedOptional[frameValue] != null) {
      return endec.decode(ctx, this);
    }

    final state = struct();
    return state.field("present", ctx, Endec.bool) ? state.field("value", ctx, endec) : null;
  }

  @override
  SequenceDeserializer<E> sequence<E>(SerializationContext ctx, Endec<E> elementEndec) =>
      _NbtSequenceDeserializer(this, ctx, elementEndec, currentValue<NbtList>());
  @override
  MapDeserializer<V> map<V>(SerializationContext ctx, Endec<V> valueEndec) =>
      _NbtMapDeserializer.map(this, ctx, valueEndec, currentValue<NbtCompound>());
  @override
  StructDeserializer struct() => _NbtMapDeserializer.struct(this, currentValue<NbtCompound>());
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
        () => (_entries.current.key, _valueEndec!.decode(_ctx!, _deserializer)),
      );

  @override
  F field<F>(String name, SerializationContext ctx, Endec<F> endec, {F Function()? defaultValueFactory}) {
    final value = _map[name];
    if (value == null) {
      if (defaultValueFactory != null) return defaultValueFactory();
      throw NbtDecodeException('Required field $name is missing from serialized data');
    }

    if (defaultValueFactory != null) {
      _potentialFlattenedOptional[value] = const ();
    }

    return _deserializer.frame(
      () => value,
      () => endec.decode(ctx, _deserializer),
    );
  }
}

class _NbtSequenceDeserializer<V> implements SequenceDeserializer<V> {
  final NbtDeserializer _deserializer;
  final SerializationContext _ctx;
  final Endec<V> _elementEndec;
  final Iterator<NbtElement> _entries;

  _NbtSequenceDeserializer(this._deserializer, this._ctx, this._elementEndec, NbtList list)
      : _entries = list.value.iterator;

  @override
  bool moveNext() => _entries.moveNext();

  @override
  V element() => _deserializer.frame(
        () => _entries.current,
        () => _elementEndec.decode(_ctx, _deserializer),
      );
}

class NbtDecodeException implements Exception {
  final String message;
  NbtDecodeException(this.message);

  @override
  String toString() => "NBT decoding failed: $message";
}

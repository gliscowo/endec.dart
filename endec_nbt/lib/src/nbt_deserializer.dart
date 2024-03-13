import 'dart:typed_data';

import 'package:endec/endec.dart';

import 'nbt_types.dart';

T fromNbt<T>(Endec<T> endec, NbtElement nbt) {
  final deserializer = NbtDeserializer(nbt);
  return endec.decode(deserializer);
}

class NbtDeserializer extends RecursiveDeserializer<NbtElement> implements SelfDescribingDeserializer {
  NbtDeserializer(super._serialized);
  @override
  void any(Serializer visitor) => _decodeElement(visitor, currentValue());
  void _decodeElement(Serializer visitor, NbtElement element) {
    switch (element.type) {
      case NbtElementType.byte:
        visitor.i8((element as NbtByte).value);
      case NbtElementType.short:
        visitor.i16((element as NbtShort).value);
      case NbtElementType.int:
        visitor.i32((element as NbtInt).value);
      case NbtElementType.long:
        visitor.i64((element as NbtLong).value);
      case NbtElementType.float:
        visitor.f32((element as NbtFloat).value);
      case NbtElementType.double:
        visitor.f64((element as NbtDouble).value);
      case NbtElementType.string:
        visitor.string((element as NbtString).value);
      case NbtElementType.byteArray:
        visitor.bytes(Uint8List.view((element as NbtByteArray).value.buffer));
      case NbtElementType.intArray:
        final list = (element as NbtIntArray).value;

        var state = visitor.sequence(
          Endec<int>.of((serializer, value) => serializer.i32(value), (deserializer) => deserializer.i32()),
          list.length,
        );

        for (final element in list) {
          state.element(element);
        }
        state.end();
      case NbtElementType.longArray:
        final list = (element as NbtLongArray).value;

        var state = visitor.sequence(Endec.int, list.length);
        for (final element in list) {
          state.element(element);
        }
        state.end();
      case NbtElementType.list:
        final list = (element as NbtList).value;

        var state = visitor.sequence(Endec<NbtElement>.of(_decodeElement, (deserializer) => NbtByte(0)), list.length);
        for (final element in list) {
          state.element(element);
        }
        state.end();
      case NbtElementType.compound:
        final map = (element as NbtCompound).value;

        var state = visitor.map(Endec<NbtElement>.of(_decodeElement, (deserializer) => NbtByte(0)), map.length);
        for (final MapEntry(:key, :value) in map.entries) {
          state.entry(key, value);
        }
        state.end();
      case _:
        throw ArgumentError.value(element, "element", "Non-standard, unrecognized NbtElement cannot be decoded");
    }
  }

  @override
  int i8() => currentValue<NbtByte>().value;
  @override
  int u8() => currentValue<NbtByte>().value;

  @override
  int i16() => currentValue<NbtShort>().value;
  @override
  int u16() => currentValue<NbtShort>().value;

  @override
  int i32() => currentValue<NbtInt>().value;
  @override
  int u32() => currentValue<NbtInt>().value;

  @override
  int i64() => currentValue<NbtLong>().value;
  @override
  int u64() => currentValue<NbtLong>().value;

  @override
  double f32() => currentValue<NbtFloat>().value;
  @override
  double f64() => currentValue<NbtDouble>().value;

  @override
  bool boolean() => currentValue<NbtByte>().value == 1;
  @override
  String string() => currentValue<NbtString>().value;
  @override
  Uint8List bytes() => Uint8List.view(currentValue<NbtByteArray>().value.buffer);
  @override
  E? optional<E>(Endec<E> endec) {
    final state = struct();
    return state.field("present", Endec.bool) ? state.field("value", endec) : null;
  }

  @override
  SequenceDeserializer<E> sequence<E>(Endec<E> elementEndec) =>
      _NbtSequenceDeserializer(this, elementEndec, currentValue<NbtList>());
  @override
  MapDeserializer<V> map<V>(Endec<V> valueEndec) =>
      _NbtMapDeserializer.map(this, valueEndec, currentValue<NbtCompound>());
  @override
  StructDeserializer struct() => _NbtMapDeserializer.struct(this, currentValue<NbtCompound>());
}

class _NbtMapDeserializer<V> implements MapDeserializer<V>, StructDeserializer {
  final NbtDeserializer _context;
  final Endec<V>? _valueEndec;

  final Map<String, NbtElement> _map;
  final Iterator<MapEntry<String, NbtElement>> _entries;

  _NbtMapDeserializer.map(this._context, Endec<V> valueEndec, NbtCompound compound)
      : _valueEndec = valueEndec,
        _map = compound.value,
        _entries = compound.value.entries.iterator;

  _NbtMapDeserializer.struct(this._context, NbtCompound compound)
      : _valueEndec = null,
        _map = compound.value,
        _entries = compound.value.entries.iterator;

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
      throw NbtDecodeException("Required field $name is missing from serialized data");
    }

    return _context.frame(
      () => _map[name]!,
      () => endec.decode(_context),
      true,
    );
  }

  @override
  F optionalField<F>(String name, Endec<F> endec, F Function() defaultValueFactory) {
    if (!_map.containsKey(name)) {
      return defaultValueFactory();
    }

    return _context.frame(
      () => _map[name]!,
      () => endec.decode(_context),
      true,
    );
  }
}

class _NbtSequenceDeserializer<V> implements SequenceDeserializer<V> {
  final NbtDeserializer _context;
  final Endec<V> _elementEndec;
  final Iterator<NbtElement> _entries;

  _NbtSequenceDeserializer(this._context, this._elementEndec, NbtList list) : _entries = list.value.iterator;

  @override
  bool moveNext() => _entries.moveNext();

  @override
  V element() => _context.frame(
        () => _entries.current,
        () => _elementEndec.decode(_context),
        false,
      );
}

class NbtDecodeException implements Exception {
  final String message;
  NbtDecodeException(this.message);

  @override
  String toString() => "NBT decoding failed: $message";
}

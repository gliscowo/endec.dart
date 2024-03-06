import 'dart:collection';
import 'dart:typed_data';

import 'package:endec/deserializer.dart';
import 'package:endec/endec.dart';
import 'package:endec/serializer.dart';

import 'nbt_types.dart';

T fromNbt<T>(Endec<T> endec, NbtElement nbt) {
  final deserializer = NbtDeserializer(nbt);
  return endec.decode(deserializer);
}

typedef NbtSource = NbtElement Function();

class NbtDeserializer implements SelfDescribingDeserializer<Object?> {
  final Queue<NbtSource> _sources = Queue();
  final NbtElement _serialized;

  NbtDeserializer(this._serialized) {
    _sources.add(() => _serialized);
  }

  E _getElement<E extends NbtElement>() => _sources.last() as E;

  @override
  void any<S>(Serializer<S> visitor) => _decodeElement(visitor, _getElement());
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
        visitor.bytes((element as NbtByteArray).value);
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
  bool boolean() => _getElement<NbtByte>().value == 1;
  @override
  E? optional<E>(Endec<E> endec) {
    final state = struct();
    return state.field("present", Endec.bool) ? state.field("value", endec) : null;
  }

  @override
  int i8() => _getElement<NbtByte>().value;
  @override
  int u8() => _getElement<NbtByte>().value;

  @override
  int i16() => _getElement<NbtShort>().value;
  @override
  int u16() => _getElement<NbtShort>().value;

  @override
  int i32() => _getElement<NbtInt>().value;
  @override
  int u32() => _getElement<NbtInt>().value;

  @override
  int i64() => _getElement<NbtLong>().value;
  @override
  int u64() => _getElement<NbtLong>().value;

  @override
  double f32() => _getElement<NbtFloat>().value;
  @override
  double f64() => _getElement<NbtDouble>().value;

  @override
  String string() => _getElement<NbtString>().value;
  @override
  Uint8List bytes() => _getElement<NbtByteArray>().value;

  @override
  SequenceDeserializer<E> sequence<E>(Endec<E> elementEndec) =>
      _NbtSequenceDeserializer(this, elementEndec, _getElement<NbtList>());
  @override
  MapDeserializer<V> map<V>(Endec<V> valueEndec) =>
      _NbtMapDeserializer.map(this, valueEndec, _getElement<NbtCompound>());
  @override
  StructDeserializer struct() => _NbtMapDeserializer.struct(this, _getElement<NbtCompound>());

  void _pushSource(NbtSource source) => _sources.addLast(source);
  void _popSource() => _sources.removeLast();
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
        throw NbtDecodeError("Field $name was missing from serialized data, but no default value was provided");
      }

      return defaultValue;
    }

    _context._pushSource(() => _map[name]!);
    final decoded = endec.decode(_context);
    _context._popSource();

    return decoded;
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
  V element() {
    _context._pushSource(() => _entries.current);
    final decoded = _elementEndec.decode(_context);
    _context._popSource();

    return decoded;
  }
}

class NbtDecodeError extends Error {
  final String message;
  NbtDecodeError(this.message);

  @override
  String toString() => "NBT decoding failed: $message";
}

import 'dart:collection';
import 'dart:typed_data';

import '../codec.dart';
import '../deserializer.dart';
import 'nbt_types.dart';

T fromNbt<T>(Codec<T> codec, NbtElement nbt) {
  final deserializer = NbtDeserializer(nbt);
  return codec.decode(deserializer);
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
  Object? any() => _fromNbt(_getElement());
  Object _fromNbt(NbtElement element) => switch (element) {
        NbtCompound compound => compound.value.map((key, value) => MapEntry(key, _fromNbt(value))),
        NbtList list => list.value.map(_fromNbt).toList(),
        _ => element.value
      };

  @override
  bool boolean() => _getElement<NbtByte>().value == 1;
  @override
  E? optional<E>(Codec<E> codec) {
    var compound = _getElement<NbtCompound>().value;
    if ((compound["present"] as NbtByte).value != 1) return null;

    _pushSource(() => compound["value"]!);
    final decoded = codec.decode(this);
    _popSource();

    return decoded;
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
  SequenceDeserializer<E> sequence<E>(Codec<E> elementCodec) =>
      _NbtSequenceDeserializer(this, elementCodec, _getElement<NbtList>());
  @override
  MapDeserializer<V> map<V>(Codec<V> valueCodec) =>
      _NbtMapDeserializer.map(this, valueCodec, _getElement<NbtCompound>());
  @override
  StructDeserializer struct() => _NbtMapDeserializer.struct(this, _getElement<NbtCompound>());

  void _pushSource(NbtSource source) => _sources.addLast(source);
  void _popSource() => _sources.removeLast();
}

class _NbtMapDeserializer<V> implements MapDeserializer<V>, StructDeserializer {
  final NbtDeserializer _context;
  final Codec<V>? _valueCodec;

  final Map<String, NbtElement> _map;
  final Iterator<MapEntry<String, NbtElement>> _entries;

  _NbtMapDeserializer.map(this._context, Codec<V> valueCodec, NbtCompound compound)
      : _valueCodec = valueCodec,
        _map = compound.value,
        _entries = compound.value.entries.iterator;

  _NbtMapDeserializer.struct(this._context, NbtCompound compound)
      : _valueCodec = null,
        _map = compound.value,
        _entries = compound.value.entries.iterator;

  @override
  bool moveNext() => _entries.moveNext();

  @override
  (String, V) entry() {
    _context._pushSource(() => _entries.current.value);
    final decoded = _valueCodec!.decode(_context);
    _context._popSource();

    return (_entries.current.key, decoded);
  }

  @override
  F field<F>(String name, Codec<F> codec, {F? defaultValue}) {
    if (!_map.containsKey(name)) {
      if (defaultValue == null) {
        throw NbtDecodeError("Field $name was missing from serialized data, but no default ");
      }

      return defaultValue;
    }

    _context._pushSource(() => _map[name]!);
    final decoded = codec.decode(_context);
    _context._popSource();

    return decoded;
  }
}

class _NbtSequenceDeserializer<V> implements SequenceDeserializer<V> {
  final NbtDeserializer _context;
  final Codec<V> _elementCodec;
  final Iterator<NbtElement> _entries;

  _NbtSequenceDeserializer(this._context, this._elementCodec, NbtList list) : _entries = list.value.iterator;

  @override
  bool moveNext() => _entries.moveNext();

  @override
  V element() {
    _context._pushSource(() => _entries.current);
    final decoded = _elementCodec.decode(_context);
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

import 'dart:collection';
import 'dart:typed_data';

import '../codec.dart';
import '../serializer.dart';
import 'nbt_types.dart';

NbtElement toNbt<T>(Codec<T> codec, T value) {
  final serializer = NbtSerializer();
  codec.encode(serializer, value);
  return serializer.result;
}

typedef NbtSink = void Function(NbtElement nbtValue);

class NbtSerializer implements Serializer<NbtElement> {
  @override
  final bool selfDescribing = true;

  final Queue<NbtSink> _sinks = Queue();
  NbtElement? _result;

  NbtSerializer() {
    _sinks.add((nbtValue) => _result = nbtValue);
  }

  void _sink(NbtElement nbtValue) => _sinks.last(nbtValue);

  @override
  void boolean(bool value) => _sink(NbtByte(value ? 1 : 0));
  @override
  void optional<E>(Codec<E> codec, E? value) {
    var compound = <String, NbtElement>{"present": NbtByte(value != null ? 1 : 0)};

    if (value != null) {
      NbtElement? encoded;
      _pushSink((nbtValue) => encoded = nbtValue);
      codec.encode(this, value);
      _popSink();

      if (encoded == null) throw NbtEncodeError("Codec for present optional value encoded nothing");
      compound["value"] = encoded!;
    }

    _sink(NbtCompound(compound));
  }

  @override
  void i8(int value) => _sink(NbtByte(value));
  @override
  void u8(int value) => _sink(NbtByte(value));

  @override
  void i16(int value) => _sink(NbtShort(value));
  @override
  void u16(int value) => _sink(NbtShort(value));

  @override
  void i32(int value) => _sink(NbtInt(value));
  @override
  void u32(int value) => _sink(NbtInt(value));

  @override
  void i64(int value) => _sink(NbtLong(value));
  @override
  void u64(int value) => _sink(NbtLong(value));

  @override
  void f32(double value) => _sink(NbtFloat(value));
  @override
  void f64(double value) => _sink(NbtDouble(value));

  @override
  void string(String value) => _sink(NbtString(value));
  @override
  void bytes(Uint8List bytes) => _sink(NbtByteArray(bytes));

  @override
  SequenceSerializer<E> sequence<E>(Codec<E> elementCodec, int length) => _NbtSequenceSerializer(this, elementCodec);
  @override
  MapSerializer<V> map<V>(Codec<V> valueCodec, int length) => _NbtMapSerializer.map(this, valueCodec);
  @override
  StructSerializer struct() => _NbtMapSerializer.struct(this);

  @override
  NbtElement get result => _result ?? NbtCompound(const {});

  void _pushSink(NbtSink sink) => _sinks.addLast(sink);
  void _popSink() => _sinks.removeLast();
}

class _NbtMapSerializer<V> implements MapSerializer<V>, StructSerializer {
  final NbtSerializer _context;
  final Codec<V>? _valueCodec;
  final Map<String, NbtElement> _result = {};

  _NbtMapSerializer.map(this._context, Codec<V> valueCodec) : _valueCodec = valueCodec;
  _NbtMapSerializer.struct(this._context) : _valueCodec = null;

  @override
  void entry(String key, V value) => _kvPair(key, _valueCodec!, value);
  @override
  void field<F, _V extends F>(String key, Codec<F> codec, _V value) => _kvPair(key, codec, value);

  void _kvPair<T>(String key, Codec<T> codec, T value) {
    NbtElement? encodedValue;
    void sink(NbtElement nbtValue) => encodedValue = nbtValue;

    _context._pushSink(sink);
    codec.encode(_context, value);
    _context._popSink();

    if (encodedValue == null) throw NbtEncodeError("Codec for NBT Compound value encoded nothing");
    _result[key] = encodedValue!;
  }

  @override
  void end() => _context._sink(NbtCompound(_result));
}

class _NbtSequenceSerializer<V> implements SequenceSerializer<V> {
  final NbtSerializer _context;
  final Codec<V> _elementCodec;
  final List<NbtElement> _result = [];

  _NbtSequenceSerializer(this._context, this._elementCodec);

  @override
  void element(V value) {
    NbtElement? encodedValue;
    void sink(NbtElement nbtValue) => encodedValue = nbtValue;

    _context._pushSink(sink);
    _elementCodec.encode(_context, value);
    _context._popSink();

    if (encodedValue == null) throw NbtEncodeError("No value was serialized");
    _result.add(encodedValue!);
  }

  @override
  void end() => _context._sink(NbtList(_result));
}

class NbtEncodeError extends Error {
  final String message;
  NbtEncodeError(this.message);

  @override
  String toString() => "NBT encoding failed: $message";
}

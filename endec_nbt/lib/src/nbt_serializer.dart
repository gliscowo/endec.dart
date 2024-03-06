import 'dart:collection';
import 'dart:typed_data';

import 'package:endec/endec.dart';
import 'package:endec/serializer.dart';

import 'nbt_types.dart';

NbtElement toNbt<T>(Endec<T> endec, T value) {
  final serializer = NbtSerializer();
  endec.encode(serializer, value);
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
  void optional<E>(Endec<E> endec, E? value) {
    final state = struct();
    state.field("present", Endec.bool, value != null);
    if (value != null) state.field("value", endec, value);
    state.end();
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
  SequenceSerializer<E> sequence<E>(Endec<E> elementEndec, int length) => _NbtSequenceSerializer(this, elementEndec);
  @override
  MapSerializer<V> map<V>(Endec<V> valueEndec, int length) => _NbtMapSerializer.map(this, valueEndec);
  @override
  StructSerializer struct() => _NbtMapSerializer.struct(this);

  @override
  NbtElement get result => _result ?? NbtCompound(const {});

  void _pushSink(NbtSink sink) => _sinks.addLast(sink);
  void _popSink() => _sinks.removeLast();
}

class _NbtMapSerializer<V> implements MapSerializer<V>, StructSerializer {
  final NbtSerializer _context;
  final Endec<V>? _valueEndec;
  final Map<String, NbtElement> _result = {};

  _NbtMapSerializer.map(this._context, Endec<V> valueEndec) : _valueEndec = valueEndec;
  _NbtMapSerializer.struct(this._context) : _valueEndec = null;

  @override
  void entry(String key, V value) => _kvPair(key, _valueEndec!, value);
  @override
  void field<F, _V extends F>(String key, Endec<F> endec, _V value) => _kvPair(key, endec, value);

  void _kvPair<T>(String key, Endec<T> endec, T value) {
    NbtElement? encodedValue;
    void sink(NbtElement nbtValue) => encodedValue = nbtValue;

    _context._pushSink(sink);
    endec.encode(_context, value);
    _context._popSink();

    if (encodedValue == null) throw NbtEncodeError("Endec for NBT Compound value encoded nothing");
    _result[key] = encodedValue!;
  }

  @override
  void end() => _context._sink(NbtCompound(_result));
}

class _NbtSequenceSerializer<V> implements SequenceSerializer<V> {
  final NbtSerializer _context;
  final Endec<V> _elementEndec;
  final List<NbtElement> _result = [];

  _NbtSequenceSerializer(this._context, this._elementEndec);

  @override
  void element(V value) {
    NbtElement? encodedValue;
    void sink(NbtElement nbtValue) => encodedValue = nbtValue;

    _context._pushSink(sink);
    _elementEndec.encode(_context, value);
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

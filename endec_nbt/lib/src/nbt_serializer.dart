import 'dart:typed_data';

import 'package:endec/endec.dart';

import 'nbt_types.dart';

NbtElement toNbt<T, S extends T>(Endec<T> endec, S value) {
  final serializer = NbtSerializer();
  endec.encode(serializer, value);
  return serializer.result;
}

class NbtSerializer extends RecursiveSerializer {
  @override
  final bool selfDescribing = true;

  NbtSerializer() : super(NbtCompound(const {}));

  @override
  void boolean(bool value) => consume(NbtByte(value ? 1 : 0));
  @override
  void optional<E>(Endec<E> endec, E? value) {
    final state = struct();
    state.field("present", Endec.bool, value != null);
    if (value != null) state.field("value", endec, value);
    state.end();
  }

  @override
  void i8(int value) => consume(NbtByte(value));
  @override
  void u8(int value) => consume(NbtByte(value));

  @override
  void i16(int value) => consume(NbtShort(value));
  @override
  void u16(int value) => consume(NbtShort(value));

  @override
  void i32(int value) => consume(NbtInt(value));
  @override
  void u32(int value) => consume(NbtInt(value));

  @override
  void i64(int value) => consume(NbtLong(value));
  @override
  void u64(int value) => consume(NbtLong(value));

  @override
  void f32(double value) => consume(NbtFloat(value));
  @override
  void f64(double value) => consume(NbtDouble(value));

  @override
  void string(String value) => consume(NbtString(value));
  @override
  void bytes(Uint8List bytes) => consume(NbtByteArray(Int8List.view(bytes.buffer)));

  @override
  SequenceSerializer<E> sequence<E>(Endec<E> elementEndec, int length) => _NbtSequenceSerializer(this, elementEndec);
  @override
  MapSerializer<V> map<V>(Endec<V> valueEndec, int length) => _NbtMapSerializer.map(this, valueEndec);
  @override
  StructSerializer struct() => _NbtMapSerializer.struct(this);
}

class _NbtMapSerializer<V> implements MapSerializer<V>, StructSerializer {
  final NbtSerializer _context;
  final Endec<V>? _valueEndec;
  final Map<String, NbtElement> _result = {};

  _NbtMapSerializer.map(this._context, Endec<V> valueEndec) : _valueEndec = valueEndec;
  _NbtMapSerializer.struct(this._context) : _valueEndec = null;

  @override
  void entry(String key, V value) => _context.frame(
        (holder) {
          _valueEndec!.encode(_context, value);
          _result[key] = holder.require("map value");
        },
        false,
      );

  @override
  void field<F, _V extends F>(String key, Endec<F> endec, _V value) => _context.frame(
        (holder) {
          endec.encode(_context, value);
          _result[key] = holder.require("struct field");
        },
        true,
      );

  @override
  void end() => _context.consume(NbtCompound(_result));
}

class _NbtSequenceSerializer<V> implements SequenceSerializer<V> {
  final NbtSerializer _context;
  final Endec<V> _elementEndec;
  final List<NbtElement> _result = [];

  _NbtSequenceSerializer(this._context, this._elementEndec);

  @override
  void element(V value) => _context.frame(
        (holder) {
          _elementEndec.encode(_context, value);
          _result.add(holder.require("sequence element"));
        },
        false,
      );

  @override
  void end() => _context.consume(NbtList(_result));
}

class NbtEncodeError extends Error {
  final String message;
  NbtEncodeError(this.message);

  @override
  String toString() => "NBT encoding failed: $message";
}

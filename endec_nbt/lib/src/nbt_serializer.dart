import 'dart:typed_data';

import 'package:endec/endec.dart';

import 'nbt_types.dart';

NbtElement toNbt<T, S extends T>(Endec<T> endec, S value, {SerializationContext ctx = SerializationContext.empty}) {
  final serializer = NbtSerializer();
  endec.encode(ctx, serializer, value);
  return serializer.result;
}

final _optionalCompounds = Expando<()>();

class NbtSerializer extends RecursiveSerializer {
  @override
  final bool selfDescribing = true;

  NbtSerializer() : super(NbtCompound(const {}));

  @override
  void i8(SerializationContext ctx, int value) => consume(NbtByte(value));
  @override
  void u8(SerializationContext ctx, int value) => consume(NbtByte(value));

  @override
  void i16(SerializationContext ctx, int value) => consume(NbtShort(value));
  @override
  void u16(SerializationContext ctx, int value) => consume(NbtShort(value));

  @override
  void i32(SerializationContext ctx, int value) => consume(NbtInt(value));
  @override
  void u32(SerializationContext ctx, int value) => consume(NbtInt(value));

  @override
  void i64(SerializationContext ctx, int value) => consume(NbtLong(value));
  @override
  void u64(SerializationContext ctx, int value) => consume(NbtLong(value));

  @override
  void f32(SerializationContext ctx, double value) => consume(NbtFloat(value));
  @override
  void f64(SerializationContext ctx, double value) => consume(NbtDouble(value));

  @override
  void boolean(SerializationContext ctx, bool value) => consume(NbtByte(value ? 1 : 0));
  @override
  void string(SerializationContext ctx, String value) => consume(NbtString(value));
  @override
  void bytes(SerializationContext ctx, Uint8List bytes) => consume(NbtByteArray(Int8List.view(bytes.buffer)));
  @override
  void optional<E>(SerializationContext ctx, Endec<E> endec, E? value) {
    final compoundValue = <String, NbtElement>{
      'present': NbtByte(value != null ? 1 : 0),
    };

    if (value != null) {
      frame((holder) {
        endec.encode(ctx, this, value);
        compoundValue['value'] = holder.require('present optional value');
      });
    }

    final compound = NbtCompound(compoundValue);
    consume(compound);

    _optionalCompounds[compound] = const ();
  }

  @override
  SequenceSerializer<E> sequence<E>(SerializationContext ctx, Endec<E> elementEndec, int length) =>
      _NbtSequenceSerializer(this, ctx, elementEndec);
  @override
  MapSerializer<V> map<V>(SerializationContext ctx, Endec<V> valueEndec, int length) =>
      _NbtMapSerializer.map(this, ctx, valueEndec);
  @override
  StructSerializer struct() => _NbtMapSerializer.struct(this);
}

class _NbtMapSerializer<V> implements MapSerializer<V>, StructSerializer {
  final NbtSerializer _serializer;
  final SerializationContext? _ctx;
  final Endec<V>? _valueEndec;
  final Map<String, NbtElement> _result = {};

  _NbtMapSerializer.map(this._serializer, this._ctx, Endec<V> valueEndec) : _valueEndec = valueEndec;
  _NbtMapSerializer.struct(this._serializer)
      : _ctx = null,
        _valueEndec = null;

  @override
  void entry(String key, V value) => _serializer.frame((holder) {
        _valueEndec!.encode(_ctx!, _serializer, value);
        _result[key] = holder.require("map value");
      });

  @override
  void field<F, _V extends F>(String key, SerializationContext ctx, Endec<F> endec, _V value, {bool mayOmit = false}) =>
      _serializer.frame((holder) {
        endec.encode(ctx, _serializer, value);

        final encodedValue = holder.require('struct field');
        if (mayOmit && _optionalCompounds[encodedValue] != null) {
          if (encodedValue case NbtCompound(value: {'present': NbtByte(value: 0)})) return;

          _result[key] = (encodedValue as NbtCompound).value['value'] as NbtElement;
          return;
        }

        _result[key] = encodedValue;
      });

  @override
  void end() => _serializer.consume(NbtCompound(_result));
}

class _NbtSequenceSerializer<V> implements SequenceSerializer<V> {
  final NbtSerializer _serializer;
  final SerializationContext _ctx;
  final Endec<V> _elementEndec;
  final List<NbtElement> _result = [];

  _NbtSequenceSerializer(this._serializer, this._ctx, this._elementEndec);

  @override
  void element(V value) => _serializer.frame((holder) {
        _elementEndec.encode(_ctx, _serializer, value);
        _result.add(holder.require("sequence element"));
      });

  @override
  void end() => _serializer.consume(NbtList(_result));
}

class NbtEncodeError extends Error {
  final String message;
  NbtEncodeError(this.message);

  @override
  String toString() => "NBT encoding failed: $message";
}

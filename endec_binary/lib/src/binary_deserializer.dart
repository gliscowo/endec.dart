import 'dart:convert';
import 'dart:typed_data';

import 'package:endec/endec.dart';

T fromBinary<T>(Endec<T> endec, Uint8List encoded, {SerializationContext ctx = SerializationContext.empty}) =>
    endec.decode(ctx, BinaryDeserializer(ByteData.view(encoded.buffer)));

class BinaryDeserializer implements Deserializer {
  final ByteData _buffer;
  int _cursor = 0;

  BinaryDeserializer(this._buffer);

  @override
  int i8(SerializationContext ctx) => _read((idx, _) => _buffer.getInt8(idx), 1);
  @override
  int u8(SerializationContext ctx) => _read((idx, _) => _buffer.getUint8(idx), 1);

  @override
  int i16(SerializationContext ctx) => _read(_buffer.getInt16, 2);
  @override
  int u16(SerializationContext ctx) => _read(_buffer.getUint16, 2);

  @override
  int i32(SerializationContext ctx) => _read(_buffer.getInt32, 4);
  @override
  int u32(SerializationContext ctx) => _read(_buffer.getUint32, 4);

  @override
  int i64(SerializationContext ctx) => _read(_buffer.getInt64, 8);
  @override
  int u64(SerializationContext ctx) => _read(_buffer.getUint64, 8);

  @override
  double f32(SerializationContext ctx) => _read(_buffer.getFloat32, 4);
  @override
  double f64(SerializationContext ctx) => _read(_buffer.getFloat64, 8);

  T _read<T>(T Function(int idx, Endian) reader, int size) {
    final value = reader(_cursor, Endian.little);
    _cursor += size;

    return value;
  }

  @override
  bool boolean(SerializationContext ctx) => u8(ctx) != 0;
  @override
  String string(SerializationContext ctx) => utf8.decode(_readBytes(ctx));
  @override
  Uint8List bytes(SerializationContext ctx) => _readBytes(ctx);
  @override
  E? optional<E>(SerializationContext ctx, Endec<E> endec) => boolean(ctx) ? endec.decode(ctx, this) : null;

  Uint8List _readBytes(SerializationContext ctx) {
    final length = i32(ctx);

    final list = Uint8List.view(_buffer.buffer, _cursor, length);
    _cursor += length;

    return list;
  }

  @override
  SequenceDeserializer<E> sequence<E>(SerializationContext ctx, Endec<E> elementEndec) =>
      _BinarySequenceDeserializer(this, ctx, elementEndec);

  @override
  MapDeserializer<V> map<V>(SerializationContext ctx, Endec<V> valueEndec) =>
      _BinaryMapDeserializer(this, ctx, valueEndec);

  @override
  StructDeserializer struct() => _BinaryStructDeserializer(this);

  @override
  V tryRead<V>(V Function(Deserializer deserializer) reader) {
    final prevCursor = _cursor;

    try {
      return reader(this);
    } catch (_) {
      _cursor = prevCursor;
      rethrow;
    }
  }
}

class _BinarySequenceDeserializer<V> implements SequenceDeserializer<V> {
  final BinaryDeserializer _deserializer;
  final SerializationContext _ctx;
  final Endec<V> _elementEndec;

  final int _length;
  int _read = 0;

  _BinarySequenceDeserializer(this._deserializer, this._ctx, this._elementEndec) : _length = _deserializer.i32(_ctx);

  @override
  bool moveNext() => ++_read <= _length;

  @override
  V element() => _elementEndec.decode(_ctx, _deserializer);
}

class _BinaryMapDeserializer<V> implements MapDeserializer<V> {
  final BinaryDeserializer _deserializer;
  final SerializationContext _ctx;
  final Endec<V> _valueEndec;

  final int _length;
  int _read = 0;

  _BinaryMapDeserializer(this._deserializer, this._ctx, this._valueEndec) : _length = _deserializer.i32(_ctx);

  @override
  bool moveNext() => ++_read <= _length;

  @override
  (String, V) entry() => (_deserializer.string(_ctx), _valueEndec.decode(_ctx, _deserializer));
}

class _BinaryStructDeserializer implements StructDeserializer {
  final BinaryDeserializer _deserializer;
  _BinaryStructDeserializer(this._deserializer);

  @override
  F field<F>(String name, SerializationContext ctx, Endec<F> endec, {F Function()? defaultValueFactory}) =>
      endec.decode(ctx, _deserializer);
}

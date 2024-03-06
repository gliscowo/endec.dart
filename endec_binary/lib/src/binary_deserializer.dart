import 'dart:convert';
import 'dart:typed_data';

import 'package:endec/deserializer.dart';
import 'package:endec/endec.dart';

T fromBinary<T>(Endec<T> endec, Uint8List encoded) => endec.decode(BinaryDeserializer(ByteData.view(encoded.buffer)));

class BinaryDeserializer implements Deserializer<Uint8List> {
  final ByteData _buffer;
  int _cursor = 0;

  BinaryDeserializer(this._buffer);

  @override
  bool boolean() => u8() != 0;
  @override
  E? optional<E>(Endec<E> endec) => boolean() ? endec.decode(this) : null;

  @override
  int i8() => _read((idx, _) => _buffer.getInt8(idx), 1);
  @override
  int u8() => _read((idx, _) => _buffer.getUint8(idx), 1);

  @override
  int i16() => _read(_buffer.getInt16, 2);
  @override
  int u16() => _read(_buffer.getUint16, 2);

  @override
  int i32() => _read(_buffer.getInt32, 4);
  @override
  int u32() => _read(_buffer.getUint32, 4);

  @override
  int i64() => _read(_buffer.getInt64, 8);
  @override
  int u64() => _read(_buffer.getUint64, 8);

  @override
  double f32() => _read(_buffer.getFloat32, 4);
  @override
  double f64() => _read(_buffer.getFloat64, 8);

  T _read<T>(T Function(int idx, Endian) reader, int size) {
    final value = reader(_cursor, Endian.little);
    _cursor += size;

    return value;
  }

  @override
  String string() => utf8.decode(_readBytes());
  @override
  Uint8List bytes() => _readBytes();

  Uint8List _readBytes() {
    final length = i32();

    final list = Uint8List.view(_buffer.buffer, _cursor, length);
    _cursor += length;

    return list;
  }

  @override
  SequenceDeserializer<E> sequence<E>(Endec<E> elementEndec) => _BinarySequenceDeserializer(this, elementEndec);

  @override
  MapDeserializer<V> map<V>(Endec<V> valueEndec) => _BinaryMapDeserializer(this, valueEndec);

  @override
  StructDeserializer struct() => _BinaryStructDeserializer(this);
}

class _BinarySequenceDeserializer<V> implements SequenceDeserializer<V> {
  final BinaryDeserializer _context;
  final Endec<V> _elementEndec;

  final int _length;
  int _read = 0;

  _BinarySequenceDeserializer(this._context, this._elementEndec) : _length = _context.i32();

  @override
  bool moveNext() => ++_read <= _length;

  @override
  V element() => _elementEndec.decode(_context);
}

class _BinaryMapDeserializer<V> implements MapDeserializer<V> {
  final BinaryDeserializer _context;
  final Endec<V> _valueEndec;

  final int _length;
  int _read = 0;

  _BinaryMapDeserializer(this._context, this._valueEndec) : _length = _context.i32();

  @override
  bool moveNext() => ++_read <= _length;

  @override
  (String, V) entry() => (_context.string(), _valueEndec.decode(_context));
}

class _BinaryStructDeserializer implements StructDeserializer {
  final BinaryDeserializer _context;
  _BinaryStructDeserializer(this._context);

  @override
  F field<F>(String name, Endec<F> endec, {F? defaultValue}) => endec.decode(_context);
}

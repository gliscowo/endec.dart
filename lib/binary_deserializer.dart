import 'dart:convert';
import 'dart:typed_data';

import 'package:codec/codec.dart';
import 'package:codec/deserializer.dart';

class BinaryDeserializer implements Deserializer<Uint8List> {
  final ByteData _buffer;
  int _cursor = 0;

  BinaryDeserializer(this._buffer);

  @override
  int i8() {
    final value = _buffer.getInt8(_cursor);
    _cursor++;

    return value;
  }

  @override
  int u8() {
    final value = _buffer.getUint8(_cursor);
    _cursor++;

    return value;
  }

  @override
  int i16() {
    final value = _buffer.getInt16(_cursor, Endian.little);
    _cursor += 2;

    return value;
  }

  @override
  int u16() {
    final value = _buffer.getUint16(_cursor, Endian.little);
    _cursor += 2;

    return value;
  }

  @override
  int i32() {
    final value = _buffer.getInt32(_cursor, Endian.little);
    _cursor += 4;

    return value;
  }

  @override
  int u32() {
    final value = _buffer.getUint32(_cursor, Endian.little);
    _cursor += 4;

    return value;
  }

  @override
  int i64() {
    final value = _buffer.getInt64(_cursor, Endian.little);
    _cursor += 8;

    return value;
  }

  @override
  int u64() {
    final value = _buffer.getUint64(_cursor, Endian.little);
    _cursor += 8;

    return value;
  }

  @override
  double f32() {
    final value = _buffer.getFloat32(_cursor, Endian.little);
    _cursor += 4;

    return value;
  }

  @override
  double f64() {
    final value = _buffer.getFloat64(_cursor, Endian.little);
    _cursor += 8;

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
  SequenceDeserializer<E> sequence<E>(Codec<E> elementCodec) => _BinarySequenceDeserializer(this, elementCodec);

  @override
  MapDeserializer<V> map<V>(Codec<V> valueCodec) => _BinaryMapDeserializer(this, valueCodec);

  @override
  StructDeserializer struct() => _BinaryStructDeserializer(this);
}

class _BinarySequenceDeserializer<V> implements SequenceDeserializer<V> {
  final BinaryDeserializer _context;
  final Codec<V> _elementCodec;

  final int _length;
  int _read = 0;

  _BinarySequenceDeserializer(this._context, this._elementCodec) : _length = _context.i32();

  @override
  bool moveNext() => ++_read <= _length;

  @override
  V element() => _elementCodec.decode(_context);
}

class _BinaryMapDeserializer<V> implements MapDeserializer<V> {
  final BinaryDeserializer _context;
  final Codec<V> _valueCodec;

  final int _length;
  int _read = 0;

  _BinaryMapDeserializer(this._context, this._valueCodec) : _length = _context.i32();

  @override
  bool moveNext() => ++_read <= _length;

  @override
  (String, V) entry() => (_context.string(), _valueCodec.decode(_context));
}

class _BinaryStructDeserializer implements StructDeserializer {
  final BinaryDeserializer _context;
  _BinaryStructDeserializer(this._context);

  @override
  F field<F>(Codec<F> codec) => codec.decode(_context);
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:codec/codec.dart';
import 'package:codec/serializer.dart';

class BinarySerializer implements Serializer<Uint8List> {
  ByteData _buffer = ByteData(2048);
  int _cursor = 0;

  @override
  void i8(int value) {
    _ensureCapacity(1);

    _buffer.setInt8(_cursor, value);
    _cursor++;
  }

  @override
  void u8(int value) {
    _ensureCapacity(1);

    _buffer.setUint8(_cursor, value);
    _cursor++;
  }

  @override
  void i16(int value) {
    _ensureCapacity(2);

    _buffer.setInt16(_cursor, value, Endian.little);
    _cursor += 2;
  }

  @override
  void u16(int value) {
    _ensureCapacity(2);

    _buffer.setUint16(_cursor, value, Endian.little);
    _cursor += 2;
  }

  @override
  void i32(int value) {
    _ensureCapacity(4);

    _buffer.setInt32(_cursor, value, Endian.little);
    _cursor += 4;
  }

  @override
  void u32(int value) {
    _ensureCapacity(4);

    _buffer.setUint32(_cursor, value, Endian.little);
    _cursor += 4;
  }

  @override
  void i64(int value) {
    _ensureCapacity(8);

    _buffer.setInt64(_cursor, value, Endian.little);
    _cursor += 8;
  }

  @override
  void u64(int value) {
    _ensureCapacity(8);

    _buffer.setUint64(_cursor, value, Endian.little);
    _cursor += 8;
  }

  @override
  void f32(double value) {
    _ensureCapacity(4);

    _buffer.setFloat32(_cursor, value, Endian.little);
    _cursor += 4;
  }

  @override
  void f64(double value) {
    _ensureCapacity(8);

    _buffer.setFloat64(_cursor, value, Endian.little);
    _cursor += 8;
  }

  @override
  void string(String value) => _writeBytes(utf8.encode(value));
  @override
  void bytes(Uint8List bytes) => _writeBytes(bytes);

  void _writeBytes(List<int> bytes) {
    i32(bytes.length);

    _ensureCapacity(bytes.length);
    _buffer.buffer.asUint8List().setRange(_cursor, _cursor + bytes.length, bytes);

    _cursor += bytes.length;
  }

  @override
  SequenceSerializer<E> sequence<E>(Codec<E> elementCodec, int length) {
    i32(length);
    return _BinarySequenceSerializer(this, elementCodec);
  }

  @override
  MapSerializer<V> map<V>(Codec<V> valueCodec, int length) {
    i32(length);
    return _BinaryMapSerializer(this, valueCodec);
  }

  @override
  StructSerializer struct() => _BinaryStructSerializer(this);

  @override
  Uint8List get result => Uint8List.view(_buffer.buffer, 0, _cursor);

  void _ensureCapacity(int bytes) {
    if (_cursor + bytes <= _buffer.lengthInBytes) return;

    final expanded = ByteData(_buffer.lengthInBytes * 2);
    expanded.buffer.asUint8List().setRange(0, _buffer.lengthInBytes, _buffer.buffer.asUint8List());

    _buffer = expanded;
  }
}

class _BinarySequenceSerializer<V> implements SequenceSerializer<V> {
  final BinarySerializer _context;
  final Codec<V> _elementCodec;
  _BinarySequenceSerializer(this._context, this._elementCodec);

  @override
  void element(V element) => _elementCodec.encode(_context, element);
  @override
  void end() {}
}

class _BinaryMapSerializer<V> implements MapSerializer<V> {
  final BinarySerializer _context;
  final Codec<V> _valueCodec;
  _BinaryMapSerializer(this._context, this._valueCodec);

  @override
  void entry(String key, V element) {
    _context.string(key);
    _valueCodec.encode(_context, element);
  }

  @override
  void end() {}
}

class _BinaryStructSerializer implements StructSerializer {
  final BinarySerializer _context;
  _BinaryStructSerializer(this._context);

  @override
  void field<F, V extends F>(String name, Codec<F> codec, V value) => codec.encode(_context, value);

  @override
  void end() {}
}

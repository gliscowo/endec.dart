import 'dart:convert';
import 'dart:typed_data';

import 'package:codec/codec.dart';
import 'package:codec/serializer.dart';

Uint8List toBinary<T>(Codec<T> codec, T value) {
  final serializer = BinarySerializer();
  codec.encode(serializer, value);

  return serializer.result;
}

class BinarySerializer implements Serializer<Uint8List> {
  @override
  final bool selfDescribing = false;

  ByteData _buffer = ByteData(2048);
  int _cursor = 0;

  @override
  void boolean(bool value) => u8(value ? 1 : 0);
  @override
  void optional<E>(Codec<E> codec, E? value) {
    if (value != null) {
      boolean(true);
      codec.encode(this, value);
    } else {
      boolean(false);
    }
  }

  @override
  void i8(int value) => _write((idx, value, _) => _buffer.setInt8(idx, value), value, 1);
  @override
  void u8(int value) => _write((idx, value, _) => _buffer.setUint8(idx, value), value, 1);

  @override
  void i16(int value) => _write(_buffer.setInt16, value, 2);
  @override
  void u16(int value) => _write(_buffer.setUint16, value, 2);

  @override
  void i32(int value) => _write(_buffer.setInt32, value, 4);
  @override
  void u32(int value) => _write(_buffer.setUint32, value, 4);

  @override
  void i64(int value) => _write(_buffer.setInt64, value, 8);
  @override
  void u64(int value) => _write(_buffer.setUint64, value, 8);

  @override
  void f32(double value) => _write(_buffer.setFloat32, value, 4);
  @override
  void f64(double value) => _write(_buffer.setFloat64, value, 8);

  void _write<T>(void Function(int idx, T value, Endian) writer, T value, int size) {
    _ensureCapacity(size);

    writer(_cursor, value, Endian.little);
    _cursor += size;
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

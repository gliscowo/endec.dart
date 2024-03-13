import 'dart:convert';
import 'dart:typed_data';

import 'package:endec/endec.dart';

Uint8List toBinary<T, S extends T>(Endec<T> endec, S value) {
  final serializer = BinarySerializer();
  endec.encode(serializer, value);

  return serializer.result;
}

class BinarySerializer implements Serializer {
  @override
  final bool selfDescribing = false;

  ByteData _buffer = ByteData(2048);
  int _cursor = 0;

  @override
  void boolean(bool value) => u8(value ? 1 : 0);
  @override
  void optional<E>(Endec<E> endec, E? value) {
    if (value != null) {
      boolean(true);
      endec.encode(this, value);
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
  SequenceSerializer<E> sequence<E>(Endec<E> elementEndec, int length) {
    i32(length);
    return _BinarySequenceSerializer(this, elementEndec);
  }

  @override
  MapSerializer<V> map<V>(Endec<V> valueEndec, int length) {
    i32(length);
    return _BinaryMapSerializer(this, valueEndec);
  }

  @override
  StructSerializer struct() => _BinaryStructSerializer(this);

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
  final Endec<V> _elementEndec;
  _BinarySequenceSerializer(this._context, this._elementEndec);

  @override
  void element(V element) => _elementEndec.encode(_context, element);
  @override
  void end() {}
}

class _BinaryMapSerializer<V> implements MapSerializer<V> {
  final BinarySerializer _context;
  final Endec<V> _valueEndec;
  _BinaryMapSerializer(this._context, this._valueEndec);

  @override
  void entry(String key, V element) {
    _context.string(key);
    _valueEndec.encode(_context, element);
  }

  @override
  void end() {}
}

class _BinaryStructSerializer implements StructSerializer {
  final BinarySerializer _context;
  _BinaryStructSerializer(this._context);

  @override
  void field<F, V extends F>(String name, Endec<F> endec, V value, {bool optional = false}) =>
      endec.encode(_context, value);

  @override
  void end() {}
}

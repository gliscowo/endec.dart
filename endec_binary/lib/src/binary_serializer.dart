import 'dart:convert';
import 'dart:typed_data';

import 'package:endec/endec.dart';

Uint8List toBinary<T, S extends T>(Endec<T> endec, S value, {SerializationContext ctx = SerializationContext.empty}) {
  final serializer = BinarySerializer();
  endec.encode(ctx, serializer, value);

  return serializer.result;
}

class BinarySerializer implements Serializer {
  ByteData _buffer = ByteData(2048);
  int _cursor = 0;

  @override
  void boolean(SerializationContext ctx, bool value) => u8(ctx, value ? 1 : 0);
  @override
  void optional<E>(SerializationContext ctx, Endec<E> endec, E? value) {
    if (value != null) {
      boolean(ctx, true);
      endec.encode(ctx, this, value);
    } else {
      boolean(ctx, false);
    }
  }

  @override
  void i8(SerializationContext ctx, int value) => _write((idx, value, _) => _buffer.setInt8(idx, value), value, 1);
  @override
  void u8(SerializationContext ctx, int value) => _write((idx, value, _) => _buffer.setUint8(idx, value), value, 1);

  @override
  void i16(SerializationContext ctx, int value) => _write(_buffer.setInt16, value, 2);
  @override
  void u16(SerializationContext ctx, int value) => _write(_buffer.setUint16, value, 2);

  @override
  void i32(SerializationContext ctx, int value) => _write(_buffer.setInt32, value, 4);
  @override
  void u32(SerializationContext ctx, int value) => _write(_buffer.setUint32, value, 4);

  @override
  void i64(SerializationContext ctx, int value) => _write(_buffer.setInt64, value, 8);
  @override
  void u64(SerializationContext ctx, int value) => _write(_buffer.setUint64, value, 8);

  @override
  void f32(SerializationContext ctx, double value) => _write(_buffer.setFloat32, value, 4);
  @override
  void f64(SerializationContext ctx, double value) => _write(_buffer.setFloat64, value, 8);

  void _write<T>(void Function(int idx, T value, Endian) writer, T value, int size) {
    _ensureCapacity(size);

    writer(_cursor, value, Endian.little);
    _cursor += size;
  }

  @override
  void string(SerializationContext ctx, String value) => _writeBytes(ctx, utf8.encode(value));
  @override
  void bytes(SerializationContext ctx, Uint8List bytes) => _writeBytes(ctx, bytes);

  void _writeBytes(SerializationContext ctx, List<int> bytes) {
    i32(ctx, bytes.length);

    _ensureCapacity(bytes.length);
    _buffer.buffer.asUint8List().setRange(_cursor, _cursor + bytes.length, bytes);

    _cursor += bytes.length;
  }

  @override
  SequenceSerializer<E> sequence<E>(SerializationContext ctx, Endec<E> elementEndec, int length) {
    i32(ctx, length);
    return _BinarySequenceSerializer(this, ctx, elementEndec);
  }

  @override
  MapSerializer<V> map<V>(SerializationContext ctx, Endec<V> valueEndec, int length) {
    i32(ctx, length);
    return _BinaryMapSerializer(this, ctx, valueEndec);
  }

  @override
  StructSerializer struct() => _BinaryStructSerializer(this);

  Uint8List get result => Uint8List.view(_buffer.buffer, 0, _cursor);

  void _ensureCapacity(int bytes) {
    final requiredSize = _cursor + bytes;
    var bufferSize = _buffer.lengthInBytes;
    if (requiredSize <= bufferSize) return;

    do {
      bufferSize *= 2;
    } while (requiredSize > bufferSize);

    final expanded = ByteData(bufferSize);
    expanded.buffer.asUint8List().setRange(0, _buffer.lengthInBytes, _buffer.buffer.asUint8List());

    _buffer = expanded;
  }
}

class _BinarySequenceSerializer<V> implements SequenceSerializer<V> {
  final BinarySerializer _serializer;
  final SerializationContext _ctx;
  final Endec<V> _elementEndec;
  _BinarySequenceSerializer(this._serializer, this._ctx, this._elementEndec);

  @override
  void element(V element) => _elementEndec.encode(_ctx, _serializer, element);
  @override
  void end() {}
}

class _BinaryMapSerializer<V> implements MapSerializer<V> {
  final BinarySerializer _serializer;
  final SerializationContext _ctx;
  final Endec<V> _valueEndec;
  _BinaryMapSerializer(this._serializer, this._ctx, this._valueEndec);

  @override
  void entry(String key, V element) {
    _serializer.string(_ctx, key);
    _valueEndec.encode(_ctx, _serializer, element);
  }

  @override
  void end() {}
}

class _BinaryStructSerializer implements StructSerializer {
  final BinarySerializer _serializer;
  _BinaryStructSerializer(this._serializer);

  @override
  void field<F, V extends F>(String name, SerializationContext ctx, Endec<F> endec, V value, {bool mayOmit = false}) =>
      endec.encode(ctx, _serializer, value);

  @override
  void end() {}
}

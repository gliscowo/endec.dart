import 'dart:convert';
import 'dart:typed_data';

import 'package:endec_edm/endec_edm.dart';

EdmElement decodeEdmElement(List<int> data) {
  final reader = EdmReader(ByteData.view(data is Uint8List ? data.buffer : Uint8List.fromList(data).buffer));
  return decodeEdmElementData(reader, EdmElementType.values[reader.u8()]);
}

Uint8List encodeEdmElement(EdmElement element) {
  final writer = EdmWriter();
  writer.u8(element.type.index);
  encodeEdmElementData(writer, element);

  return writer.result;
}

void encodeEdmElementData(EdmWriter writer, EdmElement data) {
  void writeString(String string) {
    final bytes = utf8.encode(string);
    writer.u16(bytes.length);
    writer.writeBytes(bytes);
  }

  switch (data.type) {
    case EdmElementType.u8:
      writer.u8(data.cast());
    case EdmElementType.i8:
      writer.i8(data.cast());
    case EdmElementType.u16:
      writer.u16(data.cast());
    case EdmElementType.i16:
      writer.i16(data.cast());
    case EdmElementType.u32:
      writer.u32(data.cast());
    case EdmElementType.i32:
      writer.i32(data.cast());
    case EdmElementType.u64:
      writer.u64(data.cast());
    case EdmElementType.i64:
      writer.i64(data.cast());
    case EdmElementType.f32:
      writer.f32(data.cast());
    case EdmElementType.f64:
      writer.f64(data.cast());
    case EdmElementType.boolean:
      writer.u8(data.cast<bool>() ? 1 : 0);
    case EdmElementType.string:
      writeString(data.cast());
    case EdmElementType.bytes:
      final bytes = data.cast<Uint8List>();
      writer.u32(bytes.length);
      writer.writeBytes(bytes);
    case EdmElementType.optional:
      if (data case EdmOptional(:var value?)) {
        writer.u8(1);
        writer.u8(value.type.index);
        encodeEdmElementData(writer, value);
      } else {
        writer.u8(0);
      }
    case EdmElementType.sequence:
      final list = data.cast<List<EdmElement>>();
      writer.u32(list.length);
      for (final element in list) {
        writer.u8(element.type.index);
        encodeEdmElementData(writer, element);
      }
    case EdmElementType.map:
      final map = data.cast<Map<String, EdmElement>>();
      writer.u32(map.length);
      for (final MapEntry(:key, :value) in map.entries) {
        writeString(key);
        writer.u8(value.type.index);
        encodeEdmElementData(writer, value);
      }
  }
}

EdmElement decodeEdmElementData(EdmReader reader, EdmElementType type) {
  String readString() {
    final bytes = reader.readBytes(reader.u16());
    return utf8.decode(bytes);
  }

  return switch (type) {
    EdmElementType.u8 => EdmElement.u8(reader.u8()),
    EdmElementType.i8 => EdmElement.i8(reader.i8()),
    EdmElementType.u16 => EdmElement.u16(reader.u16()),
    EdmElementType.i16 => EdmElement.i16(reader.i16()),
    EdmElementType.u32 => EdmElement.u32(reader.u32()),
    EdmElementType.i32 => EdmElement.i32(reader.i32()),
    EdmElementType.u64 => EdmElement.u64(reader.u64()),
    EdmElementType.i64 => EdmElement.i64(reader.i64()),
    EdmElementType.f32 => EdmElement.f32(reader.f32()),
    EdmElementType.f64 => EdmElement.f64(reader.f64()),
    EdmElementType.boolean => EdmElement.boolean(reader.u8() == 0 ? false : true),
    EdmElementType.string => EdmElement.string(readString()),
    EdmElementType.bytes => EdmElement.bytes(reader.readBytes(reader.u32())),
    EdmElementType.optional => () {
        if (reader.u8() == 1) {
          return EdmElement.optional(decodeEdmElementData(reader, EdmElementType.values[reader.u8()]));
        } else {
          return EdmElement.optional(null);
        }
      }(),
    EdmElementType.sequence => () {
        final values = <EdmElement>[];

        final length = reader.u32();
        for (var i = 0; i < length; i++) {
          values.add(decodeEdmElementData(reader, EdmElementType.values[reader.u8()]));
        }

        return EdmElement.sequence(values);
      }(),
    EdmElementType.map => () {
        final values = <String, EdmElement>{};

        final length = reader.u32();
        for (var i = 0; i < length; i++) {
          values[readString()] = decodeEdmElementData(reader, EdmElementType.values[reader.u8()]);
        }

        return EdmElement.map(values);
      }()
  };
}

class EdmWriter {
  ByteData _buffer = ByteData(2048);
  int _cursor = 0;

  void i8(int value) => _write((idx, value, _) => _buffer.setInt8(idx, value), value, 1);
  void u8(int value) => _write((idx, value, _) => _buffer.setUint8(idx, value), value, 1);
  void i16(int value) => _write(_buffer.setInt16, value, 2);
  void u16(int value) => _write(_buffer.setUint16, value, 2);
  void i32(int value) => _write(_buffer.setInt32, value, 4);
  void u32(int value) => _write(_buffer.setUint32, value, 4);
  void i64(int value) => _write(_buffer.setInt64, value, 8);
  void u64(int value) => _write(_buffer.setUint64, value, 8);

  void f32(double value) => _write(_buffer.setFloat32, value, 4);
  void f64(double value) => _write(_buffer.setFloat64, value, 8);

  void _write<T>(void Function(int idx, T value, Endian) writer, T value, int size) {
    _ensureCapacity(size);

    writer(_cursor, value, Endian.little);
    _cursor += size;
  }

  void writeBytes(List<int> bytes) {
    _ensureCapacity(bytes.length);
    _buffer.buffer.asUint8List().setRange(_cursor, _cursor + bytes.length, bytes);
    _cursor += bytes.length;
  }

  Uint8List get result => Uint8List.view(_buffer.buffer, 0, _cursor);

  void _ensureCapacity(int bytes) {
    if (_cursor + bytes <= _buffer.lengthInBytes) return;

    final expanded = ByteData(_buffer.lengthInBytes * 2);
    expanded.buffer.asUint8List().setRange(0, _buffer.lengthInBytes, _buffer.buffer.asUint8List());

    _buffer = expanded;
  }
}

class EdmReader {
  final ByteData _buffer;
  int _cursor = 0;

  EdmReader(this._buffer);

  int i8() => _read((idx, _) => _buffer.getInt8(idx), 1);
  int u8() => _read((idx, _) => _buffer.getUint8(idx), 1);
  int i16() => _read(_buffer.getInt16, 2);
  int u16() => _read(_buffer.getUint16, 2);
  int i32() => _read(_buffer.getInt32, 4);
  int u32() => _read(_buffer.getUint32, 4);
  int i64() => _read(_buffer.getInt64, 8);
  int u64() => _read(_buffer.getUint64, 8);

  double f32() => _read(_buffer.getFloat32, 4);
  double f64() => _read(_buffer.getFloat64, 8);

  T _read<T>(T Function(int idx, Endian) reader, int size) {
    final value = reader(_cursor, Endian.little);
    _cursor += size;

    return value;
  }

  Uint8List readBytes(int length) {
    final list = Uint8List.view(_buffer.buffer, _cursor, length);
    _cursor += length;

    return list;
  }
}

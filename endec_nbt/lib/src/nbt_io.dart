import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'nbt_types.dart';

extension Encode on NbtCompound {
  List<int> encode({bool compress = false}) => nbtToBinary(this, compress: compress);
}

List<int> nbtToBinary(NbtCompound nbt, {bool compress = false}) {
  var output = NbtWriter();
  output.i8(NbtElementType.compound.index);
  output.string("");
  nbt.write(output);

  List<int> result = output.result;
  if (compress) {
    result = gzip.encode(result);
  }

  return result;
}

NbtElement binaryToNbt(List<int> data, {bool compressed = false}) {
  if (compressed) {
    data = gzip.decode(data);
  }

  var input =
      NbtReader(data is Uint8List ? ByteData.view(data.buffer) : ByteData.view(Uint8List.fromList(data).buffer));
  if (input.i8() != NbtElementType.compound.index) {
    throw "Root element of NBT file must a TAG_Compound";
  }

  input.string();
  return input.nbtElement(NbtElementType.compound);
}

class NbtWriter {
  ByteData _buffer = ByteData(2048);
  int _cursor = 0;

  void i8(int value) => _write((idx, value, _) => _buffer.setInt8(idx, value), value, 1);
  void i16(int value) => _write(_buffer.setInt16, value, 2);
  void i32(int value) => _write(_buffer.setInt32, value, 4);
  void i64(int value) => _write(_buffer.setInt64, value, 8);

  void f32(double value) => _write(_buffer.setFloat32, value, 4);
  void f64(double value) => _write(_buffer.setFloat64, value, 8);

  void _write<T>(void Function(int idx, T value, Endian) writer, T value, int size) {
    _ensureCapacity(size);

    writer(_cursor, value, Endian.big);
    _cursor += size;
  }

  void string(String value) {
    var encoded = utf8.encode(value);

    _write(_buffer.setUint16, encoded.length, 2);

    _ensureCapacity(encoded.length);
    _buffer.buffer.asUint8List().setRange(_cursor, _cursor + encoded.length, encoded);
    _cursor += encoded.length;
  }

  void bytes(Int8List bytes) {
    i32(bytes.length);

    _ensureCapacity(bytes.length);
    _buffer.buffer.asInt8List().setRange(_cursor, _cursor + bytes.length, bytes);
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

class NbtReader {
  final ByteData _buffer;
  int _cursor = 0;

  NbtReader(this._buffer);

  NbtElement nbtElement(NbtElementType type) => switch (type) {
        NbtElementType.byte => NbtByte.read(this),
        NbtElementType.short => NbtShort.read(this),
        NbtElementType.int => NbtInt.read(this),
        NbtElementType.long => NbtLong.read(this),
        NbtElementType.float => NbtFloat.read(this),
        NbtElementType.double => NbtDouble.read(this),
        NbtElementType.byteArray => NbtByteArray.read(this),
        NbtElementType.intArray => NbtIntArray.read(this),
        NbtElementType.longArray => NbtLongArray.read(this),
        NbtElementType.string => NbtString.read(this),
        NbtElementType.list => NbtList.read(this),
        NbtElementType.compound => NbtCompound.read(this),
        NbtElementType.end => throw ""
      } as NbtElement;

  int i8() => _read((idx, _) => _buffer.getInt8(idx), 1);
  int i16() => _read(_buffer.getInt16, 2);
  int i32() => _read(_buffer.getInt32, 4);
  int i64() => _read(_buffer.getInt64, 8);

  double f32() => _read(_buffer.getFloat32, 4);
  double f64() => _read(_buffer.getFloat64, 8);

  T _read<T>(T Function(int idx, Endian) reader, int size) {
    final value = reader(_cursor, Endian.big);
    _cursor += size;

    return value;
  }

  String string() => utf8.decode(_readBytes(_read(_buffer.getUint16, 2)));
  Int8List bytes() => _readBytes(i32());

  Int8List _readBytes(int length) {
    final list = Int8List.view(_buffer.buffer, _cursor, length);
    _cursor += length;

    return list;
  }
}

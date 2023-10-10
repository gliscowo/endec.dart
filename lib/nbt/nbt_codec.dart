import 'dart:typed_data';

import '../codec.dart';
import '../deserializer.dart';
import '../serializer.dart';
import 'nbt_io.dart';
import 'nbt_types.dart';

const nbtCodec = NbtCodec._();

class NbtCodec with Codec<NbtElement> {
  const NbtCodec._();

  @override
  void encode<S>(Serializer<S> serializer, NbtElement value) {
    if (serializer.selfDescribing) {
      switch (value) {
        case NbtByte byte:
          serializer.i8(byte.value);
        case NbtShort short:
          serializer.i16(short.value);
        case NbtInt int:
          serializer.i32(int.value);
        case NbtLong long:
          serializer.i64(long.value);
        case NbtFloat float:
          serializer.f32(float.value);
        case NbtDouble double:
          serializer.f64(double.value);
        case NbtByteArray byteArray:
          serializer.bytes(byteArray.value);
        case NbtIntArray intArray:
          Codec.int.listOf().encode(serializer, intArray.value);
        case NbtLongArray longArray:
          Codec.int.listOf().encode(serializer, longArray.value);
        case NbtString string:
          serializer.string(string.value);
        case NbtList list:
          listOf().encode(serializer, list.value);
        case NbtCompound compound:
          mapOf().encode(serializer, compound.value);
        case _:
          throw "Not a valid NBT element: $value";
      }
    } else {
      final writer = NbtWriter()..i8(value.type.index);
      value.write(writer);

      serializer.bytes(writer.result);
    }
  }

  @override
  NbtElement decode<S>(Deserializer<S> deserializer) {
    if (deserializer is SelfDescribingDeserializer<S>) {
      return _dataToNbt(deserializer.any()!);
    } else {
      final reader = NbtReader(ByteData.view(deserializer.bytes().buffer));
      return reader.nbtElement(NbtElementType.byId(reader.i8()));
    }
  }

  NbtElement _dataToNbt(Object value) {
    return switch (value) {
      int value => NbtInt(value),
      double value => NbtDouble(value),
      String value => NbtString(value),
      Uint8List value => NbtByteArray(value),
      List<dynamic> value => NbtList(value.map((e) => _dataToNbt(e)).toList()),
      Map<String, dynamic> value => NbtCompound(value.map((key, value) => MapEntry(key, _dataToNbt(value)))),
      _ => throw "",
    } as NbtElement;
  }
}

import 'dart:typed_data';

import 'package:endec/deserializer.dart';
import 'package:endec/endec.dart';
import 'package:endec/serializer.dart';

import 'nbt_deserializer.dart';
import 'nbt_io.dart';
import 'nbt_serializer.dart';
import 'nbt_types.dart';

const nbtEndec = NbtEndec._();

class NbtEndec with Endec<NbtElement> {
  const NbtEndec._();

  @override
  void encode<S>(Serializer<S> serializer, NbtElement value) {
    if (serializer.selfDescribing) {
      NbtDeserializer(value).any(serializer);
    } else {
      final writer = NbtWriter()..i8(value.type.index);
      value.write(writer);

      serializer.bytes(writer.result);
    }
  }

  @override
  NbtElement decode<S>(Deserializer<S> deserializer) {
    if (deserializer is SelfDescribingDeserializer<S>) {
      final visitor = NbtSerializer();
      deserializer.any(visitor);
      return visitor.result;
    } else {
      final reader = NbtReader(ByteData.view(deserializer.bytes().buffer));
      return reader.nbtElement(NbtElementType.byId(reader.i8()));
    }
  }
}

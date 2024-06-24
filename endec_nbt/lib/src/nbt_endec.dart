import 'dart:typed_data';

import 'package:endec/endec.dart';

import 'nbt_deserializer.dart';
import 'nbt_io.dart';
import 'nbt_serializer.dart';
import 'nbt_types.dart';

const nbtEndec = NbtEndec._();

class NbtEndec with Endec<NbtElement> {
  const NbtEndec._();

  @override
  void encode(SerializationContext ctx, Serializer serializer, NbtElement value) {
    if (serializer.selfDescribing) {
      NbtDeserializer(value).any(ctx, serializer);
    } else {
      final writer = NbtWriter()..i8(value.type.index);
      value.write(writer);

      serializer.bytes(ctx, writer.result);
    }
  }

  @override
  NbtElement decode(SerializationContext ctx, Deserializer deserializer) {
    if (deserializer is SelfDescribingDeserializer) {
      final visitor = NbtSerializer();
      deserializer.any(ctx, visitor);
      return visitor.result;
    } else {
      final reader = NbtReader(ByteData.view(deserializer.bytes(ctx).buffer));
      return reader.nbtElement(NbtElementType.byId(reader.i8()));
    }
  }
}

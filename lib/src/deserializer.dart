import 'dart:typed_data';

import 'endec_base.dart';
import 'serialization_context.dart';
import 'serializer.dart';

abstract interface class Deserializer {
  int i8(SerializationContext ctx);
  int u8(SerializationContext ctx);

  int i16(SerializationContext ctx);
  int u16(SerializationContext ctx);

  int i32(SerializationContext ctx);
  int u32(SerializationContext ctx);

  int i64(SerializationContext ctx);
  int u64(SerializationContext ctx);

  double f32(SerializationContext ctx);
  double f64(SerializationContext ctx);

  bool boolean(SerializationContext ctx);
  String string(SerializationContext ctx);
  Uint8List bytes(SerializationContext ctx);

  E? optional<E>(SerializationContext ctx, Endec<E> endec);

  SequenceDeserializer<E> sequence<E>(SerializationContext ctx, Endec<E> elementEndec);
  MapDeserializer<V> map<V>(SerializationContext ctx, Endec<V> valueEndec);
  StructDeserializer struct(SerializationContext ctx);

  V tryRead<V>(V Function(Deserializer deserializer) reader);
}

abstract interface class SelfDescribingDeserializer extends Deserializer {
  void any(SerializationContext ctx, Serializer visitor);
}

abstract interface class SequenceDeserializer<E> {
  bool moveNext();
  E element();
}

abstract interface class MapDeserializer<V> {
  bool moveNext();
  (String, V) entry();
}

abstract interface class StructDeserializer {
  F field<F>(String name, SerializationContext ctx, Endec<F> endec, {F Function()? defaultValueFactory});
}

import 'dart:typed_data';

import 'package:endec/src/serializer.dart';

import 'endec_base.dart';

abstract interface class Deserializer {
  int i8();
  int u8();

  int i16();
  int u16();

  int i32();
  int u32();

  int i64();
  int u64();

  double f32();
  double f64();

  bool boolean();
  String string();
  Uint8List bytes();
  E? optional<E>(Endec<E> endec);

  SequenceDeserializer<E> sequence<E>(Endec<E> elementEndec);
  MapDeserializer<V> map<V>(Endec<V> valueEndec);
  StructDeserializer struct();

  tryRead<V>(V Function(Deserializer deserializer) reader);
}

abstract interface class SelfDescribingDeserializer extends Deserializer {
  void any(Serializer visitor);
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
  F field<F>(String name, Endec<F> endec);
  F optionalField<F>(String name, Endec<F> endec, F Function() defaultValueFactory);
}

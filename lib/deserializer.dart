import 'dart:typed_data';

import 'endec.dart';

abstract interface class Deserializer<T> {
  bool boolean();
  E? optional<E>(Endec<E> endec);

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

  String string();
  Uint8List bytes();

  SequenceDeserializer<E> sequence<E>(Endec<E> elementEndec);
  MapDeserializer<V> map<V>(Endec<V> valueEndec);
  StructDeserializer struct();
}

abstract interface class SelfDescribingDeserializer<T> extends Deserializer<T> {
  Object? any();
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
  F field<F>(String name, Endec<F> endec, {F? defaultValue});
}

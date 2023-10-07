import 'dart:typed_data';

import 'package:codec/codec.dart';

abstract interface class Serializer<T> {
  void i8(int value);
  void u8(int value);

  void i16(int value);
  void u16(int value);

  void i32(int value);
  void u32(int value);

  void i64(int value);
  void u64(int value);

  void f32(double value);
  void f64(double value);

  void string(String value);
  void bytes(Uint8List bytes);

  SequenceSerializer<E> sequence<E>(Codec<E> elementCodec, int length);
  MapSerializer<V> map<V>(Codec<V> valueCodec, int length);
  StructSerializer struct();

  T get result;
}

abstract interface class SequenceSerializer<E> {
  void element(E element);
  void end();
}

abstract interface class MapSerializer<V> {
  void entry(String key, V value);
  void end();
}

abstract interface class StructSerializer {
  void field<F, V extends F>(String name, Codec<F> codec, V value);
  void end();
}

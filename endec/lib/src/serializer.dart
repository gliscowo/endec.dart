import 'dart:typed_data';

import 'endec_base.dart';
import 'serialization_context.dart';

abstract interface class Serializer {
  void i8(SerializationContext ctx, int value);
  void u8(SerializationContext ctx, int value);

  void i16(SerializationContext ctx, int value);
  void u16(SerializationContext ctx, int value);

  void i32(SerializationContext ctx, int value);
  void u32(SerializationContext ctx, int value);

  void i64(SerializationContext ctx, int value);
  void u64(SerializationContext ctx, int value);

  void f32(SerializationContext ctx, double value);
  void f64(SerializationContext ctx, double value);

  void boolean(SerializationContext ctx, bool value);
  void string(SerializationContext ctx, String value);
  void bytes(SerializationContext ctx, Uint8List bytes);

  void optional<E>(SerializationContext ctx, Endec<E> endec, E? value);

  SequenceSerializer<E> sequence<E>(SerializationContext ctx, Endec<E> elementEndec, int length);
  MapSerializer<V> map<V>(SerializationContext ctx, Endec<V> valueEndec, int length);
  StructSerializer struct();
}

abstract interface class SelfDescribingSerializer extends Serializer {}

abstract interface class SequenceSerializer<E> {
  void element(E element);
  void end();
}

abstract interface class MapSerializer<V> {
  void entry(String key, V value);
  void end();
}

abstract interface class StructSerializer {
  void field<F, V extends F>(String name, SerializationContext ctx, Endec<F> endec, V value, {bool mayOmit = false});
  void end();
}

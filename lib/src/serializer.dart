import 'dart:typed_data';

import 'endec_base.dart';

abstract interface class Serializer {
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

  void boolean(bool value);
  void string(String value);
  void bytes(Uint8List bytes);
  void optional<E>(Endec<E> endec, E? value);

  SequenceSerializer<E> sequence<E>(Endec<E> elementEndec, int length);
  MapSerializer<V> map<V>(Endec<V> valueEndec, int length);
  StructSerializer struct();

  bool get selfDescribing;
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
  void field<F, V extends F>(String name, Endec<F> endec, V value, {bool optional = false});
  void end();
}

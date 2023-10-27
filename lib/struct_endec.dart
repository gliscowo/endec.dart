import 'endec.dart';

extension Field<F> on Endec<F> {
  StructField<S, F> field<S>(String name, F Function(S struct) getter, {F? defaultValue}) =>
      StructField(name, this, getter, defaultValue: defaultValue);
}

StructEndecBuilder<S> structEndec<S>() => StructEndecBuilder();

class StructField<S, F> {
  final String name;
  final Endec<F> endec;
  final F Function(S struct) getter;
  final F? defaultValue;
  StructField(this.name, this.endec, this.getter, {this.defaultValue});
}

class StructEndecBuilder<S> {
  Endec<S> endec1<F1>(
    StructField<S, F1> f1,
    S Function(F1) constructor,
  ) =>
      Endec.of(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.endec, f1.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(state.field(f1.name, f1.endec, defaultValue: f1.defaultValue));
        },
      );

  Endec<S> endec2<F1, F2>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    S Function(F1, F2) constructor,
  ) =>
      Endec.of(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.endec, f1.getter(value))
          ..field(f2.name, f2.endec, f2.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.name, f1.endec, defaultValue: f1.defaultValue),
            state.field(f2.name, f2.endec, defaultValue: f2.defaultValue),
          );
        },
      );

  Endec<S> endec3<F1, F2, F3>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    S Function(F1, F2, F3) constructor,
  ) =>
      Endec.of(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.endec, f1.getter(value))
          ..field(f2.name, f2.endec, f2.getter(value))
          ..field(f3.name, f3.endec, f3.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.name, f1.endec, defaultValue: f1.defaultValue),
            state.field(f2.name, f2.endec, defaultValue: f2.defaultValue),
            state.field(f3.name, f3.endec, defaultValue: f3.defaultValue),
          );
        },
      );

  Endec<S> endec4<F1, F2, F3, F4>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    S Function(F1, F2, F3, F4) constructor,
  ) =>
      Endec.of(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.endec, f1.getter(value))
          ..field(f2.name, f2.endec, f2.getter(value))
          ..field(f3.name, f3.endec, f3.getter(value))
          ..field(f4.name, f4.endec, f4.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.name, f1.endec, defaultValue: f1.defaultValue),
            state.field(f2.name, f2.endec, defaultValue: f2.defaultValue),
            state.field(f3.name, f3.endec, defaultValue: f3.defaultValue),
            state.field(f4.name, f4.endec, defaultValue: f4.defaultValue),
          );
        },
      );

  Endec<S> endec5<F1, F2, F3, F4, F5>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    StructField<S, F5> f5,
    S Function(F1, F2, F3, F4, F5) constructor,
  ) =>
      Endec.of(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.endec, f1.getter(value))
          ..field(f2.name, f2.endec, f2.getter(value))
          ..field(f3.name, f3.endec, f3.getter(value))
          ..field(f4.name, f4.endec, f4.getter(value))
          ..field(f5.name, f5.endec, f5.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.name, f1.endec, defaultValue: f1.defaultValue),
            state.field(f2.name, f2.endec, defaultValue: f2.defaultValue),
            state.field(f3.name, f3.endec, defaultValue: f3.defaultValue),
            state.field(f4.name, f4.endec, defaultValue: f4.defaultValue),
            state.field(f5.name, f5.endec, defaultValue: f5.defaultValue),
          );
        },
      );

  Endec<S> endec6<F1, F2, F3, F4, F5, F6>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    StructField<S, F5> f5,
    StructField<S, F6> f6,
    S Function(F1, F2, F3, F4, F5, F6) constructor,
  ) =>
      Endec.of(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.endec, f1.getter(value))
          ..field(f2.name, f2.endec, f2.getter(value))
          ..field(f3.name, f3.endec, f3.getter(value))
          ..field(f4.name, f4.endec, f4.getter(value))
          ..field(f5.name, f5.endec, f5.getter(value))
          ..field(f6.name, f6.endec, f6.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.name, f1.endec, defaultValue: f1.defaultValue),
            state.field(f2.name, f2.endec, defaultValue: f2.defaultValue),
            state.field(f3.name, f3.endec, defaultValue: f3.defaultValue),
            state.field(f4.name, f4.endec, defaultValue: f4.defaultValue),
            state.field(f5.name, f5.endec, defaultValue: f5.defaultValue),
            state.field(f6.name, f6.endec, defaultValue: f6.defaultValue),
          );
        },
      );

  Endec<S> endec7<F1, F2, F3, F4, F5, F6, F7>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    StructField<S, F5> f5,
    StructField<S, F6> f6,
    StructField<S, F7> f7,
    S Function(F1, F2, F3, F4, F5, F6, F7) constructor,
  ) =>
      Endec.of(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.endec, f1.getter(value))
          ..field(f2.name, f2.endec, f2.getter(value))
          ..field(f3.name, f3.endec, f3.getter(value))
          ..field(f4.name, f4.endec, f4.getter(value))
          ..field(f5.name, f5.endec, f5.getter(value))
          ..field(f6.name, f6.endec, f6.getter(value))
          ..field(f7.name, f7.endec, f7.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.name, f1.endec, defaultValue: f1.defaultValue),
            state.field(f2.name, f2.endec, defaultValue: f2.defaultValue),
            state.field(f3.name, f3.endec, defaultValue: f3.defaultValue),
            state.field(f4.name, f4.endec, defaultValue: f4.defaultValue),
            state.field(f5.name, f5.endec, defaultValue: f5.defaultValue),
            state.field(f6.name, f6.endec, defaultValue: f6.defaultValue),
            state.field(f7.name, f7.endec, defaultValue: f7.defaultValue),
          );
        },
      );

  Endec<S> endec8<F1, F2, F3, F4, F5, F6, F7, F8>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    StructField<S, F5> f5,
    StructField<S, F6> f6,
    StructField<S, F7> f7,
    StructField<S, F8> f8,
    S Function(F1, F2, F3, F4, F5, F6, F7, F8) constructor,
  ) =>
      Endec.of(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.endec, f1.getter(value))
          ..field(f2.name, f2.endec, f2.getter(value))
          ..field(f3.name, f3.endec, f3.getter(value))
          ..field(f4.name, f4.endec, f4.getter(value))
          ..field(f5.name, f5.endec, f5.getter(value))
          ..field(f6.name, f6.endec, f6.getter(value))
          ..field(f7.name, f7.endec, f7.getter(value))
          ..field(f8.name, f8.endec, f8.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.name, f1.endec, defaultValue: f1.defaultValue),
            state.field(f2.name, f2.endec, defaultValue: f2.defaultValue),
            state.field(f3.name, f3.endec, defaultValue: f3.defaultValue),
            state.field(f4.name, f4.endec, defaultValue: f4.defaultValue),
            state.field(f5.name, f5.endec, defaultValue: f5.defaultValue),
            state.field(f6.name, f6.endec, defaultValue: f6.defaultValue),
            state.field(f7.name, f7.endec, defaultValue: f7.defaultValue),
            state.field(f8.name, f8.endec, defaultValue: f8.defaultValue),
          );
        },
      );

  Endec<S> endec9<F1, F2, F3, F4, F5, F6, F7, F8, F9>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    StructField<S, F5> f5,
    StructField<S, F6> f6,
    StructField<S, F7> f7,
    StructField<S, F8> f8,
    StructField<S, F9> f9,
    S Function(F1, F2, F3, F4, F5, F6, F7, F8, F9) constructor,
  ) =>
      Endec.of(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.endec, f1.getter(value))
          ..field(f2.name, f2.endec, f2.getter(value))
          ..field(f3.name, f3.endec, f3.getter(value))
          ..field(f4.name, f4.endec, f4.getter(value))
          ..field(f5.name, f5.endec, f5.getter(value))
          ..field(f6.name, f6.endec, f6.getter(value))
          ..field(f7.name, f7.endec, f7.getter(value))
          ..field(f8.name, f8.endec, f8.getter(value))
          ..field(f9.name, f9.endec, f9.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.name, f1.endec, defaultValue: f1.defaultValue),
            state.field(f2.name, f2.endec, defaultValue: f2.defaultValue),
            state.field(f3.name, f3.endec, defaultValue: f3.defaultValue),
            state.field(f4.name, f4.endec, defaultValue: f4.defaultValue),
            state.field(f5.name, f5.endec, defaultValue: f5.defaultValue),
            state.field(f6.name, f6.endec, defaultValue: f6.defaultValue),
            state.field(f7.name, f7.endec, defaultValue: f7.defaultValue),
            state.field(f8.name, f8.endec, defaultValue: f8.defaultValue),
            state.field(f9.name, f9.endec, defaultValue: f9.defaultValue),
          );
        },
      );

  Endec<S> endec10<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    StructField<S, F5> f5,
    StructField<S, F6> f6,
    StructField<S, F7> f7,
    StructField<S, F8> f8,
    StructField<S, F9> f9,
    StructField<S, F10> f10,
    S Function(F1, F2, F3, F4, F5, F6, F7, F8, F9, F10) constructor,
  ) =>
      Endec.of(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.endec, f1.getter(value))
          ..field(f2.name, f2.endec, f2.getter(value))
          ..field(f3.name, f3.endec, f3.getter(value))
          ..field(f4.name, f4.endec, f4.getter(value))
          ..field(f5.name, f5.endec, f5.getter(value))
          ..field(f6.name, f6.endec, f6.getter(value))
          ..field(f7.name, f7.endec, f7.getter(value))
          ..field(f8.name, f8.endec, f8.getter(value))
          ..field(f9.name, f9.endec, f9.getter(value))
          ..field(f10.name, f10.endec, f10.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.name, f1.endec, defaultValue: f1.defaultValue),
            state.field(f2.name, f2.endec, defaultValue: f2.defaultValue),
            state.field(f3.name, f3.endec, defaultValue: f3.defaultValue),
            state.field(f4.name, f4.endec, defaultValue: f4.defaultValue),
            state.field(f5.name, f5.endec, defaultValue: f5.defaultValue),
            state.field(f6.name, f6.endec, defaultValue: f6.defaultValue),
            state.field(f7.name, f7.endec, defaultValue: f7.defaultValue),
            state.field(f8.name, f8.endec, defaultValue: f8.defaultValue),
            state.field(f9.name, f9.endec, defaultValue: f9.defaultValue),
            state.field(f10.name, f10.endec, defaultValue: f10.defaultValue),
          );
        },
      );

  Endec<S> endec11<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    StructField<S, F5> f5,
    StructField<S, F6> f6,
    StructField<S, F7> f7,
    StructField<S, F8> f8,
    StructField<S, F9> f9,
    StructField<S, F10> f10,
    StructField<S, F11> f11,
    S Function(F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11) constructor,
  ) =>
      Endec.of(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.endec, f1.getter(value))
          ..field(f2.name, f2.endec, f2.getter(value))
          ..field(f3.name, f3.endec, f3.getter(value))
          ..field(f4.name, f4.endec, f4.getter(value))
          ..field(f5.name, f5.endec, f5.getter(value))
          ..field(f6.name, f6.endec, f6.getter(value))
          ..field(f7.name, f7.endec, f7.getter(value))
          ..field(f8.name, f8.endec, f8.getter(value))
          ..field(f9.name, f9.endec, f9.getter(value))
          ..field(f10.name, f10.endec, f10.getter(value))
          ..field(f11.name, f11.endec, f11.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.name, f1.endec, defaultValue: f1.defaultValue),
            state.field(f2.name, f2.endec, defaultValue: f2.defaultValue),
            state.field(f3.name, f3.endec, defaultValue: f3.defaultValue),
            state.field(f4.name, f4.endec, defaultValue: f4.defaultValue),
            state.field(f5.name, f5.endec, defaultValue: f5.defaultValue),
            state.field(f6.name, f6.endec, defaultValue: f6.defaultValue),
            state.field(f7.name, f7.endec, defaultValue: f7.defaultValue),
            state.field(f8.name, f8.endec, defaultValue: f8.defaultValue),
            state.field(f9.name, f9.endec, defaultValue: f9.defaultValue),
            state.field(f10.name, f10.endec, defaultValue: f10.defaultValue),
            state.field(f11.name, f11.endec, defaultValue: f11.defaultValue),
          );
        },
      );

  Endec<S> endec12<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    StructField<S, F5> f5,
    StructField<S, F6> f6,
    StructField<S, F7> f7,
    StructField<S, F8> f8,
    StructField<S, F9> f9,
    StructField<S, F10> f10,
    StructField<S, F11> f11,
    StructField<S, F12> f12,
    S Function(F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12) constructor,
  ) =>
      Endec.of(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.endec, f1.getter(value))
          ..field(f2.name, f2.endec, f2.getter(value))
          ..field(f3.name, f3.endec, f3.getter(value))
          ..field(f4.name, f4.endec, f4.getter(value))
          ..field(f5.name, f5.endec, f5.getter(value))
          ..field(f6.name, f6.endec, f6.getter(value))
          ..field(f7.name, f7.endec, f7.getter(value))
          ..field(f8.name, f8.endec, f8.getter(value))
          ..field(f9.name, f9.endec, f9.getter(value))
          ..field(f10.name, f10.endec, f10.getter(value))
          ..field(f11.name, f11.endec, f11.getter(value))
          ..field(f12.name, f12.endec, f12.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.name, f1.endec, defaultValue: f1.defaultValue),
            state.field(f2.name, f2.endec, defaultValue: f2.defaultValue),
            state.field(f3.name, f3.endec, defaultValue: f3.defaultValue),
            state.field(f4.name, f4.endec, defaultValue: f4.defaultValue),
            state.field(f5.name, f5.endec, defaultValue: f5.defaultValue),
            state.field(f6.name, f6.endec, defaultValue: f6.defaultValue),
            state.field(f7.name, f7.endec, defaultValue: f7.defaultValue),
            state.field(f8.name, f8.endec, defaultValue: f8.defaultValue),
            state.field(f9.name, f9.endec, defaultValue: f9.defaultValue),
            state.field(f10.name, f10.endec, defaultValue: f10.defaultValue),
            state.field(f11.name, f11.endec, defaultValue: f11.defaultValue),
            state.field(f12.name, f12.endec, defaultValue: f12.defaultValue),
          );
        },
      );

  Endec<S> endec13<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    StructField<S, F5> f5,
    StructField<S, F6> f6,
    StructField<S, F7> f7,
    StructField<S, F8> f8,
    StructField<S, F9> f9,
    StructField<S, F10> f10,
    StructField<S, F11> f11,
    StructField<S, F12> f12,
    StructField<S, F13> f13,
    S Function(F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13) constructor,
  ) =>
      Endec.of(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.endec, f1.getter(value))
          ..field(f2.name, f2.endec, f2.getter(value))
          ..field(f3.name, f3.endec, f3.getter(value))
          ..field(f4.name, f4.endec, f4.getter(value))
          ..field(f5.name, f5.endec, f5.getter(value))
          ..field(f6.name, f6.endec, f6.getter(value))
          ..field(f7.name, f7.endec, f7.getter(value))
          ..field(f8.name, f8.endec, f8.getter(value))
          ..field(f9.name, f9.endec, f9.getter(value))
          ..field(f10.name, f10.endec, f10.getter(value))
          ..field(f11.name, f11.endec, f11.getter(value))
          ..field(f12.name, f12.endec, f12.getter(value))
          ..field(f13.name, f13.endec, f13.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.name, f1.endec, defaultValue: f1.defaultValue),
            state.field(f2.name, f2.endec, defaultValue: f2.defaultValue),
            state.field(f3.name, f3.endec, defaultValue: f3.defaultValue),
            state.field(f4.name, f4.endec, defaultValue: f4.defaultValue),
            state.field(f5.name, f5.endec, defaultValue: f5.defaultValue),
            state.field(f6.name, f6.endec, defaultValue: f6.defaultValue),
            state.field(f7.name, f7.endec, defaultValue: f7.defaultValue),
            state.field(f8.name, f8.endec, defaultValue: f8.defaultValue),
            state.field(f9.name, f9.endec, defaultValue: f9.defaultValue),
            state.field(f10.name, f10.endec, defaultValue: f10.defaultValue),
            state.field(f11.name, f11.endec, defaultValue: f11.defaultValue),
            state.field(f12.name, f12.endec, defaultValue: f12.defaultValue),
            state.field(f13.name, f13.endec, defaultValue: f13.defaultValue),
          );
        },
      );

  Endec<S> endec14<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    StructField<S, F5> f5,
    StructField<S, F6> f6,
    StructField<S, F7> f7,
    StructField<S, F8> f8,
    StructField<S, F9> f9,
    StructField<S, F10> f10,
    StructField<S, F11> f11,
    StructField<S, F12> f12,
    StructField<S, F13> f13,
    StructField<S, F14> f14,
    S Function(F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14) constructor,
  ) =>
      Endec.of(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.endec, f1.getter(value))
          ..field(f2.name, f2.endec, f2.getter(value))
          ..field(f3.name, f3.endec, f3.getter(value))
          ..field(f4.name, f4.endec, f4.getter(value))
          ..field(f5.name, f5.endec, f5.getter(value))
          ..field(f6.name, f6.endec, f6.getter(value))
          ..field(f7.name, f7.endec, f7.getter(value))
          ..field(f8.name, f8.endec, f8.getter(value))
          ..field(f9.name, f9.endec, f9.getter(value))
          ..field(f10.name, f10.endec, f10.getter(value))
          ..field(f11.name, f11.endec, f11.getter(value))
          ..field(f12.name, f12.endec, f12.getter(value))
          ..field(f13.name, f13.endec, f13.getter(value))
          ..field(f14.name, f14.endec, f14.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.name, f1.endec, defaultValue: f1.defaultValue),
            state.field(f2.name, f2.endec, defaultValue: f2.defaultValue),
            state.field(f3.name, f3.endec, defaultValue: f3.defaultValue),
            state.field(f4.name, f4.endec, defaultValue: f4.defaultValue),
            state.field(f5.name, f5.endec, defaultValue: f5.defaultValue),
            state.field(f6.name, f6.endec, defaultValue: f6.defaultValue),
            state.field(f7.name, f7.endec, defaultValue: f7.defaultValue),
            state.field(f8.name, f8.endec, defaultValue: f8.defaultValue),
            state.field(f9.name, f9.endec, defaultValue: f9.defaultValue),
            state.field(f10.name, f10.endec, defaultValue: f10.defaultValue),
            state.field(f11.name, f11.endec, defaultValue: f11.defaultValue),
            state.field(f12.name, f12.endec, defaultValue: f12.defaultValue),
            state.field(f13.name, f13.endec, defaultValue: f13.defaultValue),
            state.field(f14.name, f14.endec, defaultValue: f14.defaultValue),
          );
        },
      );

  Endec<S> endec15<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    StructField<S, F5> f5,
    StructField<S, F6> f6,
    StructField<S, F7> f7,
    StructField<S, F8> f8,
    StructField<S, F9> f9,
    StructField<S, F10> f10,
    StructField<S, F11> f11,
    StructField<S, F12> f12,
    StructField<S, F13> f13,
    StructField<S, F14> f14,
    StructField<S, F15> f15,
    S Function(F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15) constructor,
  ) =>
      Endec.of(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.endec, f1.getter(value))
          ..field(f2.name, f2.endec, f2.getter(value))
          ..field(f3.name, f3.endec, f3.getter(value))
          ..field(f4.name, f4.endec, f4.getter(value))
          ..field(f5.name, f5.endec, f5.getter(value))
          ..field(f6.name, f6.endec, f6.getter(value))
          ..field(f7.name, f7.endec, f7.getter(value))
          ..field(f8.name, f8.endec, f8.getter(value))
          ..field(f9.name, f9.endec, f9.getter(value))
          ..field(f10.name, f10.endec, f10.getter(value))
          ..field(f11.name, f11.endec, f11.getter(value))
          ..field(f12.name, f12.endec, f12.getter(value))
          ..field(f13.name, f13.endec, f13.getter(value))
          ..field(f14.name, f14.endec, f14.getter(value))
          ..field(f15.name, f15.endec, f15.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.name, f1.endec, defaultValue: f1.defaultValue),
            state.field(f2.name, f2.endec, defaultValue: f2.defaultValue),
            state.field(f3.name, f3.endec, defaultValue: f3.defaultValue),
            state.field(f4.name, f4.endec, defaultValue: f4.defaultValue),
            state.field(f5.name, f5.endec, defaultValue: f5.defaultValue),
            state.field(f6.name, f6.endec, defaultValue: f6.defaultValue),
            state.field(f7.name, f7.endec, defaultValue: f7.defaultValue),
            state.field(f8.name, f8.endec, defaultValue: f8.defaultValue),
            state.field(f9.name, f9.endec, defaultValue: f9.defaultValue),
            state.field(f10.name, f10.endec, defaultValue: f10.defaultValue),
            state.field(f11.name, f11.endec, defaultValue: f11.defaultValue),
            state.field(f12.name, f12.endec, defaultValue: f12.defaultValue),
            state.field(f13.name, f13.endec, defaultValue: f13.defaultValue),
            state.field(f14.name, f14.endec, defaultValue: f14.defaultValue),
            state.field(f15.name, f15.endec, defaultValue: f15.defaultValue),
          );
        },
      );

  Endec<S> endec16<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15, F16>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    StructField<S, F5> f5,
    StructField<S, F6> f6,
    StructField<S, F7> f7,
    StructField<S, F8> f8,
    StructField<S, F9> f9,
    StructField<S, F10> f10,
    StructField<S, F11> f11,
    StructField<S, F12> f12,
    StructField<S, F13> f13,
    StructField<S, F14> f14,
    StructField<S, F15> f15,
    StructField<S, F16> f16,
    S Function(F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15, F16) constructor,
  ) =>
      Endec.of(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.endec, f1.getter(value))
          ..field(f2.name, f2.endec, f2.getter(value))
          ..field(f3.name, f3.endec, f3.getter(value))
          ..field(f4.name, f4.endec, f4.getter(value))
          ..field(f5.name, f5.endec, f5.getter(value))
          ..field(f6.name, f6.endec, f6.getter(value))
          ..field(f7.name, f7.endec, f7.getter(value))
          ..field(f8.name, f8.endec, f8.getter(value))
          ..field(f9.name, f9.endec, f9.getter(value))
          ..field(f10.name, f10.endec, f10.getter(value))
          ..field(f11.name, f11.endec, f11.getter(value))
          ..field(f12.name, f12.endec, f12.getter(value))
          ..field(f13.name, f13.endec, f13.getter(value))
          ..field(f14.name, f14.endec, f14.getter(value))
          ..field(f15.name, f15.endec, f15.getter(value))
          ..field(f16.name, f16.endec, f16.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.name, f1.endec, defaultValue: f1.defaultValue),
            state.field(f2.name, f2.endec, defaultValue: f2.defaultValue),
            state.field(f3.name, f3.endec, defaultValue: f3.defaultValue),
            state.field(f4.name, f4.endec, defaultValue: f4.defaultValue),
            state.field(f5.name, f5.endec, defaultValue: f5.defaultValue),
            state.field(f6.name, f6.endec, defaultValue: f6.defaultValue),
            state.field(f7.name, f7.endec, defaultValue: f7.defaultValue),
            state.field(f8.name, f8.endec, defaultValue: f8.defaultValue),
            state.field(f9.name, f9.endec, defaultValue: f9.defaultValue),
            state.field(f10.name, f10.endec, defaultValue: f10.defaultValue),
            state.field(f11.name, f11.endec, defaultValue: f11.defaultValue),
            state.field(f12.name, f12.endec, defaultValue: f12.defaultValue),
            state.field(f13.name, f13.endec, defaultValue: f13.defaultValue),
            state.field(f14.name, f14.endec, defaultValue: f14.defaultValue),
            state.field(f15.name, f15.endec, defaultValue: f15.defaultValue),
            state.field(f16.name, f16.endec, defaultValue: f16.defaultValue),
          );
        },
      );
}

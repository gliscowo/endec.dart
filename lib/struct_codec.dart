import 'package:codec/codec.dart';
import 'package:codec/deserializer.dart';
import 'package:codec/serializer.dart';

extension Field<F> on Codec<F> {
  StructField<S, F> field<S>(String name, F Function(S struct) getter) => StructField(name, this, getter);
  StructField<S, F> optionalField<S>(String name, F defaultValue, F Function(S struct) getter) =>
      OptionalStructField(name, this, getter, defaultValue);
}

StructCodecBuilder<S> structCodec<S>() => StructCodecBuilder();

class StructField<S, F> {
  final String name;
  final Codec<F> codec;
  final F Function(S struct) getter;
  StructField(this.name, this.codec, this.getter);
}

class OptionalStructField<S, F> extends StructField<S, F> {
  final F defaultValue;
  OptionalStructField(super.name, super.codec, super.getter, this.defaultValue);
}

typedef _Encoder<T> = void Function(Serializer serializer, T value);
typedef _Decoder<T> = T Function(Deserializer deserializer);

class StructCodec<S> {
  final _Encoder<S> _encoder;
  final _Decoder<S> _unnamedDecoder;
  final _Decoder<S> _namedDecoder;

  StructCodec(this._encoder, this._unnamedDecoder, this._namedDecoder);

  Codec<S> get named => SimpleCodec(_encoder, _namedDecoder);
  Codec<S> get unnamed => SimpleCodec(_encoder, _unnamedDecoder);
}

class StructCodecBuilder<S> {
  StructCodec<S> codec1<F1>(
    StructField<S, F1> f1,
    S Function(F1) constructor,
  ) =>
      StructCodec(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.codec, f1.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(state.field(f1.codec));
        },
        (deserializer) {
          var state = deserializer.struct();
          if (state is! NamedStructDeserializer) throw "Named struct codecs require a named struct deserializer";

          return constructor(state.namedField(f1.name, f1.codec) ?? (f1 as OptionalStructField).defaultValue);
        },
      );

  StructCodec<S> codec2<F1, F2>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    S Function(F1, F2) constructor,
  ) =>
      StructCodec(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.codec, f1.getter(value))
          ..field(f2.name, f2.codec, f2.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.codec),
            state.field(f2.codec),
          );
        },
        (deserializer) {
          var state = deserializer.struct();
          if (state is! NamedStructDeserializer) throw "Named struct codecs require a named struct deserializer";

          return constructor(state.namedField(f1.name, f1.codec) ?? (f1 as OptionalStructField).defaultValue,
              state.namedField(f2.name, f2.codec) ?? (f2 as OptionalStructField).defaultValue);
        },
      );

  StructCodec<S> codec3<F1, F2, F3>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    S Function(F1, F2, F3) constructor,
  ) =>
      StructCodec(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.codec, f1.getter(value))
          ..field(f2.name, f2.codec, f2.getter(value))
          ..field(f3.name, f3.codec, f3.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.codec),
            state.field(f2.codec),
            state.field(f3.codec),
          );
        },
        (deserializer) {
          var state = deserializer.struct();
          if (state is! NamedStructDeserializer) throw "Named struct codecs require a named struct deserializer";

          return constructor(
              state.namedField(f1.name, f1.codec) ?? (f1 as OptionalStructField).defaultValue,
              state.namedField(f2.name, f2.codec) ?? (f2 as OptionalStructField).defaultValue,
              state.namedField(f3.name, f3.codec) ?? (f3 as OptionalStructField).defaultValue);
        },
      );

  StructCodec<S> codec4<F1, F2, F3, F4>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    S Function(F1, F2, F3, F4) constructor,
  ) =>
      StructCodec(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.codec, f1.getter(value))
          ..field(f2.name, f2.codec, f2.getter(value))
          ..field(f3.name, f3.codec, f3.getter(value))
          ..field(f4.name, f4.codec, f4.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.codec),
            state.field(f2.codec),
            state.field(f3.codec),
            state.field(f4.codec),
          );
        },
        (deserializer) {
          var state = deserializer.struct();
          if (state is! NamedStructDeserializer) throw "Named struct codecs require a named struct deserializer";

          return constructor(
              state.namedField(f1.name, f1.codec) ?? (f1 as OptionalStructField).defaultValue,
              state.namedField(f2.name, f2.codec) ?? (f2 as OptionalStructField).defaultValue,
              state.namedField(f3.name, f3.codec) ?? (f3 as OptionalStructField).defaultValue,
              state.namedField(f4.name, f4.codec) ?? (f4 as OptionalStructField).defaultValue);
        },
      );

  StructCodec<S> codec5<F1, F2, F3, F4, F5>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    StructField<S, F5> f5,
    S Function(F1, F2, F3, F4, F5) constructor,
  ) =>
      StructCodec(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.codec, f1.getter(value))
          ..field(f2.name, f2.codec, f2.getter(value))
          ..field(f3.name, f3.codec, f3.getter(value))
          ..field(f4.name, f4.codec, f4.getter(value))
          ..field(f5.name, f5.codec, f5.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.codec),
            state.field(f2.codec),
            state.field(f3.codec),
            state.field(f4.codec),
            state.field(f5.codec),
          );
        },
        (deserializer) {
          var state = deserializer.struct();
          if (state is! NamedStructDeserializer) throw "Named struct codecs require a named struct deserializer";

          return constructor(
              state.namedField(f1.name, f1.codec) ?? (f1 as OptionalStructField).defaultValue,
              state.namedField(f2.name, f2.codec) ?? (f2 as OptionalStructField).defaultValue,
              state.namedField(f3.name, f3.codec) ?? (f3 as OptionalStructField).defaultValue,
              state.namedField(f4.name, f4.codec) ?? (f4 as OptionalStructField).defaultValue,
              state.namedField(f5.name, f5.codec) ?? (f5 as OptionalStructField).defaultValue);
        },
      );

  StructCodec<S> codec6<F1, F2, F3, F4, F5, F6>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    StructField<S, F5> f5,
    StructField<S, F6> f6,
    S Function(F1, F2, F3, F4, F5, F6) constructor,
  ) =>
      StructCodec(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.codec, f1.getter(value))
          ..field(f2.name, f2.codec, f2.getter(value))
          ..field(f3.name, f3.codec, f3.getter(value))
          ..field(f4.name, f4.codec, f4.getter(value))
          ..field(f5.name, f5.codec, f5.getter(value))
          ..field(f6.name, f6.codec, f6.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.codec),
            state.field(f2.codec),
            state.field(f3.codec),
            state.field(f4.codec),
            state.field(f5.codec),
            state.field(f6.codec),
          );
        },
        (deserializer) {
          var state = deserializer.struct();
          if (state is! NamedStructDeserializer) throw "Named struct codecs require a named struct deserializer";

          return constructor(
              state.namedField(f1.name, f1.codec) ?? (f1 as OptionalStructField).defaultValue,
              state.namedField(f2.name, f2.codec) ?? (f2 as OptionalStructField).defaultValue,
              state.namedField(f3.name, f3.codec) ?? (f3 as OptionalStructField).defaultValue,
              state.namedField(f4.name, f4.codec) ?? (f4 as OptionalStructField).defaultValue,
              state.namedField(f5.name, f5.codec) ?? (f5 as OptionalStructField).defaultValue,
              state.namedField(f6.name, f6.codec) ?? (f6 as OptionalStructField).defaultValue);
        },
      );

  StructCodec<S> codec7<F1, F2, F3, F4, F5, F6, F7>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    StructField<S, F5> f5,
    StructField<S, F6> f6,
    StructField<S, F7> f7,
    S Function(F1, F2, F3, F4, F5, F6, F7) constructor,
  ) =>
      StructCodec(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.codec, f1.getter(value))
          ..field(f2.name, f2.codec, f2.getter(value))
          ..field(f3.name, f3.codec, f3.getter(value))
          ..field(f4.name, f4.codec, f4.getter(value))
          ..field(f5.name, f5.codec, f5.getter(value))
          ..field(f6.name, f6.codec, f6.getter(value))
          ..field(f7.name, f7.codec, f7.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.codec),
            state.field(f2.codec),
            state.field(f3.codec),
            state.field(f4.codec),
            state.field(f5.codec),
            state.field(f6.codec),
            state.field(f7.codec),
          );
        },
        (deserializer) {
          var state = deserializer.struct();
          if (state is! NamedStructDeserializer) throw "Named struct codecs require a named struct deserializer";

          return constructor(
              state.namedField(f1.name, f1.codec) ?? (f1 as OptionalStructField).defaultValue,
              state.namedField(f2.name, f2.codec) ?? (f2 as OptionalStructField).defaultValue,
              state.namedField(f3.name, f3.codec) ?? (f3 as OptionalStructField).defaultValue,
              state.namedField(f4.name, f4.codec) ?? (f4 as OptionalStructField).defaultValue,
              state.namedField(f5.name, f5.codec) ?? (f5 as OptionalStructField).defaultValue,
              state.namedField(f6.name, f6.codec) ?? (f6 as OptionalStructField).defaultValue,
              state.namedField(f7.name, f7.codec) ?? (f7 as OptionalStructField).defaultValue);
        },
      );

  StructCodec<S> codec8<F1, F2, F3, F4, F5, F6, F7, F8>(
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
      StructCodec(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.codec, f1.getter(value))
          ..field(f2.name, f2.codec, f2.getter(value))
          ..field(f3.name, f3.codec, f3.getter(value))
          ..field(f4.name, f4.codec, f4.getter(value))
          ..field(f5.name, f5.codec, f5.getter(value))
          ..field(f6.name, f6.codec, f6.getter(value))
          ..field(f7.name, f7.codec, f7.getter(value))
          ..field(f8.name, f8.codec, f8.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.codec),
            state.field(f2.codec),
            state.field(f3.codec),
            state.field(f4.codec),
            state.field(f5.codec),
            state.field(f6.codec),
            state.field(f7.codec),
            state.field(f8.codec),
          );
        },
        (deserializer) {
          var state = deserializer.struct();
          if (state is! NamedStructDeserializer) throw "Named struct codecs require a named struct deserializer";

          return constructor(
              state.namedField(f1.name, f1.codec) ?? (f1 as OptionalStructField).defaultValue,
              state.namedField(f2.name, f2.codec) ?? (f2 as OptionalStructField).defaultValue,
              state.namedField(f3.name, f3.codec) ?? (f3 as OptionalStructField).defaultValue,
              state.namedField(f4.name, f4.codec) ?? (f4 as OptionalStructField).defaultValue,
              state.namedField(f5.name, f5.codec) ?? (f5 as OptionalStructField).defaultValue,
              state.namedField(f6.name, f6.codec) ?? (f6 as OptionalStructField).defaultValue,
              state.namedField(f7.name, f7.codec) ?? (f7 as OptionalStructField).defaultValue,
              state.namedField(f8.name, f8.codec) ?? (f8 as OptionalStructField).defaultValue);
        },
      );

  StructCodec<S> codec9<F1, F2, F3, F4, F5, F6, F7, F8, F9>(
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
      StructCodec(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.codec, f1.getter(value))
          ..field(f2.name, f2.codec, f2.getter(value))
          ..field(f3.name, f3.codec, f3.getter(value))
          ..field(f4.name, f4.codec, f4.getter(value))
          ..field(f5.name, f5.codec, f5.getter(value))
          ..field(f6.name, f6.codec, f6.getter(value))
          ..field(f7.name, f7.codec, f7.getter(value))
          ..field(f8.name, f8.codec, f8.getter(value))
          ..field(f9.name, f9.codec, f9.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.codec),
            state.field(f2.codec),
            state.field(f3.codec),
            state.field(f4.codec),
            state.field(f5.codec),
            state.field(f6.codec),
            state.field(f7.codec),
            state.field(f8.codec),
            state.field(f9.codec),
          );
        },
        (deserializer) {
          var state = deserializer.struct();
          if (state is! NamedStructDeserializer) throw "Named struct codecs require a named struct deserializer";

          return constructor(
              state.namedField(f1.name, f1.codec) ?? (f1 as OptionalStructField).defaultValue,
              state.namedField(f2.name, f2.codec) ?? (f2 as OptionalStructField).defaultValue,
              state.namedField(f3.name, f3.codec) ?? (f3 as OptionalStructField).defaultValue,
              state.namedField(f4.name, f4.codec) ?? (f4 as OptionalStructField).defaultValue,
              state.namedField(f5.name, f5.codec) ?? (f5 as OptionalStructField).defaultValue,
              state.namedField(f6.name, f6.codec) ?? (f6 as OptionalStructField).defaultValue,
              state.namedField(f7.name, f7.codec) ?? (f7 as OptionalStructField).defaultValue,
              state.namedField(f8.name, f8.codec) ?? (f8 as OptionalStructField).defaultValue,
              state.namedField(f9.name, f9.codec) ?? (f9 as OptionalStructField).defaultValue);
        },
      );

  StructCodec<S> codec10<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10>(
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
      StructCodec(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.codec, f1.getter(value))
          ..field(f2.name, f2.codec, f2.getter(value))
          ..field(f3.name, f3.codec, f3.getter(value))
          ..field(f4.name, f4.codec, f4.getter(value))
          ..field(f5.name, f5.codec, f5.getter(value))
          ..field(f6.name, f6.codec, f6.getter(value))
          ..field(f7.name, f7.codec, f7.getter(value))
          ..field(f8.name, f8.codec, f8.getter(value))
          ..field(f9.name, f9.codec, f9.getter(value))
          ..field(f10.name, f10.codec, f10.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.codec),
            state.field(f2.codec),
            state.field(f3.codec),
            state.field(f4.codec),
            state.field(f5.codec),
            state.field(f6.codec),
            state.field(f7.codec),
            state.field(f8.codec),
            state.field(f9.codec),
            state.field(f10.codec),
          );
        },
        (deserializer) {
          var state = deserializer.struct();
          if (state is! NamedStructDeserializer) throw "Named struct codecs require a named struct deserializer";

          return constructor(
              state.namedField(f1.name, f1.codec) ?? (f1 as OptionalStructField).defaultValue,
              state.namedField(f2.name, f2.codec) ?? (f2 as OptionalStructField).defaultValue,
              state.namedField(f3.name, f3.codec) ?? (f3 as OptionalStructField).defaultValue,
              state.namedField(f4.name, f4.codec) ?? (f4 as OptionalStructField).defaultValue,
              state.namedField(f5.name, f5.codec) ?? (f5 as OptionalStructField).defaultValue,
              state.namedField(f6.name, f6.codec) ?? (f6 as OptionalStructField).defaultValue,
              state.namedField(f7.name, f7.codec) ?? (f7 as OptionalStructField).defaultValue,
              state.namedField(f8.name, f8.codec) ?? (f8 as OptionalStructField).defaultValue,
              state.namedField(f9.name, f9.codec) ?? (f9 as OptionalStructField).defaultValue,
              state.namedField(f10.name, f10.codec) ?? (f10 as OptionalStructField).defaultValue);
        },
      );

  StructCodec<S> codec11<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11>(
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
      StructCodec(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.codec, f1.getter(value))
          ..field(f2.name, f2.codec, f2.getter(value))
          ..field(f3.name, f3.codec, f3.getter(value))
          ..field(f4.name, f4.codec, f4.getter(value))
          ..field(f5.name, f5.codec, f5.getter(value))
          ..field(f6.name, f6.codec, f6.getter(value))
          ..field(f7.name, f7.codec, f7.getter(value))
          ..field(f8.name, f8.codec, f8.getter(value))
          ..field(f9.name, f9.codec, f9.getter(value))
          ..field(f10.name, f10.codec, f10.getter(value))
          ..field(f11.name, f11.codec, f11.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.codec),
            state.field(f2.codec),
            state.field(f3.codec),
            state.field(f4.codec),
            state.field(f5.codec),
            state.field(f6.codec),
            state.field(f7.codec),
            state.field(f8.codec),
            state.field(f9.codec),
            state.field(f10.codec),
            state.field(f11.codec),
          );
        },
        (deserializer) {
          var state = deserializer.struct();
          if (state is! NamedStructDeserializer) throw "Named struct codecs require a named struct deserializer";

          return constructor(
              state.namedField(f1.name, f1.codec) ?? (f1 as OptionalStructField).defaultValue,
              state.namedField(f2.name, f2.codec) ?? (f2 as OptionalStructField).defaultValue,
              state.namedField(f3.name, f3.codec) ?? (f3 as OptionalStructField).defaultValue,
              state.namedField(f4.name, f4.codec) ?? (f4 as OptionalStructField).defaultValue,
              state.namedField(f5.name, f5.codec) ?? (f5 as OptionalStructField).defaultValue,
              state.namedField(f6.name, f6.codec) ?? (f6 as OptionalStructField).defaultValue,
              state.namedField(f7.name, f7.codec) ?? (f7 as OptionalStructField).defaultValue,
              state.namedField(f8.name, f8.codec) ?? (f8 as OptionalStructField).defaultValue,
              state.namedField(f9.name, f9.codec) ?? (f9 as OptionalStructField).defaultValue,
              state.namedField(f10.name, f10.codec) ?? (f10 as OptionalStructField).defaultValue,
              state.namedField(f11.name, f11.codec) ?? (f11 as OptionalStructField).defaultValue);
        },
      );

  StructCodec<S> codec12<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12>(
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
      StructCodec(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.codec, f1.getter(value))
          ..field(f2.name, f2.codec, f2.getter(value))
          ..field(f3.name, f3.codec, f3.getter(value))
          ..field(f4.name, f4.codec, f4.getter(value))
          ..field(f5.name, f5.codec, f5.getter(value))
          ..field(f6.name, f6.codec, f6.getter(value))
          ..field(f7.name, f7.codec, f7.getter(value))
          ..field(f8.name, f8.codec, f8.getter(value))
          ..field(f9.name, f9.codec, f9.getter(value))
          ..field(f10.name, f10.codec, f10.getter(value))
          ..field(f11.name, f11.codec, f11.getter(value))
          ..field(f12.name, f12.codec, f12.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.codec),
            state.field(f2.codec),
            state.field(f3.codec),
            state.field(f4.codec),
            state.field(f5.codec),
            state.field(f6.codec),
            state.field(f7.codec),
            state.field(f8.codec),
            state.field(f9.codec),
            state.field(f10.codec),
            state.field(f11.codec),
            state.field(f12.codec),
          );
        },
        (deserializer) {
          var state = deserializer.struct();
          if (state is! NamedStructDeserializer) throw "Named struct codecs require a named struct deserializer";

          return constructor(
              state.namedField(f1.name, f1.codec) ?? (f1 as OptionalStructField).defaultValue,
              state.namedField(f2.name, f2.codec) ?? (f2 as OptionalStructField).defaultValue,
              state.namedField(f3.name, f3.codec) ?? (f3 as OptionalStructField).defaultValue,
              state.namedField(f4.name, f4.codec) ?? (f4 as OptionalStructField).defaultValue,
              state.namedField(f5.name, f5.codec) ?? (f5 as OptionalStructField).defaultValue,
              state.namedField(f6.name, f6.codec) ?? (f6 as OptionalStructField).defaultValue,
              state.namedField(f7.name, f7.codec) ?? (f7 as OptionalStructField).defaultValue,
              state.namedField(f8.name, f8.codec) ?? (f8 as OptionalStructField).defaultValue,
              state.namedField(f9.name, f9.codec) ?? (f9 as OptionalStructField).defaultValue,
              state.namedField(f10.name, f10.codec) ?? (f10 as OptionalStructField).defaultValue,
              state.namedField(f11.name, f11.codec) ?? (f11 as OptionalStructField).defaultValue,
              state.namedField(f12.name, f12.codec) ?? (f12 as OptionalStructField).defaultValue);
        },
      );

  StructCodec<S> codec13<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13>(
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
      StructCodec(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.codec, f1.getter(value))
          ..field(f2.name, f2.codec, f2.getter(value))
          ..field(f3.name, f3.codec, f3.getter(value))
          ..field(f4.name, f4.codec, f4.getter(value))
          ..field(f5.name, f5.codec, f5.getter(value))
          ..field(f6.name, f6.codec, f6.getter(value))
          ..field(f7.name, f7.codec, f7.getter(value))
          ..field(f8.name, f8.codec, f8.getter(value))
          ..field(f9.name, f9.codec, f9.getter(value))
          ..field(f10.name, f10.codec, f10.getter(value))
          ..field(f11.name, f11.codec, f11.getter(value))
          ..field(f12.name, f12.codec, f12.getter(value))
          ..field(f13.name, f13.codec, f13.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.codec),
            state.field(f2.codec),
            state.field(f3.codec),
            state.field(f4.codec),
            state.field(f5.codec),
            state.field(f6.codec),
            state.field(f7.codec),
            state.field(f8.codec),
            state.field(f9.codec),
            state.field(f10.codec),
            state.field(f11.codec),
            state.field(f12.codec),
            state.field(f13.codec),
          );
        },
        (deserializer) {
          var state = deserializer.struct();
          if (state is! NamedStructDeserializer) throw "Named struct codecs require a named struct deserializer";

          return constructor(
              state.namedField(f1.name, f1.codec) ?? (f1 as OptionalStructField).defaultValue,
              state.namedField(f2.name, f2.codec) ?? (f2 as OptionalStructField).defaultValue,
              state.namedField(f3.name, f3.codec) ?? (f3 as OptionalStructField).defaultValue,
              state.namedField(f4.name, f4.codec) ?? (f4 as OptionalStructField).defaultValue,
              state.namedField(f5.name, f5.codec) ?? (f5 as OptionalStructField).defaultValue,
              state.namedField(f6.name, f6.codec) ?? (f6 as OptionalStructField).defaultValue,
              state.namedField(f7.name, f7.codec) ?? (f7 as OptionalStructField).defaultValue,
              state.namedField(f8.name, f8.codec) ?? (f8 as OptionalStructField).defaultValue,
              state.namedField(f9.name, f9.codec) ?? (f9 as OptionalStructField).defaultValue,
              state.namedField(f10.name, f10.codec) ?? (f10 as OptionalStructField).defaultValue,
              state.namedField(f11.name, f11.codec) ?? (f11 as OptionalStructField).defaultValue,
              state.namedField(f12.name, f12.codec) ?? (f12 as OptionalStructField).defaultValue,
              state.namedField(f13.name, f13.codec) ?? (f13 as OptionalStructField).defaultValue);
        },
      );

  StructCodec<S> codec14<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14>(
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
      StructCodec(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.codec, f1.getter(value))
          ..field(f2.name, f2.codec, f2.getter(value))
          ..field(f3.name, f3.codec, f3.getter(value))
          ..field(f4.name, f4.codec, f4.getter(value))
          ..field(f5.name, f5.codec, f5.getter(value))
          ..field(f6.name, f6.codec, f6.getter(value))
          ..field(f7.name, f7.codec, f7.getter(value))
          ..field(f8.name, f8.codec, f8.getter(value))
          ..field(f9.name, f9.codec, f9.getter(value))
          ..field(f10.name, f10.codec, f10.getter(value))
          ..field(f11.name, f11.codec, f11.getter(value))
          ..field(f12.name, f12.codec, f12.getter(value))
          ..field(f13.name, f13.codec, f13.getter(value))
          ..field(f14.name, f14.codec, f14.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.codec),
            state.field(f2.codec),
            state.field(f3.codec),
            state.field(f4.codec),
            state.field(f5.codec),
            state.field(f6.codec),
            state.field(f7.codec),
            state.field(f8.codec),
            state.field(f9.codec),
            state.field(f10.codec),
            state.field(f11.codec),
            state.field(f12.codec),
            state.field(f13.codec),
            state.field(f14.codec),
          );
        },
        (deserializer) {
          var state = deserializer.struct();
          if (state is! NamedStructDeserializer) throw "Named struct codecs require a named struct deserializer";

          return constructor(
              state.namedField(f1.name, f1.codec) ?? (f1 as OptionalStructField).defaultValue,
              state.namedField(f2.name, f2.codec) ?? (f2 as OptionalStructField).defaultValue,
              state.namedField(f3.name, f3.codec) ?? (f3 as OptionalStructField).defaultValue,
              state.namedField(f4.name, f4.codec) ?? (f4 as OptionalStructField).defaultValue,
              state.namedField(f5.name, f5.codec) ?? (f5 as OptionalStructField).defaultValue,
              state.namedField(f6.name, f6.codec) ?? (f6 as OptionalStructField).defaultValue,
              state.namedField(f7.name, f7.codec) ?? (f7 as OptionalStructField).defaultValue,
              state.namedField(f8.name, f8.codec) ?? (f8 as OptionalStructField).defaultValue,
              state.namedField(f9.name, f9.codec) ?? (f9 as OptionalStructField).defaultValue,
              state.namedField(f10.name, f10.codec) ?? (f10 as OptionalStructField).defaultValue,
              state.namedField(f11.name, f11.codec) ?? (f11 as OptionalStructField).defaultValue,
              state.namedField(f12.name, f12.codec) ?? (f12 as OptionalStructField).defaultValue,
              state.namedField(f13.name, f13.codec) ?? (f13 as OptionalStructField).defaultValue,
              state.namedField(f14.name, f14.codec) ?? (f14 as OptionalStructField).defaultValue);
        },
      );

  StructCodec<S> codec15<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15>(
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
      StructCodec(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.codec, f1.getter(value))
          ..field(f2.name, f2.codec, f2.getter(value))
          ..field(f3.name, f3.codec, f3.getter(value))
          ..field(f4.name, f4.codec, f4.getter(value))
          ..field(f5.name, f5.codec, f5.getter(value))
          ..field(f6.name, f6.codec, f6.getter(value))
          ..field(f7.name, f7.codec, f7.getter(value))
          ..field(f8.name, f8.codec, f8.getter(value))
          ..field(f9.name, f9.codec, f9.getter(value))
          ..field(f10.name, f10.codec, f10.getter(value))
          ..field(f11.name, f11.codec, f11.getter(value))
          ..field(f12.name, f12.codec, f12.getter(value))
          ..field(f13.name, f13.codec, f13.getter(value))
          ..field(f14.name, f14.codec, f14.getter(value))
          ..field(f15.name, f15.codec, f15.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.codec),
            state.field(f2.codec),
            state.field(f3.codec),
            state.field(f4.codec),
            state.field(f5.codec),
            state.field(f6.codec),
            state.field(f7.codec),
            state.field(f8.codec),
            state.field(f9.codec),
            state.field(f10.codec),
            state.field(f11.codec),
            state.field(f12.codec),
            state.field(f13.codec),
            state.field(f14.codec),
            state.field(f15.codec),
          );
        },
        (deserializer) {
          var state = deserializer.struct();
          if (state is! NamedStructDeserializer) throw "Named struct codecs require a named struct deserializer";

          return constructor(
              state.namedField(f1.name, f1.codec) ?? (f1 as OptionalStructField).defaultValue,
              state.namedField(f2.name, f2.codec) ?? (f2 as OptionalStructField).defaultValue,
              state.namedField(f3.name, f3.codec) ?? (f3 as OptionalStructField).defaultValue,
              state.namedField(f4.name, f4.codec) ?? (f4 as OptionalStructField).defaultValue,
              state.namedField(f5.name, f5.codec) ?? (f5 as OptionalStructField).defaultValue,
              state.namedField(f6.name, f6.codec) ?? (f6 as OptionalStructField).defaultValue,
              state.namedField(f7.name, f7.codec) ?? (f7 as OptionalStructField).defaultValue,
              state.namedField(f8.name, f8.codec) ?? (f8 as OptionalStructField).defaultValue,
              state.namedField(f9.name, f9.codec) ?? (f9 as OptionalStructField).defaultValue,
              state.namedField(f10.name, f10.codec) ?? (f10 as OptionalStructField).defaultValue,
              state.namedField(f11.name, f11.codec) ?? (f11 as OptionalStructField).defaultValue,
              state.namedField(f12.name, f12.codec) ?? (f12 as OptionalStructField).defaultValue,
              state.namedField(f13.name, f13.codec) ?? (f13 as OptionalStructField).defaultValue,
              state.namedField(f14.name, f14.codec) ?? (f14 as OptionalStructField).defaultValue,
              state.namedField(f15.name, f15.codec) ?? (f15 as OptionalStructField).defaultValue);
        },
      );

  StructCodec<S> codec16<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15, F16>(
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
      StructCodec(
        (serializer, value) => serializer.struct()
          ..field(f1.name, f1.codec, f1.getter(value))
          ..field(f2.name, f2.codec, f2.getter(value))
          ..field(f3.name, f3.codec, f3.getter(value))
          ..field(f4.name, f4.codec, f4.getter(value))
          ..field(f5.name, f5.codec, f5.getter(value))
          ..field(f6.name, f6.codec, f6.getter(value))
          ..field(f7.name, f7.codec, f7.getter(value))
          ..field(f8.name, f8.codec, f8.getter(value))
          ..field(f9.name, f9.codec, f9.getter(value))
          ..field(f10.name, f10.codec, f10.getter(value))
          ..field(f11.name, f11.codec, f11.getter(value))
          ..field(f12.name, f12.codec, f12.getter(value))
          ..field(f13.name, f13.codec, f13.getter(value))
          ..field(f14.name, f14.codec, f14.getter(value))
          ..field(f15.name, f15.codec, f15.getter(value))
          ..field(f16.name, f16.codec, f16.getter(value))
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(
            state.field(f1.codec),
            state.field(f2.codec),
            state.field(f3.codec),
            state.field(f4.codec),
            state.field(f5.codec),
            state.field(f6.codec),
            state.field(f7.codec),
            state.field(f8.codec),
            state.field(f9.codec),
            state.field(f10.codec),
            state.field(f11.codec),
            state.field(f12.codec),
            state.field(f13.codec),
            state.field(f14.codec),
            state.field(f15.codec),
            state.field(f16.codec),
          );
        },
        (deserializer) {
          var state = deserializer.struct();
          if (state is! NamedStructDeserializer) throw "Named struct codecs require a named struct deserializer";

          return constructor(
              state.namedField(f1.name, f1.codec) ?? (f1 as OptionalStructField).defaultValue,
              state.namedField(f2.name, f2.codec) ?? (f2 as OptionalStructField).defaultValue,
              state.namedField(f3.name, f3.codec) ?? (f3 as OptionalStructField).defaultValue,
              state.namedField(f4.name, f4.codec) ?? (f4 as OptionalStructField).defaultValue,
              state.namedField(f5.name, f5.codec) ?? (f5 as OptionalStructField).defaultValue,
              state.namedField(f6.name, f6.codec) ?? (f6 as OptionalStructField).defaultValue,
              state.namedField(f7.name, f7.codec) ?? (f7 as OptionalStructField).defaultValue,
              state.namedField(f8.name, f8.codec) ?? (f8 as OptionalStructField).defaultValue,
              state.namedField(f9.name, f9.codec) ?? (f9 as OptionalStructField).defaultValue,
              state.namedField(f10.name, f10.codec) ?? (f10 as OptionalStructField).defaultValue,
              state.namedField(f11.name, f11.codec) ?? (f11 as OptionalStructField).defaultValue,
              state.namedField(f12.name, f12.codec) ?? (f12 as OptionalStructField).defaultValue,
              state.namedField(f13.name, f13.codec) ?? (f13 as OptionalStructField).defaultValue,
              state.namedField(f14.name, f14.codec) ?? (f14 as OptionalStructField).defaultValue,
              state.namedField(f15.name, f15.codec) ?? (f15 as OptionalStructField).defaultValue,
              state.namedField(f16.name, f16.codec) ?? (f16 as OptionalStructField).defaultValue);
        },
      );
}

import 'package:endec/endec.dart';

import 'serialization_context.dart';

extension Field<F> on Endec<F> {
  StructField<S, F> fieldOf<S>(String name, F Function(S struct) getter, {F Function()? defaultValueFactory}) =>
      defaultValueFactory != null
          ? StructField.optional(name, this, getter, defaultValueFactory)
          : StructField.required(name, this, getter);
}

typedef StructEncoder<S> = void Function(
    SerializationContext ctx, Serializer serializer, StructSerializer struct, S value);
typedef StructDecoder<S> = S Function(SerializationContext ctx, Deserializer deserializer, StructDeserializer struct);

abstract class StructEndec<S> with Endec<S> {
  StructEndec();
  factory StructEndec.of(StructEncoder<S> encoder, StructDecoder<S> decoder) => _SimpleStructEndec(encoder, decoder);

  void encodeStruct(SerializationContext ctx, Serializer serializer, StructSerializer struct, S value);
  S decodeStruct(SerializationContext ctx, Deserializer deserializer, StructDeserializer struct);

  @override
  void encode(SerializationContext ctx, Serializer serializer, S value) {
    final struct = serializer.struct();
    encodeStruct(ctx, serializer, struct, value);
    struct.end();
  }

  @override
  S decode(SerializationContext ctx, Deserializer deserializer) =>
      decodeStruct(ctx, deserializer, deserializer.struct());

  @override
  StructEndec<U> xmap<U>(U Function(S self) to, S Function(U other) from) => _XmapStructEndec(this, to, from);

  StructField<M, S> flatFieldOf<M>(S Function(M struct) getter) => StructField.flat(this, getter);
  StructField<M, S> flatInheritedFieldOf<M extends S>() => StructField.flat(this, (struct) => struct);
}

class _SimpleStructEndec<S> extends StructEndec<S> {
  final StructEncoder<S> _encoder;
  final StructDecoder<S> _decoder;
  _SimpleStructEndec(this._encoder, this._decoder);

  @override
  void encodeStruct(SerializationContext ctx, Serializer serializer, StructSerializer struct, S value) =>
      _encoder(ctx, serializer, struct, value);

  @override
  S decodeStruct(SerializationContext ctx, Deserializer deserializer, StructDeserializer struct) =>
      _decoder(ctx, deserializer, struct);
}

class _XmapStructEndec<T, U> extends StructEndec<U> {
  final StructEndec<T> _sourceEndec;
  final U Function(T) _to;
  final T Function(U) _from;

  _XmapStructEndec(this._sourceEndec, this._to, this._from);

  @override
  void encodeStruct(SerializationContext ctx, Serializer serializer, StructSerializer struct, U value) =>
      _sourceEndec.encodeStruct(ctx, serializer, struct, _from(value));

  @override
  U decodeStruct(SerializationContext ctx, Deserializer deserializer, StructDeserializer struct) =>
      _to(_sourceEndec.decodeStruct(ctx, deserializer, struct));
}

abstract final class StructField<S, F> {
  factory StructField.required(
    String name,
    Endec<F> endec,
    F Function(S struct) getter,
  ) = _GenericStructField.required;

  factory StructField.optional(
    String name,
    Endec<F> endec,
    F Function(S struct) getter,
    F Function() defaultValueFactory,
  ) = _GenericStructField.optional;

  factory StructField.flat(
    StructEndec<F> endec,
    F Function(S struct) getter,
  ) = _FlatStructField.new;

  void encodeField(SerializationContext ctx, Serializer serializer, StructSerializer struct, S value);
  F decodeField(SerializationContext ctx, Deserializer deserializer, StructDeserializer struct);
}

final class _GenericStructField<S, F> implements StructField<S, F> {
  final String _name;
  final Endec<F> _endec;
  final F Function(S) _getter;
  final F Function()? _defaultValueFactory;

  _GenericStructField.required(this._name, this._endec, this._getter) : _defaultValueFactory = null;
  _GenericStructField.optional(this._name, this._endec, this._getter, this._defaultValueFactory);

  @override
  void encodeField(SerializationContext ctx, Serializer serializer, StructSerializer struct, S instance) =>
      struct.field(_name, ctx, _endec, _getter(instance), optional: _defaultValueFactory != null);

  @override
  F decodeField(SerializationContext ctx, Deserializer deserializer, StructDeserializer struct) =>
      _defaultValueFactory != null
          ? struct.optionalField(_name, ctx, _endec, _defaultValueFactory!)
          : struct.field(_name, ctx, _endec);
}

final class _FlatStructField<S, F> implements StructField<S, F> {
  final StructEndec<F> _endec;
  final F Function(S) _getter;

  _FlatStructField(this._endec, this._getter);

  @override
  void encodeField(SerializationContext ctx, Serializer serializer, StructSerializer struct, S instance) =>
      _endec.encodeStruct(ctx, serializer, struct, _getter(instance));

  @override
  F decodeField(SerializationContext ctx, Deserializer deserializer, StructDeserializer struct) =>
      _endec.decodeStruct(ctx, deserializer, struct);
}

StructEndecBuilder<S> structEndec<S>() => StructEndecBuilder._();

class StructEndecBuilder<S> {
  StructEndecBuilder._();

  StructEndec<S> with1Field<F1>(
    StructField<S, F1> f1,
    S Function(F1) constructor,
  ) =>
      StructEndec.of(
        (ctx, serializer, struct, value) => f1.encodeField(ctx, serializer, struct, value),
        (ctx, deserializer, struct) => constructor(f1.decodeField(ctx, deserializer, struct)),
      );

  StructEndec<S> with2Fields<F1, F2>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    S Function(F1, F2) constructor,
  ) =>
      StructEndec.of((ctx, serializer, struct, value) {
        f1.encodeField(ctx, serializer, struct, value);
        f2.encodeField(ctx, serializer, struct, value);
      }, (ctx, deserializer, struct) {
        return constructor(
          f1.decodeField(ctx, deserializer, struct),
          f2.decodeField(ctx, deserializer, struct),
        );
      });

  StructEndec<S> with3Fields<F1, F2, F3>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    S Function(F1, F2, F3) constructor,
  ) =>
      StructEndec.of((ctx, serializer, struct, value) {
        f1.encodeField(ctx, serializer, struct, value);
        f2.encodeField(ctx, serializer, struct, value);
        f3.encodeField(ctx, serializer, struct, value);
      }, (ctx, deserializer, struct) {
        return constructor(
          f1.decodeField(ctx, deserializer, struct),
          f2.decodeField(ctx, deserializer, struct),
          f3.decodeField(ctx, deserializer, struct),
        );
      });

  StructEndec<S> with4Fields<F1, F2, F3, F4>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    S Function(F1, F2, F3, F4) constructor,
  ) =>
      StructEndec.of((ctx, serializer, struct, value) {
        f1.encodeField(ctx, serializer, struct, value);
        f2.encodeField(ctx, serializer, struct, value);
        f3.encodeField(ctx, serializer, struct, value);
        f4.encodeField(ctx, serializer, struct, value);
      }, (ctx, deserializer, struct) {
        return constructor(
          f1.decodeField(ctx, deserializer, struct),
          f2.decodeField(ctx, deserializer, struct),
          f3.decodeField(ctx, deserializer, struct),
          f4.decodeField(ctx, deserializer, struct),
        );
      });

  StructEndec<S> with5Fields<F1, F2, F3, F4, F5>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    StructField<S, F5> f5,
    S Function(F1, F2, F3, F4, F5) constructor,
  ) =>
      StructEndec.of((ctx, serializer, struct, value) {
        f1.encodeField(ctx, serializer, struct, value);
        f2.encodeField(ctx, serializer, struct, value);
        f3.encodeField(ctx, serializer, struct, value);
        f4.encodeField(ctx, serializer, struct, value);
        f5.encodeField(ctx, serializer, struct, value);
      }, (ctx, deserializer, struct) {
        return constructor(
          f1.decodeField(ctx, deserializer, struct),
          f2.decodeField(ctx, deserializer, struct),
          f3.decodeField(ctx, deserializer, struct),
          f4.decodeField(ctx, deserializer, struct),
          f5.decodeField(ctx, deserializer, struct),
        );
      });

  StructEndec<S> with6Fields<F1, F2, F3, F4, F5, F6>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    StructField<S, F5> f5,
    StructField<S, F6> f6,
    S Function(F1, F2, F3, F4, F5, F6) constructor,
  ) =>
      StructEndec.of((ctx, serializer, struct, value) {
        f1.encodeField(ctx, serializer, struct, value);
        f2.encodeField(ctx, serializer, struct, value);
        f3.encodeField(ctx, serializer, struct, value);
        f4.encodeField(ctx, serializer, struct, value);
        f5.encodeField(ctx, serializer, struct, value);
        f6.encodeField(ctx, serializer, struct, value);
      }, (ctx, deserializer, struct) {
        return constructor(
          f1.decodeField(ctx, deserializer, struct),
          f2.decodeField(ctx, deserializer, struct),
          f3.decodeField(ctx, deserializer, struct),
          f4.decodeField(ctx, deserializer, struct),
          f5.decodeField(ctx, deserializer, struct),
          f6.decodeField(ctx, deserializer, struct),
        );
      });

  StructEndec<S> with7Fields<F1, F2, F3, F4, F5, F6, F7>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    StructField<S, F5> f5,
    StructField<S, F6> f6,
    StructField<S, F7> f7,
    S Function(F1, F2, F3, F4, F5, F6, F7) constructor,
  ) =>
      StructEndec.of((ctx, serializer, struct, value) {
        f1.encodeField(ctx, serializer, struct, value);
        f2.encodeField(ctx, serializer, struct, value);
        f3.encodeField(ctx, serializer, struct, value);
        f4.encodeField(ctx, serializer, struct, value);
        f5.encodeField(ctx, serializer, struct, value);
        f6.encodeField(ctx, serializer, struct, value);
        f7.encodeField(ctx, serializer, struct, value);
      }, (ctx, deserializer, struct) {
        return constructor(
          f1.decodeField(ctx, deserializer, struct),
          f2.decodeField(ctx, deserializer, struct),
          f3.decodeField(ctx, deserializer, struct),
          f4.decodeField(ctx, deserializer, struct),
          f5.decodeField(ctx, deserializer, struct),
          f6.decodeField(ctx, deserializer, struct),
          f7.decodeField(ctx, deserializer, struct),
        );
      });

  StructEndec<S> with8Fields<F1, F2, F3, F4, F5, F6, F7, F8>(
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
      StructEndec.of((ctx, serializer, struct, value) {
        f1.encodeField(ctx, serializer, struct, value);
        f2.encodeField(ctx, serializer, struct, value);
        f3.encodeField(ctx, serializer, struct, value);
        f4.encodeField(ctx, serializer, struct, value);
        f5.encodeField(ctx, serializer, struct, value);
        f6.encodeField(ctx, serializer, struct, value);
        f7.encodeField(ctx, serializer, struct, value);
        f8.encodeField(ctx, serializer, struct, value);
      }, (ctx, deserializer, struct) {
        return constructor(
          f1.decodeField(ctx, deserializer, struct),
          f2.decodeField(ctx, deserializer, struct),
          f3.decodeField(ctx, deserializer, struct),
          f4.decodeField(ctx, deserializer, struct),
          f5.decodeField(ctx, deserializer, struct),
          f6.decodeField(ctx, deserializer, struct),
          f7.decodeField(ctx, deserializer, struct),
          f8.decodeField(ctx, deserializer, struct),
        );
      });

  StructEndec<S> with9Fields<F1, F2, F3, F4, F5, F6, F7, F8, F9>(
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
      StructEndec.of((ctx, serializer, struct, value) {
        f1.encodeField(ctx, serializer, struct, value);
        f2.encodeField(ctx, serializer, struct, value);
        f3.encodeField(ctx, serializer, struct, value);
        f4.encodeField(ctx, serializer, struct, value);
        f5.encodeField(ctx, serializer, struct, value);
        f6.encodeField(ctx, serializer, struct, value);
        f7.encodeField(ctx, serializer, struct, value);
        f8.encodeField(ctx, serializer, struct, value);
        f9.encodeField(ctx, serializer, struct, value);
      }, (ctx, deserializer, struct) {
        return constructor(
          f1.decodeField(ctx, deserializer, struct),
          f2.decodeField(ctx, deserializer, struct),
          f3.decodeField(ctx, deserializer, struct),
          f4.decodeField(ctx, deserializer, struct),
          f5.decodeField(ctx, deserializer, struct),
          f6.decodeField(ctx, deserializer, struct),
          f7.decodeField(ctx, deserializer, struct),
          f8.decodeField(ctx, deserializer, struct),
          f9.decodeField(ctx, deserializer, struct),
        );
      });

  StructEndec<S> with10Fields<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10>(
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
      StructEndec.of((ctx, serializer, struct, value) {
        f1.encodeField(ctx, serializer, struct, value);
        f2.encodeField(ctx, serializer, struct, value);
        f3.encodeField(ctx, serializer, struct, value);
        f4.encodeField(ctx, serializer, struct, value);
        f5.encodeField(ctx, serializer, struct, value);
        f6.encodeField(ctx, serializer, struct, value);
        f7.encodeField(ctx, serializer, struct, value);
        f8.encodeField(ctx, serializer, struct, value);
        f9.encodeField(ctx, serializer, struct, value);
        f10.encodeField(ctx, serializer, struct, value);
      }, (ctx, deserializer, struct) {
        return constructor(
          f1.decodeField(ctx, deserializer, struct),
          f2.decodeField(ctx, deserializer, struct),
          f3.decodeField(ctx, deserializer, struct),
          f4.decodeField(ctx, deserializer, struct),
          f5.decodeField(ctx, deserializer, struct),
          f6.decodeField(ctx, deserializer, struct),
          f7.decodeField(ctx, deserializer, struct),
          f8.decodeField(ctx, deserializer, struct),
          f9.decodeField(ctx, deserializer, struct),
          f10.decodeField(ctx, deserializer, struct),
        );
      });

  StructEndec<S> with11Fields<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11>(
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
      StructEndec.of((ctx, serializer, struct, value) {
        f1.encodeField(ctx, serializer, struct, value);
        f2.encodeField(ctx, serializer, struct, value);
        f3.encodeField(ctx, serializer, struct, value);
        f4.encodeField(ctx, serializer, struct, value);
        f5.encodeField(ctx, serializer, struct, value);
        f6.encodeField(ctx, serializer, struct, value);
        f7.encodeField(ctx, serializer, struct, value);
        f8.encodeField(ctx, serializer, struct, value);
        f9.encodeField(ctx, serializer, struct, value);
        f10.encodeField(ctx, serializer, struct, value);
        f11.encodeField(ctx, serializer, struct, value);
      }, (ctx, deserializer, struct) {
        return constructor(
          f1.decodeField(ctx, deserializer, struct),
          f2.decodeField(ctx, deserializer, struct),
          f3.decodeField(ctx, deserializer, struct),
          f4.decodeField(ctx, deserializer, struct),
          f5.decodeField(ctx, deserializer, struct),
          f6.decodeField(ctx, deserializer, struct),
          f7.decodeField(ctx, deserializer, struct),
          f8.decodeField(ctx, deserializer, struct),
          f9.decodeField(ctx, deserializer, struct),
          f10.decodeField(ctx, deserializer, struct),
          f11.decodeField(ctx, deserializer, struct),
        );
      });

  StructEndec<S> with12Fields<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12>(
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
      StructEndec.of((ctx, serializer, struct, value) {
        f1.encodeField(ctx, serializer, struct, value);
        f2.encodeField(ctx, serializer, struct, value);
        f3.encodeField(ctx, serializer, struct, value);
        f4.encodeField(ctx, serializer, struct, value);
        f5.encodeField(ctx, serializer, struct, value);
        f6.encodeField(ctx, serializer, struct, value);
        f7.encodeField(ctx, serializer, struct, value);
        f8.encodeField(ctx, serializer, struct, value);
        f9.encodeField(ctx, serializer, struct, value);
        f10.encodeField(ctx, serializer, struct, value);
        f11.encodeField(ctx, serializer, struct, value);
        f12.encodeField(ctx, serializer, struct, value);
      }, (ctx, deserializer, struct) {
        return constructor(
          f1.decodeField(ctx, deserializer, struct),
          f2.decodeField(ctx, deserializer, struct),
          f3.decodeField(ctx, deserializer, struct),
          f4.decodeField(ctx, deserializer, struct),
          f5.decodeField(ctx, deserializer, struct),
          f6.decodeField(ctx, deserializer, struct),
          f7.decodeField(ctx, deserializer, struct),
          f8.decodeField(ctx, deserializer, struct),
          f9.decodeField(ctx, deserializer, struct),
          f10.decodeField(ctx, deserializer, struct),
          f11.decodeField(ctx, deserializer, struct),
          f12.decodeField(ctx, deserializer, struct),
        );
      });

  StructEndec<S> with13Fields<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13>(
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
      StructEndec.of((ctx, serializer, struct, value) {
        f1.encodeField(ctx, serializer, struct, value);
        f2.encodeField(ctx, serializer, struct, value);
        f3.encodeField(ctx, serializer, struct, value);
        f4.encodeField(ctx, serializer, struct, value);
        f5.encodeField(ctx, serializer, struct, value);
        f6.encodeField(ctx, serializer, struct, value);
        f7.encodeField(ctx, serializer, struct, value);
        f8.encodeField(ctx, serializer, struct, value);
        f9.encodeField(ctx, serializer, struct, value);
        f10.encodeField(ctx, serializer, struct, value);
        f11.encodeField(ctx, serializer, struct, value);
        f12.encodeField(ctx, serializer, struct, value);
        f13.encodeField(ctx, serializer, struct, value);
      }, (ctx, deserializer, struct) {
        return constructor(
          f1.decodeField(ctx, deserializer, struct),
          f2.decodeField(ctx, deserializer, struct),
          f3.decodeField(ctx, deserializer, struct),
          f4.decodeField(ctx, deserializer, struct),
          f5.decodeField(ctx, deserializer, struct),
          f6.decodeField(ctx, deserializer, struct),
          f7.decodeField(ctx, deserializer, struct),
          f8.decodeField(ctx, deserializer, struct),
          f9.decodeField(ctx, deserializer, struct),
          f10.decodeField(ctx, deserializer, struct),
          f11.decodeField(ctx, deserializer, struct),
          f12.decodeField(ctx, deserializer, struct),
          f13.decodeField(ctx, deserializer, struct),
        );
      });

  StructEndec<S> with14Fields<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14>(
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
      StructEndec.of((ctx, serializer, struct, value) {
        f1.encodeField(ctx, serializer, struct, value);
        f2.encodeField(ctx, serializer, struct, value);
        f3.encodeField(ctx, serializer, struct, value);
        f4.encodeField(ctx, serializer, struct, value);
        f5.encodeField(ctx, serializer, struct, value);
        f6.encodeField(ctx, serializer, struct, value);
        f7.encodeField(ctx, serializer, struct, value);
        f8.encodeField(ctx, serializer, struct, value);
        f9.encodeField(ctx, serializer, struct, value);
        f10.encodeField(ctx, serializer, struct, value);
        f11.encodeField(ctx, serializer, struct, value);
        f12.encodeField(ctx, serializer, struct, value);
        f13.encodeField(ctx, serializer, struct, value);
        f14.encodeField(ctx, serializer, struct, value);
      }, (ctx, deserializer, struct) {
        return constructor(
          f1.decodeField(ctx, deserializer, struct),
          f2.decodeField(ctx, deserializer, struct),
          f3.decodeField(ctx, deserializer, struct),
          f4.decodeField(ctx, deserializer, struct),
          f5.decodeField(ctx, deserializer, struct),
          f6.decodeField(ctx, deserializer, struct),
          f7.decodeField(ctx, deserializer, struct),
          f8.decodeField(ctx, deserializer, struct),
          f9.decodeField(ctx, deserializer, struct),
          f10.decodeField(ctx, deserializer, struct),
          f11.decodeField(ctx, deserializer, struct),
          f12.decodeField(ctx, deserializer, struct),
          f13.decodeField(ctx, deserializer, struct),
          f14.decodeField(ctx, deserializer, struct),
        );
      });

  StructEndec<S> with15Fields<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15>(
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
      StructEndec.of((ctx, serializer, struct, value) {
        f1.encodeField(ctx, serializer, struct, value);
        f2.encodeField(ctx, serializer, struct, value);
        f3.encodeField(ctx, serializer, struct, value);
        f4.encodeField(ctx, serializer, struct, value);
        f5.encodeField(ctx, serializer, struct, value);
        f6.encodeField(ctx, serializer, struct, value);
        f7.encodeField(ctx, serializer, struct, value);
        f8.encodeField(ctx, serializer, struct, value);
        f9.encodeField(ctx, serializer, struct, value);
        f10.encodeField(ctx, serializer, struct, value);
        f11.encodeField(ctx, serializer, struct, value);
        f12.encodeField(ctx, serializer, struct, value);
        f13.encodeField(ctx, serializer, struct, value);
        f14.encodeField(ctx, serializer, struct, value);
        f15.encodeField(ctx, serializer, struct, value);
      }, (ctx, deserializer, struct) {
        return constructor(
          f1.decodeField(ctx, deserializer, struct),
          f2.decodeField(ctx, deserializer, struct),
          f3.decodeField(ctx, deserializer, struct),
          f4.decodeField(ctx, deserializer, struct),
          f5.decodeField(ctx, deserializer, struct),
          f6.decodeField(ctx, deserializer, struct),
          f7.decodeField(ctx, deserializer, struct),
          f8.decodeField(ctx, deserializer, struct),
          f9.decodeField(ctx, deserializer, struct),
          f10.decodeField(ctx, deserializer, struct),
          f11.decodeField(ctx, deserializer, struct),
          f12.decodeField(ctx, deserializer, struct),
          f13.decodeField(ctx, deserializer, struct),
          f14.decodeField(ctx, deserializer, struct),
          f15.decodeField(ctx, deserializer, struct),
        );
      });

  StructEndec<S> with16Fields<F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15, F16>(
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
      StructEndec.of((ctx, serializer, struct, value) {
        f1.encodeField(ctx, serializer, struct, value);
        f2.encodeField(ctx, serializer, struct, value);
        f3.encodeField(ctx, serializer, struct, value);
        f4.encodeField(ctx, serializer, struct, value);
        f5.encodeField(ctx, serializer, struct, value);
        f6.encodeField(ctx, serializer, struct, value);
        f7.encodeField(ctx, serializer, struct, value);
        f8.encodeField(ctx, serializer, struct, value);
        f9.encodeField(ctx, serializer, struct, value);
        f10.encodeField(ctx, serializer, struct, value);
        f11.encodeField(ctx, serializer, struct, value);
        f12.encodeField(ctx, serializer, struct, value);
        f13.encodeField(ctx, serializer, struct, value);
        f14.encodeField(ctx, serializer, struct, value);
        f15.encodeField(ctx, serializer, struct, value);
        f16.encodeField(ctx, serializer, struct, value);
      }, (ctx, deserializer, struct) {
        return constructor(
          f1.decodeField(ctx, deserializer, struct),
          f2.decodeField(ctx, deserializer, struct),
          f3.decodeField(ctx, deserializer, struct),
          f4.decodeField(ctx, deserializer, struct),
          f5.decodeField(ctx, deserializer, struct),
          f6.decodeField(ctx, deserializer, struct),
          f7.decodeField(ctx, deserializer, struct),
          f8.decodeField(ctx, deserializer, struct),
          f9.decodeField(ctx, deserializer, struct),
          f10.decodeField(ctx, deserializer, struct),
          f11.decodeField(ctx, deserializer, struct),
          f12.decodeField(ctx, deserializer, struct),
          f13.decodeField(ctx, deserializer, struct),
          f14.decodeField(ctx, deserializer, struct),
          f15.decodeField(ctx, deserializer, struct),
          f16.decodeField(ctx, deserializer, struct),
        );
      });
}

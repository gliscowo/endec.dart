import 'package:endec/src/deserializer.dart';
import 'package:endec/src/serializer.dart';

import 'endec_base.dart';

extension Field<F> on Endec<F> {
  StructField<S, F> fieldOf<S>(String name, F Function(S struct) getter) => StructField.required(name, this, getter);

  StructField<S, F> optionalFieldOf<S>(String name, F Function(S struct) getter, F defaultValue) =>
      StructField.optional(name, this, getter, defaultValue);
}

typedef StructEncoder<S> = void Function(StructSerializer struct, S value);
typedef StructDecoder<S> = S Function(StructDeserializer struct);

abstract class StructEndec<S> with Endec<S> {
  StructEndec();
  factory StructEndec.of(StructEncoder<S> encoder, StructDecoder<S> decoder) => _SimpleStructEndec(encoder, decoder);

  void encodeStruct(StructSerializer struct, S value);
  S decodeStruct(StructDeserializer struct);

  @override
  void encode(Serializer serializer, S value) {
    final struct = serializer.struct();
    encodeStruct(struct, value);
    struct.end();
  }

  @override
  S decode(Deserializer deserializer) => decodeStruct(deserializer.struct());

  StructField<M, S> flatFieldOf<M>(S Function(M struct) getter) => FlatStructField.required(this, getter);
}

class _SimpleStructEndec<S> extends StructEndec<S> {
  final StructEncoder<S> _encoder;
  final StructDecoder<S> _decoder;
  _SimpleStructEndec(this._encoder, this._decoder);

  @override
  void encodeStruct(StructSerializer struct, S value) => _encoder(struct, value);

  @override
  S decodeStruct(StructDeserializer struct) => _decoder(struct);
}

final class StructField<S, F> {
  final String _name;
  final Endec<F> _endec;
  final F Function(S struct) _getter;

  final bool _required;
  final F? _defaultValue;

  StructField.required(this._name, this._endec, this._getter)
      : _required = true,
        _defaultValue = null;
  StructField.optional(this._name, this._endec, this._getter, F this._defaultValue) : _required = false;

  void encodeField(StructSerializer struct, S instance) => struct.field(_name, _endec, _getter(instance));
  F decodeField(StructDeserializer struct) =>
      _required ? struct.field(_name, _endec) : struct.optionalField(_name, _endec, _defaultValue as F);
}

final class FlatStructField<S, M> extends StructField<S, M> {
  FlatStructField.required(StructEndec<M> endec, M Function(S) getter) : super.required("", endec, getter);

  @override
  StructEndec<M> get _endec => super._endec as StructEndec<M>;

  @override
  void encodeField(StructSerializer struct, S instance) => _endec.encodeStruct(struct, _getter(instance));
  @override
  M decodeField(StructDeserializer struct) => _endec.decodeStruct(struct);
}

StructEndecBuilder<S> structEndec<S>() => StructEndecBuilder._();

class StructEndecBuilder<S> {
  StructEndecBuilder._();

  Endec<S> with1Field<F1>(
    StructField<S, F1> f1,
    S Function(F1) constructor,
  ) =>
      StructEndec.of(
        (struct, value) => f1.encodeField(struct, value),
        (struct) => constructor(f1.decodeField(struct)),
      );

  StructEndec<S> with2Fields<F1, F2>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    S Function(F1, F2) constructor,
  ) =>
      StructEndec.of((struct, value) {
        f1.encodeField(struct, value);
        f2.encodeField(struct, value);
      }, (struct) {
        return constructor(
          f1.decodeField(struct),
          f2.decodeField(struct),
        );
      });

  StructEndec<S> with3Fields<F1, F2, F3>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    S Function(F1, F2, F3) constructor,
  ) =>
      StructEndec.of((struct, value) {
        f1.encodeField(struct, value);
        f2.encodeField(struct, value);
        f3.encodeField(struct, value);
      }, (struct) {
        return constructor(
          f1.decodeField(struct),
          f2.decodeField(struct),
          f3.decodeField(struct),
        );
      });

  StructEndec<S> with4Fields<F1, F2, F3, F4>(
    StructField<S, F1> f1,
    StructField<S, F2> f2,
    StructField<S, F3> f3,
    StructField<S, F4> f4,
    S Function(F1, F2, F3, F4) constructor,
  ) =>
      StructEndec.of((struct, value) {
        f1.encodeField(struct, value);
        f2.encodeField(struct, value);
        f3.encodeField(struct, value);
        f4.encodeField(struct, value);
      }, (struct) {
        return constructor(
          f1.decodeField(struct),
          f2.decodeField(struct),
          f3.decodeField(struct),
          f4.decodeField(struct),
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
      StructEndec.of((struct, value) {
        f1.encodeField(struct, value);
        f2.encodeField(struct, value);
        f3.encodeField(struct, value);
        f4.encodeField(struct, value);
        f5.encodeField(struct, value);
      }, (struct) {
        return constructor(
          f1.decodeField(struct),
          f2.decodeField(struct),
          f3.decodeField(struct),
          f4.decodeField(struct),
          f5.decodeField(struct),
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
      StructEndec.of((struct, value) {
        f1.encodeField(struct, value);
        f2.encodeField(struct, value);
        f3.encodeField(struct, value);
        f4.encodeField(struct, value);
        f5.encodeField(struct, value);
        f6.encodeField(struct, value);
      }, (struct) {
        return constructor(
          f1.decodeField(struct),
          f2.decodeField(struct),
          f3.decodeField(struct),
          f4.decodeField(struct),
          f5.decodeField(struct),
          f6.decodeField(struct),
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
      StructEndec.of((struct, value) {
        f1.encodeField(struct, value);
        f2.encodeField(struct, value);
        f3.encodeField(struct, value);
        f4.encodeField(struct, value);
        f5.encodeField(struct, value);
        f6.encodeField(struct, value);
        f7.encodeField(struct, value);
      }, (struct) {
        return constructor(
          f1.decodeField(struct),
          f2.decodeField(struct),
          f3.decodeField(struct),
          f4.decodeField(struct),
          f5.decodeField(struct),
          f6.decodeField(struct),
          f7.decodeField(struct),
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
      StructEndec.of((struct, value) {
        f1.encodeField(struct, value);
        f2.encodeField(struct, value);
        f3.encodeField(struct, value);
        f4.encodeField(struct, value);
        f5.encodeField(struct, value);
        f6.encodeField(struct, value);
        f7.encodeField(struct, value);
        f8.encodeField(struct, value);
      }, (struct) {
        return constructor(
          f1.decodeField(struct),
          f2.decodeField(struct),
          f3.decodeField(struct),
          f4.decodeField(struct),
          f5.decodeField(struct),
          f6.decodeField(struct),
          f7.decodeField(struct),
          f8.decodeField(struct),
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
      StructEndec.of((struct, value) {
        f1.encodeField(struct, value);
        f2.encodeField(struct, value);
        f3.encodeField(struct, value);
        f4.encodeField(struct, value);
        f5.encodeField(struct, value);
        f6.encodeField(struct, value);
        f7.encodeField(struct, value);
        f8.encodeField(struct, value);
        f9.encodeField(struct, value);
      }, (struct) {
        return constructor(
          f1.decodeField(struct),
          f2.decodeField(struct),
          f3.decodeField(struct),
          f4.decodeField(struct),
          f5.decodeField(struct),
          f6.decodeField(struct),
          f7.decodeField(struct),
          f8.decodeField(struct),
          f9.decodeField(struct),
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
      StructEndec.of((struct, value) {
        f1.encodeField(struct, value);
        f2.encodeField(struct, value);
        f3.encodeField(struct, value);
        f4.encodeField(struct, value);
        f5.encodeField(struct, value);
        f6.encodeField(struct, value);
        f7.encodeField(struct, value);
        f8.encodeField(struct, value);
        f9.encodeField(struct, value);
        f10.encodeField(struct, value);
      }, (struct) {
        return constructor(
          f1.decodeField(struct),
          f2.decodeField(struct),
          f3.decodeField(struct),
          f4.decodeField(struct),
          f5.decodeField(struct),
          f6.decodeField(struct),
          f7.decodeField(struct),
          f8.decodeField(struct),
          f9.decodeField(struct),
          f10.decodeField(struct),
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
      StructEndec.of((struct, value) {
        f1.encodeField(struct, value);
        f2.encodeField(struct, value);
        f3.encodeField(struct, value);
        f4.encodeField(struct, value);
        f5.encodeField(struct, value);
        f6.encodeField(struct, value);
        f7.encodeField(struct, value);
        f8.encodeField(struct, value);
        f9.encodeField(struct, value);
        f10.encodeField(struct, value);
        f11.encodeField(struct, value);
      }, (struct) {
        return constructor(
          f1.decodeField(struct),
          f2.decodeField(struct),
          f3.decodeField(struct),
          f4.decodeField(struct),
          f5.decodeField(struct),
          f6.decodeField(struct),
          f7.decodeField(struct),
          f8.decodeField(struct),
          f9.decodeField(struct),
          f10.decodeField(struct),
          f11.decodeField(struct),
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
      StructEndec.of((struct, value) {
        f1.encodeField(struct, value);
        f2.encodeField(struct, value);
        f3.encodeField(struct, value);
        f4.encodeField(struct, value);
        f5.encodeField(struct, value);
        f6.encodeField(struct, value);
        f7.encodeField(struct, value);
        f8.encodeField(struct, value);
        f9.encodeField(struct, value);
        f10.encodeField(struct, value);
        f11.encodeField(struct, value);
        f12.encodeField(struct, value);
      }, (struct) {
        return constructor(
          f1.decodeField(struct),
          f2.decodeField(struct),
          f3.decodeField(struct),
          f4.decodeField(struct),
          f5.decodeField(struct),
          f6.decodeField(struct),
          f7.decodeField(struct),
          f8.decodeField(struct),
          f9.decodeField(struct),
          f10.decodeField(struct),
          f11.decodeField(struct),
          f12.decodeField(struct),
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
      StructEndec.of((struct, value) {
        f1.encodeField(struct, value);
        f2.encodeField(struct, value);
        f3.encodeField(struct, value);
        f4.encodeField(struct, value);
        f5.encodeField(struct, value);
        f6.encodeField(struct, value);
        f7.encodeField(struct, value);
        f8.encodeField(struct, value);
        f9.encodeField(struct, value);
        f10.encodeField(struct, value);
        f11.encodeField(struct, value);
        f12.encodeField(struct, value);
        f13.encodeField(struct, value);
      }, (struct) {
        return constructor(
          f1.decodeField(struct),
          f2.decodeField(struct),
          f3.decodeField(struct),
          f4.decodeField(struct),
          f5.decodeField(struct),
          f6.decodeField(struct),
          f7.decodeField(struct),
          f8.decodeField(struct),
          f9.decodeField(struct),
          f10.decodeField(struct),
          f11.decodeField(struct),
          f12.decodeField(struct),
          f13.decodeField(struct),
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
      StructEndec.of((struct, value) {
        f1.encodeField(struct, value);
        f2.encodeField(struct, value);
        f3.encodeField(struct, value);
        f4.encodeField(struct, value);
        f5.encodeField(struct, value);
        f6.encodeField(struct, value);
        f7.encodeField(struct, value);
        f8.encodeField(struct, value);
        f9.encodeField(struct, value);
        f10.encodeField(struct, value);
        f11.encodeField(struct, value);
        f12.encodeField(struct, value);
        f13.encodeField(struct, value);
        f14.encodeField(struct, value);
      }, (struct) {
        return constructor(
          f1.decodeField(struct),
          f2.decodeField(struct),
          f3.decodeField(struct),
          f4.decodeField(struct),
          f5.decodeField(struct),
          f6.decodeField(struct),
          f7.decodeField(struct),
          f8.decodeField(struct),
          f9.decodeField(struct),
          f10.decodeField(struct),
          f11.decodeField(struct),
          f12.decodeField(struct),
          f13.decodeField(struct),
          f14.decodeField(struct),
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
      StructEndec.of((struct, value) {
        f1.encodeField(struct, value);
        f2.encodeField(struct, value);
        f3.encodeField(struct, value);
        f4.encodeField(struct, value);
        f5.encodeField(struct, value);
        f6.encodeField(struct, value);
        f7.encodeField(struct, value);
        f8.encodeField(struct, value);
        f9.encodeField(struct, value);
        f10.encodeField(struct, value);
        f11.encodeField(struct, value);
        f12.encodeField(struct, value);
        f13.encodeField(struct, value);
        f14.encodeField(struct, value);
        f15.encodeField(struct, value);
      }, (struct) {
        return constructor(
          f1.decodeField(struct),
          f2.decodeField(struct),
          f3.decodeField(struct),
          f4.decodeField(struct),
          f5.decodeField(struct),
          f6.decodeField(struct),
          f7.decodeField(struct),
          f8.decodeField(struct),
          f9.decodeField(struct),
          f10.decodeField(struct),
          f11.decodeField(struct),
          f12.decodeField(struct),
          f13.decodeField(struct),
          f14.decodeField(struct),
          f15.decodeField(struct),
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
      StructEndec.of((struct, value) {
        f1.encodeField(struct, value);
        f2.encodeField(struct, value);
        f3.encodeField(struct, value);
        f4.encodeField(struct, value);
        f5.encodeField(struct, value);
        f6.encodeField(struct, value);
        f7.encodeField(struct, value);
        f8.encodeField(struct, value);
        f9.encodeField(struct, value);
        f10.encodeField(struct, value);
        f11.encodeField(struct, value);
        f12.encodeField(struct, value);
        f13.encodeField(struct, value);
        f14.encodeField(struct, value);
        f15.encodeField(struct, value);
        f16.encodeField(struct, value);
      }, (struct) {
        return constructor(
          f1.decodeField(struct),
          f2.decodeField(struct),
          f3.decodeField(struct),
          f4.decodeField(struct),
          f5.decodeField(struct),
          f6.decodeField(struct),
          f7.decodeField(struct),
          f8.decodeField(struct),
          f9.decodeField(struct),
          f10.decodeField(struct),
          f11.decodeField(struct),
          f12.decodeField(struct),
          f13.decodeField(struct),
          f14.decodeField(struct),
          f15.decodeField(struct),
          f16.decodeField(struct),
        );
      });
}

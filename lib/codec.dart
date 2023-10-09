import 'package:codec/deserializer.dart';
import 'package:codec/serializer.dart';

typedef Int = int;
typedef Double = double;

abstract mixin class Codec<T> {
  static final Codec<Int> int =
      SimpleCodec((serializer, value) => serializer.i64(value), (deserializer) => deserializer.i64());
  static final Codec<Double> double =
      SimpleCodec((serializer, value) => serializer.f64(value), (deserializer) => deserializer.f64());
  static final Codec<String> string =
      SimpleCodec((serializer, value) => serializer.string(value), (deserializer) => deserializer.string());

  void encode<S>(Serializer<S> serializer, T value);
  T decode<S>(Deserializer<S> deserializer);

  Codec<List<T>> listOf() => _ListCodec(this);
  Codec<Map<String, T>> mapOf() => _MapCodec(this);
  Codec<T?> optionalOf() => _OptionalCodec(this);

  Codec<U> xmap<U>(U Function(T self) to, T Function(U other) from) => _XmapCodec(this, to, from);
}

class _ListCodec<T> with Codec<List<T>> {
  final Codec<T> elementCodec;
  _ListCodec(this.elementCodec);

  @override
  void encode<S>(Serializer<S> serializer, List<T> value) {
    var state = serializer.sequence<T>(elementCodec, value.length);
    for (final element in value) {
      state.element(element);
    }
    state.end();
  }

  @override
  List<T> decode<S>(Deserializer<S> deserializer) {
    final result = <T>[];

    var state = deserializer.sequence(elementCodec);
    while (state.moveNext()) {
      result.add(state.element());
    }

    return result;
  }
}

class _MapCodec<T> with Codec<Map<String, T>> {
  final Codec<T> valueCodec;
  _MapCodec(this.valueCodec);

  @override
  void encode<S>(Serializer<S> serializer, Map<String, T> value) {
    var state = serializer.map<T>(valueCodec, value.length);
    for (final MapEntry(:key, :value) in value.entries) {
      state.entry(key, value);
    }
    state.end();
  }

  @override
  Map<String, T> decode<S>(Deserializer<S> deserializer) {
    final result = <String, T>{};

    var state = deserializer.map(valueCodec);
    while (state.moveNext()) {
      var (key, value) = state.entry();
      result[key] = value;
    }

    return result;
  }
}

class _OptionalCodec<T> with Codec<T?> {
  final Codec<T> _valueCodec;
  _OptionalCodec(this._valueCodec);

  @override
  T? decode<S>(Deserializer<S> deserializer) => deserializer.optional(_valueCodec);
  @override
  void encode<S>(Serializer<S> serializer, T? value) => serializer.optional(_valueCodec, value);
}

class _XmapCodec<T, U> with Codec<U> {
  final Codec<T> _sourceCodec;
  final U Function(T) _to;
  final T Function(U) _from;

  _XmapCodec(this._sourceCodec, this._to, this._from);

  @override
  void encode<S>(Serializer<S> serializer, U value) => _sourceCodec.encode(serializer, _from(value));
  @override
  U decode<S>(Deserializer<S> deserializer) => _to(_sourceCodec.decode(deserializer));
}

typedef _Encoder<T> = void Function(Serializer serializer, T value);
typedef _Decoder<T> = T Function(Deserializer deserializer);

class SimpleCodec<T> with Codec<T> {
  final _Encoder<T> _encoder;
  final _Decoder<T> _decoder;
  SimpleCodec(this._encoder, this._decoder);

  @override
  void encode<S>(Serializer<S> serializer, T value) => _encoder(serializer, value);
  @override
  T decode<S>(Deserializer<S> deserializer) => _decoder(deserializer);
}

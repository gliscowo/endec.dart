import 'deserializer.dart';
import 'serializer.dart';

typedef Int = int;
typedef Double = double;
typedef Bool = bool;

typedef Encoder<T> = void Function(Serializer serializer, T value);
typedef Decoder<T> = T Function(Deserializer deserializer);

abstract mixin class Endec<T> {
  static final Endec<Int> int =
      Endec.of((serializer, value) => serializer.i64(value), (deserializer) => deserializer.i64());
  static final Endec<Double> double =
      Endec.of((serializer, value) => serializer.f64(value), (deserializer) => deserializer.f64());
  static final Endec<Bool> bool =
      Endec.of((serializer, value) => serializer.boolean(value), (deserializer) => deserializer.boolean());
  static final Endec<String> string =
      Endec.of((serializer, value) => serializer.string(value), (deserializer) => deserializer.string());

  factory Endec.of(Encoder<T> encoder, Decoder<T> decoder) => _SimpleEndec(encoder, decoder);

  void encode<S>(Serializer<S> serializer, T value);
  T decode<S>(Deserializer<S> deserializer);

  Endec<List<T>> listOf() => _ListEndec(this);
  Endec<Map<String, T>> mapOf() => _MapEndec(this);
  Endec<T?> optionalOf() => _OptionalEndec(this);

  Endec<U> xmap<U>(U Function(T self) to, T Function(U other) from) => _XmapEndec(this, to, from);
}

class _ListEndec<T> with Endec<List<T>> {
  final Endec<T> elementEndec;
  _ListEndec(this.elementEndec);

  @override
  void encode<S>(Serializer<S> serializer, List<T> value) {
    var state = serializer.sequence<T>(elementEndec, value.length);
    for (final element in value) {
      state.element(element);
    }
    state.end();
  }

  @override
  List<T> decode<S>(Deserializer<S> deserializer) {
    final result = <T>[];

    var state = deserializer.sequence(elementEndec);
    while (state.moveNext()) {
      result.add(state.element());
    }

    return result;
  }
}

class _MapEndec<T> with Endec<Map<String, T>> {
  final Endec<T> valueEndec;
  _MapEndec(this.valueEndec);

  @override
  void encode<S>(Serializer<S> serializer, Map<String, T> value) {
    var state = serializer.map<T>(valueEndec, value.length);
    for (final MapEntry(:key, :value) in value.entries) {
      state.entry(key, value);
    }
    state.end();
  }

  @override
  Map<String, T> decode<S>(Deserializer<S> deserializer) {
    final result = <String, T>{};

    var state = deserializer.map(valueEndec);
    while (state.moveNext()) {
      var (key, value) = state.entry();
      result[key] = value;
    }

    return result;
  }
}

class _OptionalEndec<T> with Endec<T?> {
  final Endec<T> _valueEndec;
  _OptionalEndec(this._valueEndec);

  @override
  T? decode<S>(Deserializer<S> deserializer) => deserializer.optional(_valueEndec);
  @override
  void encode<S>(Serializer<S> serializer, T? value) => serializer.optional(_valueEndec, value);
}

class _XmapEndec<T, U> with Endec<U> {
  final Endec<T> _sourceEndec;
  final U Function(T) _to;
  final T Function(U) _from;

  _XmapEndec(this._sourceEndec, this._to, this._from);

  @override
  void encode<S>(Serializer<S> serializer, U value) => _sourceEndec.encode(serializer, _from(value));
  @override
  U decode<S>(Deserializer<S> deserializer) => _to(_sourceEndec.decode(deserializer));
}

class _SimpleEndec<T> with Endec<T> {
  final Encoder<T> _encoder;
  final Decoder<T> _decoder;
  _SimpleEndec(this._encoder, this._decoder);

  @override
  void encode<S>(Serializer<S> serializer, T value) => _encoder(serializer, value);
  @override
  T decode<S>(Deserializer<S> deserializer) => _decoder(deserializer);
}

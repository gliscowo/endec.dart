import 'deserializer.dart';
import 'serializer.dart';
import 'struct_endec.dart';

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
  static Endec<Map<K, V>> map<K, V>(Endec<K> keyEndec, Endec<V> valueEndec) => structEndec<MapEntry<K, V>>()
      .with2Fields(
        keyEndec.fieldOf("k", (entry) => entry.key),
        valueEndec.fieldOf("v", (entry) => entry.value),
        MapEntry.new,
      )
      .listOf()
      .xmap(Map.fromEntries, (map) => map.entries.toList());

  void encode(Serializer serializer, T value);
  T decode(Deserializer deserializer);

  Endec<List<T>> listOf() => _ListEndec(this);
  Endec<Map<String, T>> mapOf() => _StringMapEndec(this);
  Endec<T?> optionalOf() => _OptionalEndec(this);

  Endec<U> xmap<U>(U Function(T self) to, T Function(U other) from) => _XmapEndec(this, to, from);
}

class _ListEndec<T> with Endec<List<T>> {
  final Endec<T> _elementEndec;
  _ListEndec(this._elementEndec);

  @override
  void encode(Serializer serializer, List<T> value) {
    var state = serializer.sequence(_elementEndec, value.length);
    for (final element in value) {
      state.element(element);
    }
    state.end();
  }

  @override
  List<T> decode(Deserializer deserializer) {
    final result = <T>[];

    var state = deserializer.sequence(_elementEndec);
    while (state.moveNext()) {
      result.add(state.element());
    }

    return result;
  }
}

class _StringMapEndec<T> with Endec<Map<String, T>> {
  final Endec<T> _valueEndec;
  _StringMapEndec(this._valueEndec);

  @override
  void encode(Serializer serializer, Map<String, T> value) {
    var state = serializer.map(_valueEndec, value.length);
    for (final MapEntry(:key, :value) in value.entries) {
      state.entry(key, value);
    }
    state.end();
  }

  @override
  Map<String, T> decode(Deserializer deserializer) {
    final result = <String, T>{};

    var state = deserializer.map(_valueEndec);
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
  T? decode(Deserializer deserializer) => deserializer.optional(_valueEndec);
  @override
  void encode(Serializer serializer, T? value) => serializer.optional(_valueEndec, value);
}

class _XmapEndec<T, U> with Endec<U> {
  final Endec<T> _sourceEndec;
  final U Function(T) _to;
  final T Function(U) _from;

  _XmapEndec(this._sourceEndec, this._to, this._from);

  @override
  void encode(Serializer serializer, U value) => _sourceEndec.encode(serializer, _from(value));
  @override
  U decode(Deserializer deserializer) => _to(_sourceEndec.decode(deserializer));
}

class _SimpleEndec<T> with Endec<T> {
  final Encoder<T> _encoder;
  final Decoder<T> _decoder;
  _SimpleEndec(this._encoder, this._decoder);

  @override
  void encode(Serializer serializer, T value) => _encoder(serializer, value);
  @override
  T decode(Deserializer deserializer) => _decoder(deserializer);
}

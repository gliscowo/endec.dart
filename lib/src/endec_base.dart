import 'dart:core' as core show bool;
import 'dart:core' hide bool;
import 'dart:typed_data';

import 'deserializer.dart';
import 'serialization_context.dart';
import 'serializer.dart';
import 'struct_endec.dart';

typedef Encoder<T> = void Function(SerializationContext ctx, Serializer serializer, T value);
typedef Decoder<T> = T Function(SerializationContext ctx, Deserializer deserializer);

abstract mixin class Endec<T> {
  // --- serializer primitives ---
  static final Endec<int> i8 =
      Endec.of((ctx, serializer, value) => serializer.i8(ctx, value), (ctx, deserializer) => deserializer.i8(ctx));
  static final Endec<int> u8 =
      Endec.of((ctx, serializer, value) => serializer.u8(ctx, value), (ctx, deserializer) => deserializer.u8(ctx));
  static final Endec<int> i16 =
      Endec.of((ctx, serializer, value) => serializer.i16(ctx, value), (ctx, deserializer) => deserializer.i16(ctx));
  static final Endec<int> u16 =
      Endec.of((ctx, serializer, value) => serializer.u16(ctx, value), (ctx, deserializer) => deserializer.u16(ctx));
  static final Endec<int> i32 =
      Endec.of((ctx, serializer, value) => serializer.i32(ctx, value), (ctx, deserializer) => deserializer.i32(ctx));
  static final Endec<int> u32 =
      Endec.of((ctx, serializer, value) => serializer.u32(ctx, value), (ctx, deserializer) => deserializer.u32(ctx));
  static final Endec<int> i64 =
      Endec.of((ctx, serializer, value) => serializer.i64(ctx, value), (ctx, deserializer) => deserializer.i64(ctx));
  static final Endec<int> u64 =
      Endec.of((ctx, serializer, value) => serializer.u64(ctx, value), (ctx, deserializer) => deserializer.u64(ctx));

  static final Endec<double> f32 =
      Endec.of((ctx, serializer, value) => serializer.f32(ctx, value), (ctx, deserializer) => deserializer.f32(ctx));
  static final Endec<double> f64 =
      Endec.of((ctx, serializer, value) => serializer.f64(ctx, value), (ctx, deserializer) => deserializer.f64(ctx));

  static final Endec<core.bool> bool = Endec.of(
      (ctx, serializer, value) => serializer.boolean(ctx, value), (ctx, deserializer) => deserializer.boolean(ctx));
  static final Endec<String> string = Endec.of(
      (ctx, serializer, value) => serializer.string(ctx, value), (ctx, deserializer) => deserializer.string(ctx));
  static final Endec<Uint8List> bytes = Endec.of(
      (ctx, serializer, value) => serializer.bytes(ctx, value), (ctx, deserializer) => deserializer.bytes(ctx));

  // --- constructors ---

  factory Endec.of(Encoder<T> encoder, Decoder<T> decoder) = _SimpleEndec;
  factory Endec.recursive(Endec<T> Function(Endec<T> thisRef) factory) = _RecursiveEndec;

  static Endec<Map<K, V>> map<K, V>(Endec<K> keyEndec, Endec<V> valueEndec) => structEndec<MapEntry<K, V>>()
      .with2Fields(
        keyEndec.fieldOf("k", (entry) => entry.key),
        valueEndec.fieldOf("v", (entry) => entry.value),
        MapEntry.new,
      )
      .listOf()
      .xmap(Map.fromEntries, (map) => map.entries.toList());

  static AttributeBranchBuilder<T> ifAttr<T>(SerializationAttribute attribute, Endec<T> endec) =>
      AttributeBranchBuilder(attribute, endec);

  // --- interface specification ---

  void encode(SerializationContext ctx, Serializer serializer, T value);
  T decode(SerializationContext ctx, Deserializer deserializer);

  // --- composition operators ---

  Endec<List<T>> listOf() => _ListEndec(this);
  Endec<Set<T>> setOf() => listOf().xmap((self) => self.toSet(), (other) => other.toList());
  Endec<Map<String, T>> mapOf() => _StringMapEndec(this);
  Endec<T?> optionalOf() => _OptionalEndec(this);

  Endec<U> xmap<U>(U Function(T self) to, T Function(U other) from) => _XmapEndec(this, to, from);
}

// --- type-specific extensions ---

extension RangedNumEndec<N extends num> on Endec<N> {
  /// Create a new endec which verifies that the number values in receives during
  /// de- and encoding are between [min] and [max] (both inclusive).
  ///
  /// If [error] is set, a [RangedNumException] is thrown when the value outside
  /// the specific bounds. Otherwise, it is corrected to the nearest bound and passed on
  Endec<N> ranged({N? min, N? max, core.bool error = false}) => xmap(
        (value) => _checkBounds(value, min, max, error),
        (value) => _checkBounds(value, min, max, error),
      );

  static N _checkBounds<N extends num>(N value, N? min, N? max, core.bool error) {
    if (min != null && value < min) {
      if (error) throw RangedNumException._(value, min, max);
      value = min;
    } else if (max != null && value > max) {
      if (error) throw RangedNumException._(value, min, max);
      value = max;
    }

    return value;
  }
}

class RangedNumException implements Exception {
  final num value;
  final num? lowerBound, upperBound;

  RangedNumException._(this.value, this.lowerBound, this.upperBound);

  @override
  String toString() =>
      'Value $value is out of range: ${lowerBound != null ? '[$lowerBound' : '(∞'},${upperBound != null ? '$upperBound]' : '∞)'}';
}

// --- implementation classes ---

class _ListEndec<T> with Endec<List<T>> {
  final Endec<T> _elementEndec;
  _ListEndec(this._elementEndec);

  @override
  void encode(SerializationContext ctx, Serializer serializer, List<T> value) {
    var state = serializer.sequence(ctx, _elementEndec, value.length);
    for (final element in value) {
      state.element(element);
    }
    state.end();
  }

  @override
  List<T> decode(SerializationContext ctx, Deserializer deserializer) {
    final result = <T>[];

    var state = deserializer.sequence(ctx, _elementEndec);
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
  void encode(SerializationContext ctx, Serializer serializer, Map<String, T> value) {
    var state = serializer.map(ctx, _valueEndec, value.length);
    for (final MapEntry(:key, :value) in value.entries) {
      state.entry(key, value);
    }
    state.end();
  }

  @override
  Map<String, T> decode(SerializationContext ctx, Deserializer deserializer) {
    final result = <String, T>{};

    var state = deserializer.map(ctx, _valueEndec);
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
  T? decode(SerializationContext ctx, Deserializer deserializer) => deserializer.optional(ctx, _valueEndec);
  @override
  void encode(SerializationContext ctx, Serializer serializer, T? value) =>
      serializer.optional(ctx, _valueEndec, value);
}

class _XmapEndec<T, U> with Endec<U> {
  final Endec<T> _sourceEndec;
  final U Function(T) _to;
  final T Function(U) _from;

  _XmapEndec(this._sourceEndec, this._to, this._from);

  @override
  void encode(SerializationContext ctx, Serializer serializer, U value) =>
      _sourceEndec.encode(ctx, serializer, _from(value));
  @override
  U decode(SerializationContext ctx, Deserializer deserializer) => _to(_sourceEndec.decode(ctx, deserializer));
}

class _RecursiveEndec<T> with Endec<T> {
  late final Endec<T> _inner;
  _RecursiveEndec(Endec<T> Function(Endec<T>) endecFactory) {
    _inner = endecFactory(this);
  }

  @override
  T decode(SerializationContext ctx, Deserializer deserializer) => _inner.decode(ctx, deserializer);
  @override
  void encode(SerializationContext ctx, Serializer serializer, T value) => _inner.encode(ctx, serializer, value);
}

class _SimpleEndec<T> with Endec<T> {
  final Encoder<T> _encoder;
  final Decoder<T> _decoder;
  _SimpleEndec(this._encoder, this._decoder);

  @override
  void encode(SerializationContext ctx, Serializer serializer, T value) => _encoder(ctx, serializer, value);
  @override
  T decode(SerializationContext ctx, Deserializer deserializer) => _decoder(ctx, deserializer);
}

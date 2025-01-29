import 'dart:core' as core show bool;
import 'dart:core' hide bool;
import 'dart:typed_data';

import 'deserializer.dart';
import 'serialization_context.dart';
import 'serializer.dart';
import 'struct_endec.dart';

typedef Encoder<T> = void Function(SerializationContext ctx, Serializer serializer, T value);
typedef Decoder<T> = T Function(SerializationContext ctx, Deserializer deserializer);

/// A combined **en**coder and **dec**oder for values of type [T]
///
/// To convert between single instances of [T] and their serialized form,
/// use the respective `to<Format>` and `from<Format>` top-level functions
/// exported by the format's respective serializer package
abstract mixin class Endec<T> {
  // --- interface specification ---

  /// Write all data required to reconstruct [value] into [serializer]
  void encode(SerializationContext ctx, Serializer serializer, T value);

  /// Decode the data specified by [encode] and reconstruct
  /// the corresponding instance of [T].
  ///
  /// Endecs which intend to handle deserialization failure by decoding a different
  /// structure on error, must wrap their initial reads in a call to [Deserializer.tryRead]
  /// to ensure that deserializer state is restored for the subsequent attempt
  T decode(SerializationContext ctx, Deserializer deserializer);

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

  // --- serializer compound types ---

  Endec<List<T>> listOf() => _ListEndec(this);
  Endec<Map<String, T>> mapOf() => _StringMapEndec(this);
  Endec<T?> optionalOf() => _OptionalEndec(this);

  // --- constructors ---

  factory Endec.of(Encoder<T> encoder, Decoder<T> decoder) = _SimpleEndec;
  factory Endec.recursive(Endec<T> Function(Endec<T> thisRef) factory) = _RecursiveEndec;

  /// Create a new endec which serializes a map from keys encoded as strings using
  /// [keyToString] and decoded using [stringToKey] to values serialized
  /// using [valueEndec]
  static Endec<Map<K, V>> map<K, V>(
    String Function(K key) keyToString,
    K Function(String keyString) stringToKey,
    Endec<V> valueEndec,
  ) =>
      _StringMappedMapEndec(valueEndec, keyToString, stringToKey);

  /// Create a new endec which serializes a map from keys serialized using
  /// [keyEndec] to values serialized using [valueEndec].
  ///
  /// Due to the endec data model only natively supporting maps
  /// with string keys, the resulting endec's serialized representation
  /// is a list of key-value pairs
  static Endec<Map<K, V>> improperMap<K, V>(Endec<K> keyEndec, Endec<V> valueEndec) => structEndec<MapEntry<K, V>>()
      .with2Fields(
        keyEndec.fieldOf("k", (entry) => entry.key),
        valueEndec.fieldOf("v", (entry) => entry.value),
        MapEntry.new,
      )
      .listOf()
      .xmap(Map.fromEntries, (map) => map.entries.toList());

  /// Create a new dispatch endec which serializes variants of [T]
  ///
  /// Such an endec is conceptually similar to a struct-dispatch one created through {@link #dispatchedStruct(Function, Function, Endec, String)}
  /// (check the documentation on that function for a complete usage example), but because this family of endecs does not
  /// require [T] to be a struct, the variant identifier field cannot be merged with the rest and is encoded separately
  static StructEndec<T> dispatched<T, V>(
    Endec<T> Function(V variant) variantToEndec,
    V Function(T instance) instanceToVariant,
    Endec<V> variantEndec,
  ) =>
      _DispatchEndec(variantEndec, variantToEndec, instanceToVariant);

  /// Create a new struct-dispatch endec which serializes variants of the struct [S]
  ///
  /// To do this, it inserts an additional field given by [variantKey] into the beginning of the
  /// struct and writes the variant identifier obtained from [instanceToVariant] into it
  /// using [variantEndec]. When decoding, this variant identifier is read and the rest
  /// of the struct decoded with the endec obtained from [variantToEndec]
  ///
  /// For example, assume there is some interface like this
  /// ```dart
  /// abstract interface class Herbert {
  ///      String get id;
  ///      ... more functionality here
  /// }
  /// ```
  ///
  /// which is implemented by [Harald] and [Albrecht], whose endecs we have
  /// stored in a map:
  /// ```dart
  /// final class Harald implements Herbert {
  ///      static final endec = structEndec<Harald>()...;
  ///
  ///      final int _haraldOMeter;
  ///      ...
  /// }
  ///
  /// final class Albrecht implements Herbert {
  ///     static final endec = structEndec<Albrecht>()...;
  ///
  ///     final List<String> _dadJokes;
  ///      ...
  /// }
  ///
  /// final herbertRegistry = {
  ///      'harald': Harald.endec,
  ///      'albrecht': Albrecht.endec,
  /// };
  /// ```
  ///
  /// We could then create an endec capable of serializing either [Harald] or [Albrecht] as follows:
  /// ```dart
  /// Endec.dispatchedStruct<Herbert, String>((id) => herbertRegistry[id]!, (herbert) => herbert.id, Endec.string)
  /// ```
  ///
  /// If we now encode an instance of [Albrecht] to JSON using this endec, we'll get the following result:
  /// ```json
  /// {
  ///      "type": "herbert:albrecht",
  ///      "dad_jokes": [
  ///          "What does a sprinter eat before a race? Nothing, they fast!",
  ///          "Why don't eggs tell jokes? They'd crack each other up."
  ///      ]
  /// }
  /// ```
  ///
  /// And similarly, the following data could be used for decoding an instance of [Harald]:
  /// ```json
  /// {
  ///      "type": "herbert:harald",
  ///      "harald_o_meter": 69
  /// }
  /// ```
  static StructEndec<S> dispatchedStruct<S, V>(
    StructEndec<S> Function(V variant) variantToEndec,
    V Function(S instance) instanceToVariant,
    Endec<V> variantEndec, {
    String key = 'type',
  }) =>
      _StructDispatchEndec(key, variantEndec, variantToEndec, instanceToVariant);

  static AttributeBranchBuilder<T> ifAttr<T>(SerializationAttribute attribute, Endec<T> endec) =>
      AttributeBranchBuilder(attribute, endec);

  // --- composition operators ---

  /// Create a new endec which converts between instances of [T] and [R]
  /// using [to] and [from] before encoding / after decoding
  Endec<U> xmap<U>(U Function(T self) to, T Function(U other) from) => _XmapEndec(this, to, from);

  /// Create a new endec which serializes a set of elements
  /// using this endec as an xmapped list
  Endec<Set<T>> setOf() => listOf().xmap((self) => self.toSet(), (other) => other.toList());

  /// Create a new endec which runs [validator] (giving it the chance to
  /// throw on an invalid value) before encoding / after decoding
  Endec<T> validate(void Function(T value) validator) => xmap(
        (self) {
          validator(self);
          return self;
        },
        (other) {
          validator(other);
          return other;
        },
      );
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

class _StringMappedMapEndec<K, V> with Endec<Map<K, V>> {
  final Endec<V> _valueEndec;
  final String Function(K) _keyToString;
  final K Function(String) _stringToKey;
  _StringMappedMapEndec(this._valueEndec, this._keyToString, this._stringToKey);

  @override
  void encode(SerializationContext ctx, Serializer serializer, Map<K, V> value) {
    var state = serializer.map(ctx, _valueEndec, value.length);
    for (final MapEntry(:key, :value) in value.entries) {
      state.entry(_keyToString(key), value);
    }
    state.end();
  }

  @override
  Map<K, V> decode(SerializationContext ctx, Deserializer deserializer) {
    final result = <K, V>{};

    var state = deserializer.map(ctx, _valueEndec);
    while (state.moveNext()) {
      var (key, value) = state.entry();
      result[_stringToKey(key)] = value;
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

class _DispatchEndec<T, V> extends StructEndec<T> {
  final Endec<V> _variantEndec;
  final Endec<T> Function(V) _variantToEndec;
  final V Function(T) _instanceToVariant;

  _DispatchEndec(this._variantEndec, this._variantToEndec, this._instanceToVariant);

  @override
  void encodeStruct(SerializationContext ctx, Serializer serializer, StructSerializer struct, T value) {
    final variant = _instanceToVariant(value);
    struct.field('variant', ctx, _variantEndec, variant);
    struct.field('instance', ctx, _variantToEndec(variant), value);
  }

  @override
  T decodeStruct(SerializationContext ctx, Deserializer deserializer, StructDeserializer struct) {
    final variant = struct.field('variant', ctx, _variantEndec);
    return struct.field('instance', ctx, _variantToEndec(variant));
  }
}

class _StructDispatchEndec<S, V> extends StructEndec<S> {
  final String _key;
  final Endec<V> _variantEndec;
  final StructEndec<S> Function(V) _variantToEndec;
  final V Function(S) _instanceToVariant;

  _StructDispatchEndec(this._key, this._variantEndec, this._variantToEndec, this._instanceToVariant);

  @override
  void encodeStruct(SerializationContext ctx, Serializer serializer, StructSerializer struct, S value) {
    final variant = _instanceToVariant(value);
    struct.field(_key, ctx, _variantEndec, variant);

    _variantToEndec(variant).encodeStruct(ctx, serializer, struct, value);
  }

  @override
  S decodeStruct(SerializationContext ctx, Deserializer deserializer, StructDeserializer struct) {
    final variant = struct.field(_key, ctx, _variantEndec);
    return _variantToEndec(variant).decodeStruct(ctx, deserializer, struct);
  }
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

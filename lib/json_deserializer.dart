import 'dart:collection';
import 'dart:typed_data';

import 'package:codec/codec.dart';
import 'package:codec/deserializer.dart';

typedef JsonSource = Object Function();

T fromJson<T>(Codec<T> codec, Object json) {
  final deserializer = JsonDeserializer(json);
  return codec.decode(deserializer);
}

class JsonDeserializer implements Deserializer<Object> {
  final Queue<JsonSource> _sources = Queue();
  final Object _serialized;

  JsonDeserializer(this._serialized) {
    _sources.add(() => _serialized);
  }

  T _getObject<T>() => _sources.last() as T;

  @override
  int i8() => _getObject();
  @override
  int u8() => _getObject();

  @override
  int i16() => _getObject();
  @override
  int u16() => _getObject();

  @override
  int i32() => _getObject();
  @override
  int u32() => _getObject();

  @override
  int i64() => _getObject();
  @override
  int u64() => _getObject();

  @override
  double f32() => _getObject();
  @override
  double f64() => _getObject();

  @override
  String string() => _getObject();
  @override
  Uint8List bytes() => Uint8List.fromList(_getObject<List<dynamic>>().cast<int>());

  @override
  SequenceDeserializer<E> sequence<E>(Codec<E> elementCodec) =>
      _JsonSequenceDeserializer(this, elementCodec, _getObject<List<dynamic>>());
  @override
  MapDeserializer<V> map<V>(Codec<V> valueCodec) =>
      _JsonMapDeserializer.map(this, valueCodec, _getObject<Map<String, dynamic>>());
  @override
  StructDeserializer struct() => _JsonMapDeserializer.struct(this, _getObject<Map<String, dynamic>>());

  void _pushSource(JsonSource source) => _sources.addLast(source);
  void _popSource() => _sources.removeLast();
}

class _JsonMapDeserializer<V> implements MapDeserializer<V>, StructDeserializer {
  final JsonDeserializer _context;
  final Codec<V>? _valueCodec;
  final Iterator<MapEntry<String, dynamic>> _entries;

  _JsonMapDeserializer.map(this._context, Codec<V> valueCodec, Map<String, dynamic> map)
      : _valueCodec = valueCodec,
        _entries = map.entries.iterator;

  _JsonMapDeserializer.struct(this._context, Map<String, dynamic> map)
      : _valueCodec = null,
        _entries = map.entries.iterator;

  @override
  bool moveNext() => _entries.moveNext();

  @override
  (String, V) entry() => _kvPair(_valueCodec!, false);
  @override
  F field<F>(Codec<F> codec) => _kvPair(codec, true).$2;

  (String, T) _kvPair<T>(Codec<T> codec, bool move) {
    if (move) _entries.moveNext();

    final entry = _entries.current;
    Object source() => entry.value;

    _context._pushSource(source);
    final decoded = codec.decode(_context);
    _context._popSource();

    return (entry.key, decoded);
  }
}

class _JsonSequenceDeserializer<V> implements SequenceDeserializer<V> {
  final JsonDeserializer _context;
  final Codec<V> _elementCodec;
  final Iterator<dynamic> _entries;

  _JsonSequenceDeserializer(this._context, this._elementCodec, List<dynamic> list) : _entries = list.iterator;

  @override
  bool moveNext() => _entries.moveNext();

  @override
  V element() {
    final serialized = _entries.current;
    Object source() => serialized;

    _context._pushSource(source);
    final decoded = _elementCodec.decode(_context);
    _context._popSource();

    return decoded;
  }
}

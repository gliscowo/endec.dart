import 'dart:typed_data';

import 'package:endec/endec.dart';
import 'package:endec_edm/endec_edm.dart';

T fromEdm<T>(Endec<T> endec, EdmElement serialized, {SerializationContext ctx = SerializationContext.empty}) =>
    endec.decode(ctx, EdmDeserializer(serialized));

class EdmDeserializer extends RecursiveDeserializer<EdmElement> {
  EdmDeserializer(super.serialized);

  @override
  int i8(SerializationContext ctx) => currentValue().cast();
  @override
  int u8(SerializationContext ctx) => currentValue().cast();

  @override
  int i16(SerializationContext ctx) => currentValue().cast();
  @override
  int u16(SerializationContext ctx) => currentValue().cast();

  @override
  int i32(SerializationContext ctx) => currentValue().cast();
  @override
  int u32(SerializationContext ctx) => currentValue().cast();

  @override
  int i64(SerializationContext ctx) => currentValue().cast();
  @override
  int u64(SerializationContext ctx) => currentValue().cast();

  @override
  double f32(SerializationContext ctx) => currentValue().cast();
  @override
  double f64(SerializationContext ctx) => currentValue().cast();

  @override
  bool boolean(SerializationContext ctx) => currentValue().cast();
  @override
  String string(SerializationContext ctx) => currentValue().cast();
  @override
  Uint8List bytes(SerializationContext ctx) => currentValue().cast();

  @override
  E? optional<E>(SerializationContext ctx, Endec<E> endec) {
    final element = currentValue();
    if (element.value != null) {
      return frame(() => element.value, () => endec.decode(ctx, this));
    }

    return null;
  }

  @override
  SequenceDeserializer<E> sequence<E>(SerializationContext ctx, Endec<E> elementEndec) =>
      _EdmSequenceDeserializer(this, ctx, elementEndec, currentValue().cast());

  @override
  MapDeserializer<V> map<V>(SerializationContext ctx, Endec<V> valueEndec) =>
      _EdmMapDeserializer.map(this, ctx, valueEndec, currentValue().cast());

  @override
  StructDeserializer struct() => _EdmMapDeserializer.struct(this, currentValue().cast());
}

class _EdmSequenceDeserializer<V> implements SequenceDeserializer<V> {
  final EdmDeserializer _deserializer;
  final SerializationContext _ctx;
  final Endec<V> _elementEndec;

  final Iterator<EdmElement> _elements;

  _EdmSequenceDeserializer(this._deserializer, this._ctx, this._elementEndec, List<EdmElement> elements)
      : _elements = elements.iterator;

  @override
  bool moveNext() => _elements.moveNext();

  @override
  V element() => _deserializer.frame(
        () => _elements.current,
        () => _elementEndec.decode(_ctx, _deserializer),
      );
}

class _EdmMapDeserializer<V> implements MapDeserializer<V>, StructDeserializer {
  final EdmDeserializer _deserializer;
  final SerializationContext? _ctx;
  final Endec<V>? _valueEndec;

  final Map<String, EdmElement> _map;
  final Iterator<MapEntry<String, EdmElement>>? _entries;

  _EdmMapDeserializer.map(this._deserializer, this._ctx, this._valueEndec, this._map)
      : _entries = _map.entries.iterator;

  _EdmMapDeserializer.struct(this._deserializer, this._map)
      : _ctx = null,
        _valueEndec = null,
        _entries = null;

  @override
  bool moveNext() => _entries!.moveNext();

  @override
  (String, V) entry() => _deserializer.frame(
        () => _entries!.current.value,
        () => (_entries!.current.key, _valueEndec!.decode(_ctx!, _deserializer)),
      );

  @override
  F field<F>(String name, SerializationContext ctx, Endec<F> endec, {F Function()? defaultValueFactory}) {
    final value = _map[name];
    if (value == null) {
      if (defaultValueFactory != null) return defaultValueFactory();
      throw 'Required Field $name is missing from serialized data';
    }

    return _deserializer.frame(
      () => value,
      () => endec.decode(ctx, _deserializer),
    );
  }
}

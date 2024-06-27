import 'dart:typed_data';

import 'package:endec/endec.dart';
import 'package:endec_edm/endec_edm.dart';

EdmElement toEdm<T, S extends T>(Endec<T> endec, S value, {SerializationContext ctx = SerializationContext.empty}) {
  final serializer = EdmSerializer();
  endec.encode(ctx, serializer, value);
  return serializer.result;
}

class EdmSerializer extends RecursiveSerializer<EdmElement> {
  @override
  final bool selfDescribing = true;

  EdmSerializer() : super(EdmElement.map(const {}));

  @override
  void i8(SerializationContext ctx, int value) => consume(EdmElement.i8(value));
  @override
  void u8(SerializationContext ctx, int value) => consume(EdmElement.u8(value));

  @override
  void i16(SerializationContext ctx, int value) => consume(EdmElement.i16(value));
  @override
  void u16(SerializationContext ctx, int value) => consume(EdmElement.u16(value));

  @override
  void i32(SerializationContext ctx, int value) => consume(EdmElement.i32(value));
  @override
  void u32(SerializationContext ctx, int value) => consume(EdmElement.u32(value));

  @override
  void i64(SerializationContext ctx, int value) => consume(EdmElement.i64(value));
  @override
  void u64(SerializationContext ctx, int value) => consume(EdmElement.u64(value));

  @override
  void f32(SerializationContext ctx, double value) => consume(EdmElement.f32(value));
  @override
  void f64(SerializationContext ctx, double value) => consume(EdmElement.f64(value));

  @override
  void boolean(SerializationContext ctx, bool value) => consume(EdmElement.boolean(value));
  @override
  void string(SerializationContext ctx, String value) => consume(EdmElement.string(value));
  @override
  void bytes(SerializationContext ctx, Uint8List bytes) => consume(EdmElement.bytes(bytes));

  @override
  void optional<E>(SerializationContext ctx, Endec<E> endec, E? value) {
    EdmElement? result;
    frame((holder) {
      if (value == null) return;

      endec.encode(ctx, this, value);
      result = holder.get;
    });

    consume(EdmElement.optional(result));
  }

  @override
  SequenceSerializer<E> sequence<E>(SerializationContext ctx, Endec<E> elementEndec, int length) =>
      _EdmSequenceSerializer(this, ctx, elementEndec);
  @override
  MapSerializer<V> map<V>(SerializationContext ctx, Endec<V> valueEndec, int length) =>
      _EdmMapSerializer.map(this, ctx, valueEndec);
  @override
  StructSerializer struct() => _EdmMapSerializer.struct(this);
}

class _EdmSequenceSerializer<V> implements SequenceSerializer<V> {
  final EdmSerializer _serializer;
  final SerializationContext _ctx;
  final Endec<V> _elementEndec;

  final List<EdmElement> _result = [];

  _EdmSequenceSerializer(this._serializer, this._ctx, this._elementEndec);

  @override
  void element(V element) => _serializer.frame((holder) {
        _elementEndec.encode(_ctx, _serializer, element);
        _result.add(holder.require('sequence element'));
      });

  @override
  void end() => _serializer.consume(EdmElement.sequence(_result));
}

class _EdmMapSerializer<V> implements MapSerializer<V>, StructSerializer {
  final EdmSerializer _serializer;
  final SerializationContext? _ctx;
  final Endec<V>? _valueEndec;

  final Map<String, EdmElement> _result = {};

  _EdmMapSerializer.map(this._serializer, this._ctx, this._valueEndec);
  _EdmMapSerializer.struct(this._serializer)
      : _ctx = null,
        _valueEndec = null;

  @override
  void entry(String key, V value) => _serializer.frame((holder) {
        _valueEndec!.encode(_ctx!, _serializer, value);
        _result[key] = holder.require('map value');
      });

  @override
  void field<F, _V extends F>(
    String name,
    SerializationContext ctx,
    Endec<F> endec,
    _V value, {
    bool optional = false,
  }) =>
      _serializer.frame(
        (holder) {
          endec.encode(ctx, _serializer, value);
          _result[name] = holder.require('struct field');
        },
        isOptionalStructField: optional,
      );

  @override
  void end() => _serializer.consume(EdmElement.map(_result));
}

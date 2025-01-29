@experimental
library;

import 'dart:typed_data';

import 'package:endec/endec.dart';
import 'package:meta/meta.dart';

String toJson<T, S extends T>(Endec<T> endec, S value, {SerializationContext ctx = SerializationContext.empty}) {
  final serializer = JsonStringSerializer();
  endec.encode(ctx, serializer, value);
  return serializer._writer.buildResult();
}

class JsonStringSerializer implements SelfDescribingSerializer {
  final BlockWriter _writer = BlockWriter();

  JsonStringSerializer();

  String _escapedString(String content) => '"${content.replaceAll('"', r'\"')}"';

  @override
  void i8(SerializationContext ctx, int value) => _writer.write(value.toString());
  @override
  void u8(SerializationContext ctx, int value) => _writer.write(value.toString());

  @override
  void i16(SerializationContext ctx, int value) => _writer.write(value.toString());
  @override
  void u16(SerializationContext ctx, int value) => _writer.write(value.toString());

  @override
  void i32(SerializationContext ctx, int value) => _writer.write(value.toString());
  @override
  void u32(SerializationContext ctx, int value) => _writer.write(value.toString());

  @override
  void i64(SerializationContext ctx, int value) => _writer.write(value.toString());
  @override
  void u64(SerializationContext ctx, int value) => _writer.write(value.toString());

  @override
  void f32(SerializationContext ctx, double value) => _writer.write(value.toString());
  @override
  void f64(SerializationContext ctx, double value) => _writer.write(value.toString());

  @override
  void boolean(SerializationContext ctx, bool value) => _writer.write(value.toString());
  @override
  void string(SerializationContext ctx, String value) => _writer.write(_escapedString(value));
  @override
  void bytes(SerializationContext ctx, Uint8List bytes) =>
      _writer.write('[${bytes.map((e) => e.toString()).join(', ')}]');
  @override
  void optional<E>(SerializationContext ctx, Endec<E> endec, E? value) {
    if (value != null) {
      endec.encode(ctx, this, value);
    } else /*if (!isWritingOptionalStructField)*/ {
      _writer.write('null');
    }
  }

  @override
  SequenceSerializer<E> sequence<E>(SerializationContext ctx, Endec<E> elementEndec, int length) {
    _writer.startBlock('[', ']');
    return _JsonStringSequenceSerializer(this, ctx, elementEndec);
  }

  @override
  MapSerializer<V> map<V>(SerializationContext ctx, Endec<V> valueEndec, int length) {
    _writer.startBlock('{', '}');
    return _JsonStringMapSerializer.map(this, ctx, valueEndec);
  }

  @override
  StructSerializer struct() {
    _writer.startBlock('{', '}');
    return _JsonStringMapSerializer.struct(this);
  }
}

class _JsonStringMapSerializer<V> implements MapSerializer<V>, StructSerializer {
  final JsonStringSerializer _serializer;
  final SerializationContext? _ctx;
  final Endec<V>? _valueEndec;
  bool _hadElement = false;

  _JsonStringMapSerializer.map(this._serializer, this._ctx, Endec<V> valueEndec) : _valueEndec = valueEndec;
  _JsonStringMapSerializer.struct(this._serializer)
      : _ctx = null,
        _valueEndec = null;

  @override
  void entry(String key, V value) {
    if (_hadElement) _serializer._writer.write(', ');

    _serializer._writer.write('${_serializer._escapedString(key)}: ');
    _valueEndec!.encode(_ctx!, _serializer, value);
    _hadElement = true;
  }

  @override
  void field<F, _V extends F>(String key, SerializationContext ctx, Endec<F> endec, _V value, {bool mayOmit = false}) {
    if (_hadElement) _serializer._writer.writeln(', ');
    _serializer._writer.write('${_serializer._escapedString(key)}: ');
    endec.encode(ctx, _serializer, value);
    _hadElement = true;
  }

  @override
  void end() => _serializer._writer.endBlock();
}

class _JsonStringSequenceSerializer<V> implements SequenceSerializer<V> {
  final JsonStringSerializer _serializer;
  final SerializationContext _ctx;
  final Endec<V> _elementEndec;
  bool _hadElement = false;

  _JsonStringSequenceSerializer(this._serializer, this._ctx, this._elementEndec);

  @override
  void element(V value) {
    if (_hadElement) _serializer._writer.writeln(', ');

    _elementEndec.encode(_ctx, _serializer, value);
    _hadElement = true;
  }

  @override
  void end() => _serializer._writer.endBlock();
}

class JsonEncodeError extends Error {
  final String message;
  JsonEncodeError(this.message);

  @override
  String toString() => "JSON encoding failed: $message";
}

void main(List<String> args) {
  final endec = structEndec<(int, bool, List<String>, Map<String, double>)>().with4Fields(
    Endec.i32.fieldOf('f1', (struct) => struct.$1),
    Endec.bool.fieldOf('f2', (struct) => struct.$2),
    Endec.string.listOf().fieldOf('f3', (struct) => struct.$3),
    Endec.f64.mapOf().fieldOf('f4', (struct) => struct.$4),
    (p0, p1, p2, p3) => (p0, p1, p2, p3),
  );

  final json = toJson(endec, (1256, false, ["that's", "a string", "yep"], {"field": 6.9}));
  print(json);
}

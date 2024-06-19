@experimental
library json_string_serializer;

import 'dart:collection';
import 'dart:typed_data';

import 'package:endec/endec.dart';
import 'package:meta/meta.dart';

String toJson<T, S extends T>(Endec<T> endec, S value) {
  final serializer = JsonStringSerializer();
  endec.encode(serializer, value);
  return serializer._writer.toString();
}

class JsonStringSerializer implements Serializer {
  @override
  final bool selfDescribing = false;
  final _JsonWriter _writer = _JsonWriter();

  JsonStringSerializer();

  @override
  void i8(int value) => _writer.write(value.toString());
  @override
  void u8(int value) => _writer.write(value.toString());

  @override
  void i16(int value) => _writer.write(value.toString());
  @override
  void u16(int value) => _writer.write(value.toString());

  @override
  void i32(int value) => _writer.write(value.toString());
  @override
  void u32(int value) => _writer.write(value.toString());

  @override
  void i64(int value) => _writer.write(value.toString());
  @override
  void u64(int value) => _writer.write(value.toString());

  @override
  void f32(double value) => _writer.write(value.toString());
  @override
  void f64(double value) => _writer.write(value.toString());

  @override
  void boolean(bool value) => _writer.write(value.toString());
  @override
  void string(String value) => _writer.write('"$value"');
  @override
  void bytes(Uint8List bytes) => _writer.write('[${bytes.map((e) => e.toString()).join(', ')}]');
  @override
  void optional<E>(Endec<E> endec, E? value) {
    if (value != null) {
      endec.encode(this, value);
    } else /*if (!isWritingOptionalStructField)*/ {
      _writer.write('null');
    }
  }

  @override
  SequenceSerializer<E> sequence<E>(Endec<E> elementEndec, int length) {
    _writer.startBlock('[', ']');
    return _JsonStringSequenceSerializer(this, elementEndec);
  }

  @override
  MapSerializer<V> map<V>(Endec<V> valueEndec, int length) {
    _writer.startBlock('{', '}');
    return _JsonStringMapSerializer.map(this, valueEndec);
  }

  @override
  StructSerializer struct() {
    _writer.startBlock('{', '}');
    return _JsonStringMapSerializer.struct(this);
  }
}

class _JsonStringMapSerializer<V> implements MapSerializer<V>, StructSerializer {
  final JsonStringSerializer _context;
  final Endec<V>? _valueEndec;
  bool _hadElement = false;

  _JsonStringMapSerializer.map(this._context, Endec<V> valueEndec) : _valueEndec = valueEndec;
  _JsonStringMapSerializer.struct(this._context) : _valueEndec = null;

  @override
  void entry(String key, V value) {
    if (_hadElement) _context._writer.write(', ');

    _context._writer.write('"$key": ');
    _valueEndec!.encode(_context, value);
    _hadElement = true;
  }

  @override
  void field<F, _V extends F>(String key, Endec<F> endec, _V value, {bool optional = false}) {
    if (_hadElement) _context._writer.writeln(', ');
    _context._writer.write('"$key": ');
    endec.encode(_context, value);
    _hadElement = true;
  }

  @override
  void end() => _context._writer.endBlock();
}

class _JsonStringSequenceSerializer<V> implements SequenceSerializer<V> {
  final JsonStringSerializer _context;
  final Endec<V> _elementEndec;
  bool _hadElement = false;

  _JsonStringSequenceSerializer(this._context, this._elementEndec);

  @override
  void element(V value) {
    if (_hadElement) _context._writer.writeln(', ');

    _elementEndec.encode(_context, value);
    _hadElement = true;
  }

  @override
  void end() => _context._writer.endBlock();
}

class _JsonWriter {
  final StringBuffer _result = StringBuffer();
  final Queue<String> _blocks = Queue();
  int indentLevel = 0;

  String escape(String input) {
    return input.replaceAll('"', r'\"');
  }

  void write(String value) => _result.write(value);
  void writeln([String value = ""]) => _result.write("$value\n${"  " * indentLevel}");

  void startBlock(String startDelimiter, String endDelimiter) {
    indentLevel++;
    _blocks.addLast(endDelimiter);

    writeln(startDelimiter);
  }

  void endBlock() {
    indentLevel--;

    writeln();
    write(_blocks.removeLast());
  }

  @override
  String toString() => _result.toString();
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

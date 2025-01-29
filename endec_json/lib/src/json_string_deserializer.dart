@experimental
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:endec/endec.dart';
import 'package:meta/meta.dart';

class JsonStringDeserializer implements Deserializer {
  static const _numberInitial = {_TokenType.digit, _TokenType.minus};
  static const _number = {..._numberInitial, _TokenType.dot, _TokenType.e, _TokenType.plus};
  static const _bool = {_TokenType.literalTrue, _TokenType.literalFalse};

  final String _input;

  _TokenType? _tokenCache;
  int _pointer = 0;

  JsonStringDeserializer(String input) : _input = input.trimLeft();

  _TokenType get _currentToken => _tokenCache ??= _TokenType.forChar(_input[_pointer]);
  void _advance([int by = 1]) => _movePointer(_pointer + by);

  void _movePointer(int to) {
    _pointer = to;
    _tokenCache = null;
  }

  void _skipWhitespace() {
    while (_currentToken == _TokenType.whitespace) {
      _advance();
    }
  }

  num _parseNumber() {
    _skipWhitespace();
    if (!_numberInitial.contains(_currentToken)) throw 'Expected a number, found: $_currentToken';

    final numberBegin = _pointer;
    while (_number.contains(_currentToken)) {
      _advance();
    }

    return jsonDecode(_input.substring(numberBegin, _pointer)) as num;
  }

  bool _parseBool() {
    _skipWhitespace();
    if (!_bool.contains(_currentToken)) throw 'Expected "true" or "false", found: $_currentToken';

    if (_currentToken == _TokenType.literalTrue) {
      if (_input.substring(_pointer, _pointer + 4) != 'true') {
        throw 'Encountered unexpected char while parsing boolean true';
      }

      _advance(4);
      return true;
    } else {
      if (_input.substring(_pointer, _pointer + 5) != 'false') {
        throw 'Encountered unexpected char while parsing boolean false';
      }

      _advance(5);
      return true;
    }
  }

  String _parseString() {
    _skipWhitespace();
    if (_currentToken != _TokenType.quote) throw 'Expected string, found: $_currentToken';

    final stringBegin = _pointer;
    _advance();
    while (_currentToken != _TokenType.quote || _input[_pointer - 1] == r'\') {
      _advance();
    }
    _advance();

    return jsonDecode(_input.substring(stringBegin, _pointer)) as String;
  }

  // @override
  // void any(Serializer visitor) {
  //   switch (_currentToken) {
  //     case _TokenType.digit || _TokenType.minus:
  //       final number = _parseNumber();
  //       if (number is int) {
  //         visitor.i64(number);
  //       } else {
  //         visitor.f64(number as double);
  //       }
  //     case _TokenType.literalTrue || _TokenType.literalFalse:
  //       visitor.boolean(_parseBool());
  //     case _TokenType.literalNull:
  //       final endec = Endec.of((serializer, value) {}, (deserializer) => null);
  //       optional(endec);
  //       visitor.optional(endec, null);
  //     case _TokenType.quote:
  //       visitor.string(_parseString());
  //     case _TokenType.arrayBegin:
  //       final state = visitor.sequence(Endec.of((serializer, value) => any(serializer), (deserializer) => null), )

  //   }
  // }

  //TODO: size checks
  @override
  int i8(SerializationContext ctx) => _parseNumber() as int;
  @override
  int u8(SerializationContext ctx) => _parseNumber() as int;

  @override
  int i16(SerializationContext ctx) => _parseNumber() as int;
  @override
  int u16(SerializationContext ctx) => _parseNumber() as int;

  @override
  int i32(SerializationContext ctx) => _parseNumber() as int;
  @override
  int u32(SerializationContext ctx) => _parseNumber() as int;

  @override
  int i64(SerializationContext ctx) => _parseNumber() as int;
  @override
  int u64(SerializationContext ctx) => _parseNumber() as int;

  @override
  double f32(SerializationContext ctx) => _parseNumber() as double;
  @override
  double f64(SerializationContext ctx) => _parseNumber() as double;

  @override
  bool boolean(SerializationContext ctx) => _parseBool();
  @override
  String string(SerializationContext ctx) => _parseString();
  @override
  Uint8List bytes(SerializationContext ctx) => Uint8List.fromList(Endec.u8.listOf().decode(ctx, this));
  @override
  E? optional<E>(SerializationContext ctx, Endec<E> endec) {
    _skipWhitespace();
    if (_currentToken == _TokenType.literalNull) {
      if (_input.substring(_pointer, _pointer + 4) != 'null') {
        throw 'Encountered unexpected char while parsing "null"';
      }

      _advance(4);
      return null;
    } else {
      return endec.decode(ctx, this);
    }
  }

  @override
  SequenceDeserializer<E> sequence<E>(SerializationContext ctx, Endec<E> elementEndec) {
    if (_currentToken != _TokenType.arrayBegin) throw 'Expected array, found: $_currentToken';

    _advance();
    _skipWhitespace();
    return _JsonStringArrayDeserializer(this, ctx, elementEndec);
  }

  @override
  MapDeserializer<V> map<V>(SerializationContext ctx, Endec<V> valueEndec) {
    if (_currentToken != _TokenType.objectBegin) throw 'Expected object, found: $_currentToken';

    _advance();
    _skipWhitespace();
    return _JsonStringObjectDeserializer(this, ctx, valueEndec);
  }

  @override
  StructDeserializer struct(SerializationContext ctx) {
    if (_currentToken != _TokenType.objectBegin) throw 'Expected object, found: $_currentToken';

    _advance();
    _skipWhitespace();
    return _JsonStructDeserializer(this);
  }

  @override
  V tryRead<V>(V Function(Deserializer deserializer) reader) {
    final prevPointer = _pointer;

    try {
      return reader(this);
    } catch (_) {
      _pointer = prevPointer;
      rethrow;
    }
  }
}

class _JsonStringArrayDeserializer<V> implements SequenceDeserializer<V> {
  static const _arrayParts = {_TokenType.arrayEnd, _TokenType.elementSeparator};

  final Iterator<V> _elements;

  _JsonStringArrayDeserializer(JsonStringDeserializer deserializer, SerializationContext ctx, Endec<V> elementEndec)
      : _elements = _parser(deserializer, ctx, elementEndec).iterator;

  static Iterable<V> _parser<V>(
    JsonStringDeserializer deserializer,
    SerializationContext ctx,
    Endec<V> elementEndec,
  ) sync* {
    while (deserializer._currentToken != _TokenType.arrayEnd) {
      yield elementEndec.decode(ctx, deserializer);

      deserializer._skipWhitespace();
      if (!_arrayParts.contains(deserializer._currentToken)) {
        throw 'Expected "," for next element or "]" to close array, found ${deserializer._currentToken}';
      }

      if (deserializer._currentToken == _TokenType.elementSeparator) deserializer._advance();
      deserializer._skipWhitespace();
    }

    deserializer._advance();
  }

  @override
  V element() => _elements.current;

  @override
  bool moveNext() => _elements.moveNext();
}

class _JsonStringObjectDeserializer<V> implements MapDeserializer<V> {
  static const _objectParts = {_TokenType.objectEnd, _TokenType.elementSeparator};

  final Iterator<(String, V)> _elements;

  _JsonStringObjectDeserializer(JsonStringDeserializer deserializer, SerializationContext ctx, Endec<V> elementEndec)
      : _elements = _parser(deserializer, ctx, elementEndec).iterator;

  static Iterable<(String, V)> _parser<V>(
    JsonStringDeserializer deserializer,
    SerializationContext ctx,
    Endec<V> elementEndec,
  ) sync* {
    while (deserializer._currentToken != _TokenType.objectEnd) {
      final key = deserializer._parseString();
      deserializer._skipWhitespace();
      if (deserializer._currentToken != _TokenType.keyValueSeparator) {
        throw 'Expected ":" to separate key from value, found ${deserializer._currentToken}';
      }

      deserializer._advance();
      deserializer._skipWhitespace();
      yield (key, elementEndec.decode(ctx, deserializer));

      deserializer._skipWhitespace();
      if (!_objectParts.contains(deserializer._currentToken)) {
        throw 'Expected "," for next entry or "}" to close object, found ${deserializer._currentToken}';
      }

      if (deserializer._currentToken == _TokenType.elementSeparator) deserializer._advance();
      deserializer._skipWhitespace();
    }

    deserializer._advance();
  }

  @override
  (String, V) entry() => _elements.current;

  @override
  bool moveNext() => _elements.moveNext();
}

class _JsonStructDeserializer implements StructDeserializer {
  static const _objectParts = {_TokenType.objectEnd, _TokenType.elementSeparator};

  final JsonStringDeserializer _deserializer;
  final Map<String, int> _valueIndicesByKey = {};

  _JsonStructDeserializer(this._deserializer);

  @override
  F field<F>(String name, SerializationContext ctx, Endec<F> endec, {F Function()? defaultValueFactory}) {
    if (_valueIndicesByKey[name] case var idx?) {
      final prevPointer = _deserializer._pointer;

      _deserializer._movePointer(idx);
      final result = endec.decode(ctx, _deserializer);
      _skipAfterValue();
      _deserializer._movePointer(prevPointer);

      return result;
    }

    while (true) {
      var key = _deserializer._parseString();
      _deserializer._skipWhitespace();
      if (_deserializer._currentToken != _TokenType.keyValueSeparator) {
        throw 'Expected ":" to separate key from value, found ${_deserializer._currentToken}';
      }

      _deserializer._advance();
      _deserializer._skipWhitespace();

      if (key == name) {
        final result = endec.decode(ctx, _deserializer);
        _skipAfterValue();

        return result;
      } else {
        _valueIndicesByKey[key] = _deserializer._pointer;
        _skipValue();
      }
    }
  }

  void _skipValue() {
    var arrayDepth = 0, objectDepth = 0;
    while (true) {
      switch (_deserializer._currentToken) {
        case _TokenType.objectBegin:
          objectDepth++;
          _deserializer._advance();
        case _TokenType.arrayBegin:
          arrayDepth++;
          _deserializer._advance();
        case _TokenType.objectEnd:
          if (objectDepth == 0) {
            return;
          } else {
            objectDepth--;
            _deserializer._advance();
          }
        case _TokenType.arrayEnd:
          arrayDepth--;
          _deserializer._advance();
        case _TokenType.elementSeparator:
          _deserializer._advance();

          if (objectDepth == 0 && arrayDepth == 0) {
            return;
          }
        default:
          _deserializer._advance();
      }
    }
  }

  void _skipAfterValue() {
    _deserializer._skipWhitespace();
    if (!_objectParts.contains(_deserializer._currentToken)) {
      throw 'Expected "," for next entry or "}" to close object, found ${_deserializer._currentToken}';
    }

    if (_deserializer._currentToken == _TokenType.elementSeparator) _deserializer._advance();
    _deserializer._skipWhitespace();
  }
}

enum _TokenType {
  elementSeparator,
  objectBegin,
  objectEnd,
  arrayBegin,
  arrayEnd,
  quote,
  digit,
  plus,
  minus,
  e,
  keyValueSeparator,
  dot,
  literalTrue,
  literalFalse,
  literalNull,
  whitespace,
  other;

  static _TokenType forChar(String char) => switch (char) {
        ',' => _TokenType.elementSeparator,
        '{' => _TokenType.objectBegin,
        '}' => _TokenType.objectEnd,
        '[' => _TokenType.arrayBegin,
        ']' => _TokenType.arrayEnd,
        '"' => _TokenType.quote,
        '0' || '1' || '2' || '3' || '4' || '5' || '6' || '7' || '8' || '9' || '0' => _TokenType.digit,
        '+' => _TokenType.plus,
        '-' => _TokenType.minus,
        'e' || 'E' => _TokenType.e,
        ':' => _TokenType.keyValueSeparator,
        '.' => _TokenType.dot,
        ' ' || '\n' || '\r' || '\t' => _TokenType.whitespace,
        't' => _TokenType.literalTrue,
        'f' => _TokenType.literalFalse,
        'n' => _TokenType.literalNull,
        _ => _TokenType.other,
      };
}

void main(List<String> args) {
//   final result = Endec.i32.listOf().mapOf().mapOf().decode(
//         SerializationContext.empty,
//         JsonStringDeserializer(r'''
// {
//   "a": {"_": [1]},
//   "b": {"_": [2, 3], "-": [3, 2]},
//   "c": {"_": [4, 5, 6]}
// }
// '''),
//       );

  final endec = structEndec<(int, String, List<Map<double, bool>>)>().with3Fields(
    Endec.i32.fieldOf('int', (struct) => struct.$1),
    Endec.string.fieldOf('string', (struct) => struct.$2),
    Endec.map((d) => d.toString(), double.parse, Endec.bool).listOf().fieldOf('bruh', (struct) => struct.$3),
    (p0, p1, p2) => (p0, p1, p2),
  );

  final result = endec.decode(
    SerializationContext.empty,
    JsonStringDeserializer(r'''
{
  "string": "bruh",
  "bruh": [
    {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false}
  ],
  "int": 69
}
'''),
  );
  print(result);
}

void main1(List<String> args) {
  final jsonString = r'7';
  final json = jsonDecode(jsonString);
  print(jsonString);
  print(json);
  print(json.runtimeType);

  // print(double.parse(source))
}

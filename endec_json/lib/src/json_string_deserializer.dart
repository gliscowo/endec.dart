import 'dart:convert';
import 'dart:typed_data';

import 'package:endec/endec.dart';

class JsonStringDeserializer implements Deserializer {
  static const _numberInitial = {_TokenType.digit, _TokenType.minus};
  static const _number = {..._numberInitial, _TokenType.dot, _TokenType.e, _TokenType.plus};
  static const _bool = {_TokenType.literalTrue, _TokenType.literalFalse};

  final String _input;

  _TokenType? _tokenCache;
  int _pointer = 0;

  JsonStringDeserializer(String input) : _input = input.trimLeft();

  _TokenType get _currentToken => _tokenCache ??= _TokenType.forChar(_input[_pointer]);
  void _advance([int by = 1]) {
    _pointer += by;
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
  int i8() => _parseNumber() as int;
  @override
  int u8() => _parseNumber() as int;

  @override
  int i16() => _parseNumber() as int;
  @override
  int u16() => _parseNumber() as int;

  @override
  int i32() => _parseNumber() as int;
  @override
  int u32() => _parseNumber() as int;

  @override
  int i64() => _parseNumber() as int;
  @override
  int u64() => _parseNumber() as int;

  @override
  double f32() => _parseNumber() as double;
  @override
  double f64() => _parseNumber() as double;

  @override
  bool boolean() => _parseBool();
  @override
  String string() => _parseString();
  @override
  Uint8List bytes() => Uint8List.fromList(Endec.u8.listOf().decode(this));
  @override
  E? optional<E>(Endec<E> endec) {
    _skipWhitespace();
    if (_currentToken == _TokenType.literalNull) {
      if (_input.substring(_pointer, _pointer + 4) != 'null') {
        throw 'Encountered unexpected char while parsing "null"';
      }

      _advance(4);
      return null;
    } else {
      return endec.decode(this);
    }
  }

  @override
  SequenceDeserializer<E> sequence<E>(Endec<E> elementEndec) {
    if (_currentToken != _TokenType.arrayBegin) throw 'Expected array, found: $_currentToken';

    _advance();
    _skipWhitespace();
    return _JsonStringArrayDeserializer(this, elementEndec);
  }

  @override
  MapDeserializer<V> map<V>(Endec<V> valueEndec) {
    if (_currentToken != _TokenType.objectBegin) throw 'Expected object, found: $_currentToken';

    _advance();
    _skipWhitespace();
    return _JsonStringObjectDeserializer(this, valueEndec);
  }

  @override
  StructDeserializer struct() => throw UnimplementedError();

  @override
  tryRead<V>(V Function(Deserializer deserializer) reader) {
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

  _JsonStringArrayDeserializer(JsonStringDeserializer context, Endec<V> elementEndec)
      : _elements = _generator(context, elementEndec).iterator;

  static Iterable<V> _generator<V>(JsonStringDeserializer context, Endec<V> elementEndec) sync* {
    while (context._currentToken != _TokenType.arrayEnd) {
      yield elementEndec.decode(context);

      context._skipWhitespace();
      if (!_arrayParts.contains(context._currentToken)) {
        throw 'Expected "," for next element or "]" to close array, found ${context._currentToken}';
      }

      if (context._currentToken == _TokenType.elementSeparator) context._advance();
      context._skipWhitespace();
    }

    context._advance();
  }

  @override
  V element() => _elements.current;

  @override
  bool moveNext() => _elements.moveNext();
}

class _JsonStringObjectDeserializer<V> implements MapDeserializer<V> {
  static const _objectParts = {_TokenType.objectEnd, _TokenType.elementSeparator};

  final Iterator<(String, V)> _elements;

  _JsonStringObjectDeserializer(JsonStringDeserializer context, Endec<V> elementEndec)
      : _elements = _generator(context, elementEndec).iterator;

  static Iterable<(String, V)> _generator<V>(JsonStringDeserializer context, Endec<V> elementEndec) sync* {
    while (context._currentToken != _TokenType.objectEnd) {
      final key = context._parseString();
      context._skipWhitespace();
      if (context._currentToken != _TokenType.keyValueSeparator) {
        throw 'Expected ":" to separate key from value, found ${context._currentToken}';
      }

      context._advance();
      context._skipWhitespace();
      yield (key, elementEndec.decode(context));

      context._skipWhitespace();
      if (!_objectParts.contains(context._currentToken)) {
        throw 'Expected "," for next entry or "}" to close object, found ${context._currentToken}';
      }

      if (context._currentToken == _TokenType.elementSeparator) context._advance();
      context._skipWhitespace();
    }

    context._advance();
  }

  @override
  (String, V) entry() => _elements.current;

  @override
  bool moveNext() => _elements.moveNext();
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
  final result = Endec.i32.listOf().mapOf().mapOf().decode(JsonStringDeserializer(r'''
{
  "a": {"_": [1]},
  "b": {"_": [2, 3], "-": [3, 2]}, 
  "c": {"_": [4, 5, 6]}
}
'''));
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

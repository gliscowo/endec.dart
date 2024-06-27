import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:endec/endec.dart';

import 'nbt_types.dart';

NbtElement snbtToNbt(String snbt) => _SnbtReader(snbt).parseElement();

extension ToSnbt on NbtElement {
  String toSnbt() => nbtToSnbt(this);
}

String nbtToSnbt(NbtElement element) {
  String escape(String string) => string.replaceAll('"', r'\"');

  void stringify(BlockWriter writer, NbtElement element) {
    switch (element) {
      case NbtString(:var value):
        writer.write('"${escape(value)}"');
      case NbtByte(:var value):
        writer.write("${value}b");
      case NbtShort(:var value):
        writer.write("${value}s");
      case NbtInt(:var value):
        writer.write("$value");
      case NbtLong(:var value):
        writer.write("${value}L");
      case NbtFloat(:var value):
        writer.write("${value}f");
      case NbtDouble(:var value):
        writer.write("$value");
      case NbtByteArray(:var value):
        writer.write("[B; ${value.map((e) => "${e}b").join(", ")}]");
      case NbtIntArray(:var value):
        writer.write("[I; ${value.join(", ")}]");
      case NbtLongArray(:var value):
        writer.write("[L; ${value.map((e) => "${e}L").join(", ")}]");
      case NbtList(:var value):
        writer.startBlock('[', ']');
        for (final (idx, element) in value.indexed) {
          stringify(writer, element);
          if (idx < value.length - 1) writer.writeln(",");
        }
        writer.endBlock();
      case NbtCompound(value: var compound):
        writer.startBlock('{', '}');

        for (final (idx, MapEntry(:key, :value)) in compound.entries.indexed) {
          writer.write(NbtCompound.safeKeyRegex.hasMatch(key) ? "$key: " : '"${escape(key)}": ');
          stringify(writer, value);

          if (idx < compound.length - 1) writer.writeln(",");
        }

        writer.endBlock();
    }
  }

  final writer = BlockWriter();
  stringify(writer, element);
  return writer.buildResult();
}

class _SnbtReader {
  static final _unquotedStringRegex = RegExp(r"[a-zA-Z0-9_\+\.-]");

  final String _input;
  int _cursor = 0;

  _SnbtReader(String input) : _input = input.trim();

  String get current => String.fromCharCode(_input.codeUnitAt(_cursor));

  NbtElement parseElement() {
    skipWhitespace();
    return switch (current) { "{" => parseCompound(), "[" => parseArray(), _ => parsePrimitive() };
  }

  NbtCompound parseCompound() {
    var map = <String, NbtElement>{};

    _cursor++;

    skipWhitespace();
    while (current != "}") {
      skipWhitespace();

      var name = current == "'" || current == '"' ? consumeQuotedString() : consumeUnquotedString();
      if (name.isEmpty) {
        _fail("Entries in an NBT Compound require a non-empty name");
      }

      skipWhitespace();
      if (current != ":") {
        _fail("Name of entry in NBT Compound must be separated by colon");
      }

      _cursor++;
      map[name] = parseElement();

      skipWhitespace();
      if (current != ",") break;
      _cursor++;
    }

    skipWhitespace();
    if (current != "}") {
      _fail("Expected '}' to close compound");
    }

    _cursor++;
    return NbtCompound(map);
  }

  NbtElement parseArray() {
    if (expect("[B;")) {
      return NbtByteArray(Int8List.fromList(parsePrimitiveArrayElements(NbtElementType.byte)));
    } else if (expect("[I;")) {
      return NbtIntArray(Int32List.fromList(parsePrimitiveArrayElements(NbtElementType.int)));
    } else if (expect("[L;")) {
      return NbtLongArray(Int64List.fromList(parsePrimitiveArrayElements(NbtElementType.long)));
    } else {
      var list = <NbtElement>[];
      _cursor++;

      skipWhitespace();
      while (current != "]") {
        var element = parseElement();
        if (list.isNotEmpty && list.first.type != element.type) {
          _fail("All list elements must be of the same type");
        }

        list.add(element);

        skipWhitespace();
        if (current != ",") break;
        _cursor++;
      }

      skipWhitespace();
      if (current != "]") {
        _fail("Expected ']' to close array");
      }

      _cursor++;
      return NbtList(list);
    }
  }

  List<int> parsePrimitiveArrayElements(NbtElementType elementType) {
    skipWhitespace();

    var elements = <int>[];
    while (current != "]") {
      var element = parsePrimitive();
      if (element.type != elementType) {
        _fail("Invalid entry in array");
      }

      if (element is NbtByte) elements.add(element.value);
      if (element is NbtInt) elements.add(element.value);
      if (element is NbtLong) elements.add(element.value);

      skipWhitespace();
      if (current != ",") break;
      _cursor++;
    }

    skipWhitespace();
    if (current != "]") {
      _fail("Expected ']' to close array");
    }

    _cursor++;
    return elements;
  }

  NbtElement parsePrimitive() {
    skipWhitespace();
    if (current == "'" || current == '"') return NbtString(consumeQuotedString());

    final primitive = consumeUnquotedString();
    if (primitive.isEmpty) _fail("Expected an NBT element, found nothing");

    if (primitive == "true") return NbtByte(1);
    if (primitive == "false") return NbtByte(0);

    if (primitive.endsWith("d") || primitive.endsWith("D")) {
      if (double.tryParse(primitive.substring(0, primitive.length - 1)) case var value?) return NbtDouble(value);
    }
    if (primitive.endsWith("f") || primitive.endsWith("F")) {
      if (double.tryParse(primitive.substring(0, primitive.length - 1)) case var value?) return NbtFloat(value);
    }

    if (primitive.endsWith("b") || primitive.endsWith("B")) {
      if (int.tryParse(primitive.substring(0, primitive.length - 1)) case var value?) return NbtByte(value);
    }
    if (primitive.endsWith("s") || primitive.endsWith("S")) {
      if (int.tryParse(primitive.substring(0, primitive.length - 1)) case var value?) return NbtShort(value);
    }
    if (primitive.endsWith("l") || primitive.endsWith("L")) {
      if (int.tryParse(primitive.substring(0, primitive.length - 1)) case var value?) return NbtLong(value);
    }

    if (int.tryParse(primitive) case var value?) return NbtInt(value);
    if (double.tryParse(primitive) case var value?) return NbtDouble(value);

    return NbtString(primitive);
  }

  void skipWhitespace() => consumeWhile((char) => char.trim().isEmpty);

  String consumeUnquotedString() => consumeWhile((char) => _unquotedStringRegex.hasMatch(char));

  String consumeQuotedString() {
    final delimiter = current;
    _cursor++;

    final result = StringBuffer();
    bool escaped = false;

    while (true) {
      if (current == delimiter && !escaped) {
        _cursor++;
        break;
      }

      escaped = false;
      if (current == r"\") {
        escaped = true;
        _cursor++;
        continue;
      }

      result.writeCharCode(_input.codeUnitAt(_cursor));
      _cursor++;
    }

    return result.toString();
  }

  String consumeWhile(bool Function(String char) predicate) {
    final result = StringBuffer();
    while (predicate(current)) {
      result.writeCharCode(_input.codeUnitAt(_cursor));
      _cursor++;
    }

    return result.toString();
  }

  bool expect(String expected) {
    skipWhitespace();
    if (_cursor + expected.length >= _input.length) return false;

    if (_input.substring(_cursor, _cursor + expected.length) == expected) {
      _cursor += expected.length;
      return true;
    } else {
      return false;
    }
  }

  Never _fail(String reason) {
    _cursor -= _input.substring(0, _cursor).length - _input.substring(0, _cursor).trimRight().length;
    final contextString = _input.substring(max(_cursor - 45, 0), min(_cursor + 46, _input.length));

    var column = 45;
    if (_cursor - 45 < 0) column += _cursor - 45;

    var context = contextString.split("\n");

    int lineIdx = 0, chars = 0;
    for (final line in context) {
      chars += line.length + 1;
      if (column > chars) {
        lineIdx++;
      } else {
        column -= chars - line.length - 1;
        break;
      }
    }

    throw SnbtParsingException(context, reason, (lineIdx, column));
  }
}

class SnbtParsingException implements Exception {
  final List<String> context;
  final String reason;
  final (int, int) errorIndex;

  SnbtParsingException(this.context, this.reason, this.errorIndex);

  @override
  String toString() {
    final result = StringBuffer("$reason\n");
    for (var (idx, contextLine) in context.indexed) {
      result.writeln(contextLine);
      if (idx == errorIndex.$1) {
        result.writeln("${" " * errorIndex.$2}^ here");
      }
    }

    return result.toString();
  }
}

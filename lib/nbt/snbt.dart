import 'nbt_types.dart';

String nbtToString(NbtElement element) {
  final snbt = SnbtWriter();
  element.stringify(snbt);
  return snbt.toString();
}

class SnbtWriter {
  final StringBuffer _result = StringBuffer();
  int indentLevel = 0;

  String escape(String input) {
    return input.replaceAll('"', r'\"');
  }

  void write(String value) => _result.write(value);
  void writeln([String value = ""]) => _result.write("$value\n${"  " * indentLevel}");

  void openBlock(String delimiter) {
    indentLevel++;
    writeln(delimiter);
  }

  void closeBlock(String delimiter) {
    indentLevel--;

    writeln();
    write(delimiter);
  }

  @override
  String toString() => _result.toString();
}

// TODO: snbt reader
class SnbtReader {}

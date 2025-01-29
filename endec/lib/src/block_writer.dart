import 'dart:collection';

mixin class BlockWriter {
  final StringBuffer _result = StringBuffer();
  final Queue<String> _blocks = Queue();
  int _indentLevel = 0;

  factory BlockWriter() = _BlockWriter;

  void write(String value) => _result.write(value);
  void writeln([String value = ""]) => _result.write("$value\n${"  " * _indentLevel}");

  void startBlock(String startDelimiter, String endDelimiter) {
    _indentLevel++;
    _blocks.addLast(endDelimiter);

    writeln(startDelimiter);
  }

  void endBlock() {
    _indentLevel--;

    writeln();
    write(_blocks.removeLast());
  }

  String buildResult() => _result.toString();
}

class _BlockWriter with BlockWriter {
  _BlockWriter();
}

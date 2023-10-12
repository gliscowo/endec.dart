import 'dart:core' hide int;
import 'dart:core' as dart show int;
import 'dart:typed_data';

import 'nbt_io.dart';
import 'snbt.dart';

enum NbtElementType {
  end,
  byte,
  short,
  int,
  long,
  float,
  double,
  byteArray,
  string,
  list,
  compound,
  intArray,
  longArray;

  factory NbtElementType.byId(dart.int id) => NbtElementType.values.firstWhere((element) => element.index == id);
}

abstract base class NbtElement<T> {
  final T _value;
  const NbtElement(this._value);

  NbtElementType get type;
  void write(NbtWriter output);
  void stringify(SnbtWriter writer);

  T get value => _value;

  @override
  String toString() => _value.toString();
}

final class NbtString extends NbtElement<String> {
  @override
  final NbtElementType type = NbtElementType.string;

  NbtString(super._value);
  factory NbtString.read(NbtReader input) => NbtString(input.string());

  @override
  void write(NbtWriter output) => output.string(_value);
  @override
  void stringify(SnbtWriter writer) => writer.write('"${writer.escape(_value)}"');
}

// --- integer types ---

final class NbtByte extends NbtElement<dart.int> {
  @override
  final NbtElementType type = NbtElementType.byte;

  NbtByte(super._value);
  factory NbtByte.read(NbtReader input) => NbtByte(input.i8());

  @override
  void write(NbtWriter output) => output.i8(_value);
  @override
  void stringify(SnbtWriter writer) => writer.write("${_value}b");
}

final class NbtShort extends NbtElement<dart.int> {
  @override
  final NbtElementType type = NbtElementType.short;

  NbtShort(super._value);
  factory NbtShort.read(NbtReader input) => NbtShort(input.i16());

  @override
  void write(NbtWriter output) => output.i16(_value);
  @override
  void stringify(SnbtWriter writer) => writer.write("${_value}s");
}

final class NbtInt extends NbtElement<dart.int> {
  @override
  final NbtElementType type = NbtElementType.int;

  NbtInt(super._value);
  factory NbtInt.read(NbtReader input) => NbtInt(input.i32());

  @override
  void write(NbtWriter output) => output.i32(_value);
  @override
  void stringify(SnbtWriter writer) => writer.write("$_value");
}

final class NbtLong extends NbtElement<dart.int> {
  @override
  final NbtElementType type = NbtElementType.long;

  NbtLong(super._value);
  factory NbtLong.read(NbtReader input) => NbtLong(input.i64());

  @override
  void write(NbtWriter output) => output.i64(_value);
  @override
  void stringify(SnbtWriter writer) => writer.write("${_value}L");
}

// --- floating point types ---

final class NbtFloat extends NbtElement<double> {
  @override
  final NbtElementType type = NbtElementType.float;

  NbtFloat(super._value);
  factory NbtFloat.read(NbtReader input) => NbtFloat(input.f32());

  @override
  void write(NbtWriter output) => output.f32(_value);
  @override
  void stringify(SnbtWriter writer) => writer.write("${_value}f");
}

final class NbtDouble extends NbtElement<double> {
  @override
  final NbtElementType type = NbtElementType.double;

  NbtDouble(super._value);
  factory NbtDouble.read(NbtReader input) => NbtDouble(input.f64());

  @override
  void write(NbtWriter output) => output.f64(_value);
  @override
  void stringify(SnbtWriter writer) => writer.write("$_value");
}

// --- array types ---

final class NbtByteArray extends NbtElement<Uint8List> {
  @override
  final NbtElementType type = NbtElementType.byteArray;

  NbtByteArray(super._value);
  factory NbtByteArray.read(NbtReader input) => NbtByteArray(input.bytes());

  @override
  void write(NbtWriter output) => output.bytes(_value);
  @override
  void stringify(SnbtWriter writer) => writer.write("[B; ${_value.map((e) => "${e}b").join(", ")}]");
}

final class NbtIntArray extends NbtElement<List<dart.int>> {
  @override
  final NbtElementType type = NbtElementType.intArray;

  NbtIntArray(super._value);
  factory NbtIntArray.read(NbtReader input) {
    final length = input.i32();

    final list = <dart.int>[];
    for (var i = 0; i < length; i++) {
      list.add(input.i32());
    }

    return NbtIntArray(list);
  }

  @override
  void write(NbtWriter output) {
    output.i32(_value.length);
    for (final element in _value) {
      output.i32(element);
    }
  }

  @override
  void stringify(SnbtWriter writer) => writer.write("[I; ${_value.join(", ")}]");
}

final class NbtLongArray extends NbtElement<List<dart.int>> {
  @override
  final NbtElementType type = NbtElementType.longArray;

  NbtLongArray(super._value);
  factory NbtLongArray.read(NbtReader input) {
    final length = input.i32();

    final list = <dart.int>[];
    for (var i = 0; i < length; i++) {
      list.add(input.i64());
    }

    return NbtLongArray(list);
  }

  @override
  void write(NbtWriter output) {
    output.i32(_value.length);
    for (final element in _value) {
      output.i64(element);
    }
  }

  @override
  void stringify(SnbtWriter writer) => writer.write("[L; ${_value.map((e) => "${e}L").join(", ")}]");
}

// --- compound types ---

final class NbtList extends NbtElement<List<NbtElement>> {
  @override
  final NbtElementType type = NbtElementType.list;

  NbtList(super._value);
  factory NbtList.read(NbtReader input) {
    final elementType = input.i8();
    final length = input.i32();

    final list = <NbtElement>[];
    for (var i = 0; i < length; i++) {
      list.add(input.nbtElement(NbtElementType.byId(elementType)));
    }

    return NbtList(list);
  }

  @override
  void write(NbtWriter output) {
    output.i8(_value.firstOrNull?.type.index ?? 0);
    output.i32(_value.length);

    for (final element in _value) {
      element.write(output);
    }
  }

  @override
  void stringify(SnbtWriter writer) {
    writer.startBlock('[', ']');
    for (final (idx, element) in _value.indexed) {
      element.stringify(writer);
      if (idx < _value.length - 1) writer.writeln(",");
    }
    writer.endBlock();
  }
}

final class NbtCompound extends NbtElement<Map<String, NbtElement>> {
  static final _safeKeyRegex = RegExp(r"^[a-zA-Z0-9_\+\.-]+$");

  @override
  final NbtElementType type = NbtElementType.compound;

  NbtCompound(super._value);
  factory NbtCompound.read(NbtReader input) {
    final map = <String, NbtElement>{};

    var valueType = input.i8();
    while (valueType != NbtElementType.end.index) {
      map[input.string()] = input.nbtElement(NbtElementType.byId(valueType));
      valueType = input.i8();
    }

    return NbtCompound(map);
  }

  @override
  void write(NbtWriter output) {
    for (final MapEntry(:key, :value) in _value.entries.where((element) => element.value.type != NbtElementType.end)) {
      output.i8(value.type.index);
      output.string(key);
      value.write(output);
    }

    output.i8(NbtElementType.end.index);
  }

  @override
  void stringify(SnbtWriter writer) {
    writer.startBlock('{', '}');

    for (final (idx, MapEntry(:key, :value)) in _value.entries.indexed) {
      writer.write(_safeKeyRegex.hasMatch(key) ? "$key: " : '"${writer.escape(key)}": ');
      value.stringify(writer);

      if (idx < _value.length - 1) writer.writeln(",");
    }

    writer.endBlock();
  }
}

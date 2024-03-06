import 'dart:io';

void main(List<String> args) {
  final result = StringBuffer();

  for (var i = 2; i <= 16; i++) {
    var indices = List.generate(i, (index) => index + 1);
    var types = indices.map((e) => "F$e").join(", ");

    result.writeln("""
  Endec<S> with${i}Fields<$types>(
${indices.map((e) => "    StructField<S, F$e> f$e,").join("\n")}
    S Function($types) constructor,
  ) =>
      Endec.of(
        (serializer, value) => serializer.struct()
${indices.map((e) => "          ..field(f$e.name, f$e.endec, f$e.getter(value))").join("\n")}
          ..end(),
        (deserializer) {
          var state = deserializer.struct();
          return constructor(${indices.map((e) => "state.field(f$e.name, f$e.endec, defaultValue: f$e.defaultValue)").join(", ")},);
        }
      );
""");
  }

  File("structs.txt").writeAsStringSync(result.toString());
}

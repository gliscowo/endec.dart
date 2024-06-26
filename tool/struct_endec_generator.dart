import 'dart:io';

void main(List<String> args) {
  final result = StringBuffer();

  for (var i = 2; i <= 16; i++) {
    var indices = List.generate(i, (index) => index + 1);
    var types = indices.map((e) => "F$e").join(", ");

    result.writeln("""
  StructEndec<S> with${i}Fields<$types>(
${indices.map((e) => "    StructField<S, F$e> f$e,").join("\n")}
    S Function($types) constructor,
  ) =>
      StructEndec.of(
        (ctx, serializer, struct, value) {
${indices.map((e) => "          f$e.encodeField(ctx, serializer, struct, value);").join("\n")}
        },
        (ctx, deserializer, struct) {
          return constructor(${indices.map((e) => "f$e.decodeField(ctx, deserializer, struct)").join(", ")},);
        }
      );
""");
  }

  File("structs.txt").writeAsStringSync(result.toString());
}

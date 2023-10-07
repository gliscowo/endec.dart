import 'dart:convert';

import 'package:codec/codec.dart';
import 'package:codec/json_deserializer.dart';
import 'package:codec/json_serializer.dart';
import 'package:test/test.dart';

void main() {
  final jsonEncoder = const JsonEncoder.withIndent("  ");

  test('encode string', () {
    var value = "an epic string";
    var result = toJson<String>(Codec.string, value);
    print("Result: $result, Type: ${result.runtimeType}");
  });

  test('encode struct', () {
    var serializer = JsonSerializer();

    serializer.struct()
      ..field("a field", Codec.string, "an epic field value")
      ..field("a nested field", Codec.string.mapOf(), {"a": "bruh", "b": "nested field value, epic"})
      ..field("list moment", Codec.double.listOf(), [1.0, 5.7, double.maxFinite])
      ..field("another field", Codec.string, "this too")
      ..end();

    var serialized = jsonEncoder.convert(serializer.result);
    print(serialized);

    var state = JsonDeserializer(jsonDecode(serialized)).struct();
    final field1 = state.field(Codec.string);
    final field2 = state.field(Codec.string.mapOf());
    final field3 = state.field(Codec.double.listOf());
    final field4 = state.field(Codec.string);

    print("Deserialized: $field1, $field2, $field3, $field4");
  });

  test('xmap string to codepoints', () {
    final codepointCodec = Codec.int.listOf().xmap(String.fromCharCodes, (other) => other.codeUnits);

    final serialized = jsonEncoder.convert(toJson(codepointCodec, "a string"));
    print(serialized);

    final decoded = fromJson(codepointCodec, jsonDecode(serialized));
    print("decoded: $decoded");
  });
}

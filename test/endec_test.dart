import 'dart:convert';
import 'dart:typed_data';

import 'package:endec/binary/binary_deserializer.dart';
import 'package:endec/binary/binary_serializer.dart';
import 'package:endec/endec.dart';
import 'package:endec/json/json_deserializer.dart';
import 'package:endec/json/json_endec.dart';
import 'package:endec/json/json_serializer.dart';
import 'package:endec/struct_endec.dart';
import 'package:test/test.dart';

void main() {
  final jsonEncoder = const JsonEncoder.withIndent("  ");

  test('encode string', () {
    var value = "an epic string";
    var result = toJson<String>(Endec.string, value);
    print("Result: $result, Type: ${result.runtimeType}");
  });

  test('encode struct', () {
    var endec = structEndec<_Struct>().with4Fields(
      Endec.string.field("a_field", (struct) => struct.aField),
      Endec.string.mapOf().field("a_nested_field", (struct) => struct.aNestedField),
      Endec.double.listOf().field("list_moment", (struct) => struct.listMoment),
      Endec.string.field("another_field", (struct) => struct.anotherField),
      _Struct.new,
    );

    var serialized = toJson(
      endec,
      _Struct(
        "an epic field value",
        {"a": "bruh", "b": "nested field value, epic"},
        [1.0, 5.7, double.maxFinite],
        "this too",
      ),
    );
    print(serialized);

    var decoded = fromJson(endec, serialized);
    print("Deserialized: ${decoded.aField}, ${decoded.aNestedField}, ${decoded.listMoment}, ${decoded.anotherField}");
  });

  test('xmap string to codepoints', () {
    final codepointEndec = Endec.int.listOf().xmap(String.fromCharCodes, (other) => other.codeUnits);

    final serialized = jsonEncoder.convert(toJson(codepointEndec, "a string"));
    print(serialized);

    final decoded = fromJson(codepointEndec, jsonDecode(serialized));
    print("decoded: $decoded");
  });

  test('encode json to binary', () {
    var json = {
      "a field": "some json here",
      "another_field": [
        1.0,
        {"hmmm": null}
      ]
    };

    var serializer = BinarySerializer();
    jsonEndec.encode(serializer, json);

    expect(jsonEndec.decode(BinaryDeserializer(ByteData.view(serializer.result.buffer))), json);
  });

  test('encode json to json', () {
    var json = {
      "a field": "some json here",
      "another_field": [
        1.0,
        {"hmmm": null}
      ]
    };

    var encoded = toJson(jsonEndec, json);
    expect(json, encoded);
  });
}

class _Struct {
  final String aField;
  final Map<String, String> aNestedField;
  final List<double> listMoment;
  final String anotherField;

  _Struct(this.aField, this.aNestedField, this.listMoment, this.anotherField);
}

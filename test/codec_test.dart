import 'dart:convert';
import 'dart:typed_data';

import 'package:codec/binary/binary_deserializer.dart';
import 'package:codec/binary/binary_serializer.dart';
import 'package:codec/codec.dart';
import 'package:codec/json/json_codec.dart';
import 'package:codec/json/json_deserializer.dart';
import 'package:codec/json/json_serializer.dart';
import 'package:codec/struct_codec.dart';
import 'package:test/test.dart';

void main() {
  final jsonEncoder = const JsonEncoder.withIndent("  ");

  test('encode string', () {
    var value = "an epic string";
    var result = toJson<String>(Codec.string, value);
    print("Result: $result, Type: ${result.runtimeType}");
  });

  test('encode struct', () {
    var codec = structCodec<_Struct>().codec4(
      Codec.string.field("a_field", (struct) => struct.aField),
      Codec.string.mapOf().field("a_nested_field", (struct) => struct.aNestedField),
      Codec.double.listOf().field("list_moment", (struct) => struct.listMoment),
      Codec.string.field("another_field", (struct) => struct.anotherField),
      _Struct.new,
    );

    var serialized = toJson(
      codec,
      _Struct(
        "an epic field value",
        {"a": "bruh", "b": "nested field value, epic"},
        [1.0, 5.7, double.maxFinite],
        "this too",
      ),
    );
    print(serialized);

    var decoded = fromJson(codec, serialized);
    print("Deserialized: ${decoded.aField}, ${decoded.aNestedField}, ${decoded.listMoment}, ${decoded.anotherField}");
  });

  test('xmap string to codepoints', () {
    final codepointCodec = Codec.int.listOf().xmap(String.fromCharCodes, (other) => other.codeUnits);

    final serialized = jsonEncoder.convert(toJson(codepointCodec, "a string"));
    print(serialized);

    final decoded = fromJson(codepointCodec, jsonDecode(serialized));
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
    jsonCodec.encode(serializer, json);

    expect(jsonCodec.decode(BinaryDeserializer(ByteData.view(serializer.result.buffer))), json);
  });

  test('encode json to json', () {
    var json = {
      "a field": "some json here",
      "another_field": [
        1.0,
        {"hmmm": null}
      ]
    };

    var encoded = toJson(jsonCodec, json);
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

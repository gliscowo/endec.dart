import 'dart:convert';
import 'dart:typed_data';

import 'package:endec/endec.dart';
import 'package:endec_binary/endec_binary.dart';
import 'package:endec_json/endec_json.dart';
import 'package:test/test.dart';

void main() {
  final jsonEncoder = const JsonEncoder.withIndent("  ");

  test('xmap string to codepoints', () {
    final codepointEndec = Endec.u16.listOf().xmap(String.fromCharCodes, (other) => other.codeUnits);

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
    jsonEndec.encode(SerializationContext.empty, serializer, json);

    expect(
      jsonEndec.decode(SerializationContext.empty, BinaryDeserializer(ByteData.view(serializer.result.buffer))),
      json,
    );
  });

  test('ranged nums', () {
    expect(
      fromJson(Endec.i32.ranged(min: -2, max: 10), -10),
      -2,
    );

    expect(
      fromJson(Endec.i32.ranged(min: 0, max: 10), 15),
      10,
    );

    expect(
      () => fromJson(Endec.f32.ranged(min: -2, max: -.25, error: true), 0.0),
      throwsA(isA<RangedNumException>()),
    );
  });
}

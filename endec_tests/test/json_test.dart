import 'package:endec/endec.dart';
import 'package:endec/struct_endec.dart';
import 'package:endec_json/endec_json.dart';
import 'package:test/test.dart';

void main() {
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

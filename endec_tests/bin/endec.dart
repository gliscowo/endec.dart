import 'package:endec_json/endec_json.dart';

import 'package:endec/endec.dart';

// void main(List<String> args) {
//   var encoded = toNbt(
//       MyEpicStruct.endec,
//       MyEpicStruct(
//         "a",
//         5,
//         {
//           "some entry": [1.0, double.maxFinite],
//           "another entry": [6.9, 4.2, 0.0]
//         },
//       ));

//   File("encode_struct.nbt").writeAsBytesSync(nbtToBinary(encoded as NbtCompound));
//   print(nbtToSnbt(encoded));

//   var deserialized = fromNbt(MyEpicStruct.endec, encoded);
//   print(deserialized);
// }

// void main(List<String> args) {
//   var json = {
//     "a_field": "epic value",
//     "map_field": {"b": []},
//     "another_field": 7,
//   };

//   var decoded = fromJson(MyEpicStruct.endec, json);
//   print(decoded);
// }

class MyEpicStruct {
  static final endec = structEndec<MyEpicStruct>().with3Fields(
    Endec.string.fieldOf("a_field", (struct) => struct.aField),
    Endec.i64.fieldOf("another_field", (struct) => struct.anotherField),
    Endec.f64.listOf().mapOf().fieldOf("map_field", (struct) => struct.mapField, defaultValueFactory: () => {}),
    MyEpicStruct.new,
  );

  final String aField;
  final int anotherField;
  final Map<String, List<double>> mapField;

  MyEpicStruct(this.aField, this.anotherField, this.mapField);

  @override
  String toString() => "aField: $aField\nanotherField: $anotherField\nmapField: $mapField";
}

class RecursiveStruct {
  static final endec = Endec<RecursiveStruct>.recursive(
    (thisRef) => structEndec<RecursiveStruct>().with2Fields(
      Endec.i32.fieldOf("a_field", (struct) => struct.aField),
      thisRef.optionalOf().fieldOf("inner", (struct) => struct.inner, defaultValueFactory: () => null),
      (p0, p1) => RecursiveStruct(p0, p1),
    ),
  );

  final int aField;
  final RecursiveStruct? inner;

  RecursiveStruct(this.aField, this.inner);

  @override
  String toString() => "RecursiveStruct($aField, $inner)";
}

void main(List<String> args) {
  final json = '1.25';
  final endec = Endec.f64.tryWhenDecoding([Endec.string.xmap(double.parse, (other) => other.toString())]).ranged(
    min: 0,
    max: 1.5,
    error: true,
  );

  print(fromJson(endec, json));
}

import 'dart:io';

import 'package:endec/endec.dart';
import 'package:endec_nbt/endec_nbt.dart';

void main(List<String> args) {
  var encoded = toNbt(
      MyEpicStruct.endec,
      MyEpicStruct(
        "a",
        5,
        {
          "some entry": [1.0, double.maxFinite],
          "another entry": [6.9, 4.2, 0.0]
        },
      ));

  File("encode_struct.nbt").writeAsBytesSync(nbtToBinary(encoded as NbtCompound));
  print(nbtToSnbt(encoded));

  var deserialized = fromNbt(MyEpicStruct.endec, encoded);
  print(deserialized);
}

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
  static final Endec<MyEpicStruct> endec = structEndec<MyEpicStruct>().with3Fields(
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

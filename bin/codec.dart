import 'dart:io';

import 'package:codec/codec.dart';
import 'package:codec/nbt/nbt_deserializer.dart';
import 'package:codec/nbt/nbt_io.dart';
import 'package:codec/nbt/nbt_serializer.dart';
import 'package:codec/nbt/nbt_types.dart';
import 'package:codec/nbt/snbt.dart';
import 'package:codec/struct_codec.dart';

void main(List<String> args) {
  var encoded = toNbt(
      MyEpicStruct.codec,
      MyEpicStruct(
        "a",
        5,
        {
          "some entry": [1.0, double.maxFinite],
          "another entry": [6.9, 4.2, 0.0]
        },
      ));

  var snbt = SnbtWriter();
  encoded.stringify(snbt);

  File("encode_struct.nbt").writeAsBytesSync(nbtToBinary(encoded as NbtCompound));
  print(snbt.toString());

  var deserialized = fromNbt(MyEpicStruct.codec, encoded);
  print(deserialized);
}

// void main(List<String> args) {
//   var json = {
//     "a_field": "epic value",
//     "map_field": {"b": []},
//     "another_field": 7,
//   };

//   var decoded = fromJson(MyEpicStruct.codec, json);
//   print(decoded);
// }

class MyEpicStruct {
  static final Codec<MyEpicStruct> codec = structCodec<MyEpicStruct>().codec3(
    Codec.string.field("a_field", (struct) => struct.aField),
    Codec.int.field("another_field", (struct) => struct.anotherField),
    Codec.double.listOf().mapOf().field("map_field", defaultValue: {}, (struct) => struct.mapField),
    MyEpicStruct.new,
  );

  final String aField;
  final int anotherField;
  final Map<String, List<double>> mapField;

  MyEpicStruct(this.aField, this.anotherField, this.mapField);

  @override
  String toString() => "aField: $aField\nanotherField: $anotherField\nmapField: $mapField";
}

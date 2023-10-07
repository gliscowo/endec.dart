import 'dart:io';
import 'dart:typed_data';

import 'package:codec/binary_deserializer.dart';
import 'package:codec/binary_serializer.dart';
import 'package:codec/codec.dart';
import 'package:codec/struct_codec.dart';

// void main(List<String> arguments) {
//   var serialized = toJson(MyEpicStruct.codec, MyEpicStruct("a", 5, [1.0, double.maxFinite]));

//   var encoded = JsonEncoder.withIndent("  ").convert(serialized);
//   print(encoded);

//   var decoded = fromJson(MyEpicStruct.codec, jsonDecode(encoded));
//   print("decoded: \n$decoded");
// }

void main(List<String> args) {
  var serializer = BinarySerializer();
  MyEpicStruct.codec.encode(
      serializer,
      MyEpicStruct(
        "a",
        5,
        {
          "some entry": [1.0, double.maxFinite],
          "another entry": [6.9, 4.2, 0.0]
        },
      ));

  File("result.bin").writeAsBytesSync(serializer.result);

  var deserialized =
      MyEpicStruct.codec.decode(BinaryDeserializer(ByteData.view(File("result.bin").readAsBytesSync().buffer)));
  print(deserialized);
}

class MyEpicStruct {
  static final Codec<MyEpicStruct> codec = structCodec<MyEpicStruct>().codec3(
    Codec.string.field("a_field", (struct) => struct.aField),
    Codec.int.field("another_field", (struct) => struct.anotherField),
    Codec.double.listOf().mapOf().field("map_field", (struct) => struct.mapField),
    MyEpicStruct._,
  );

  final String aField;
  final int anotherField;
  final Map<String, List<double>> mapField;

  MyEpicStruct(this.aField, this.anotherField, this.mapField);
  MyEpicStruct._(this.aField, this.anotherField, this.mapField);

  @override
  String toString() => "aField: $aField\nanotherField: $anotherField\nmapField: $mapField";
}

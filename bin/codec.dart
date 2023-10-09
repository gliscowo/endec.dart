import 'package:codec/codec.dart';
import 'package:codec/json/json_deserializer.dart';
import 'package:codec/struct_codec.dart';

// void main(List<String> args) {
//   var serializer = BinarySerializer();
//   MyEpicStruct.codec.named.encode(
//       serializer,
//       MyEpicStruct(
//         "a",
//         5,
//         {
//           "some entry": [1.0, double.maxFinite],
//           "another entry": [6.9, 4.2, 0.0]
//         },
//       ));

//   File("result.bin").writeAsBytesSync(serializer.result);

//   var deserialized =
//       MyEpicStruct.codec.named.decode(BinaryDeserializer(ByteData.view(File("result.bin").readAsBytesSync().buffer)));
//   print(deserialized);
// }

void main(List<String> args) {
  var json = {
    "a_field": "epic value",
    "map_field": {"b": []},
    "another_field": 7,
  };

  var decoded = fromJson(MyEpicStruct.codec.named, json);
  print(decoded);
}

class MyEpicStruct {
  static final StructCodec<MyEpicStruct> codec = structCodec<MyEpicStruct>().codec3(
    Codec.string.field("a_field", (struct) => struct.aField),
    Codec.int.field("another_field", (struct) => struct.anotherField),
    Codec.double.listOf().mapOf().optionalField("map_field", {}, (struct) => struct.mapField),
    MyEpicStruct.new,
  );

  final String aField;
  final int anotherField;
  final Map<String, List<double>> mapField;

  MyEpicStruct(this.aField, this.anotherField, this.mapField);

  @override
  String toString() => "aField: $aField\nanotherField: $anotherField\nmapField: $mapField";
}

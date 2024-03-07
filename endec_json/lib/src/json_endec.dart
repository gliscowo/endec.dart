import 'dart:convert';

import 'package:endec/deserializer.dart';
import 'package:endec/endec.dart';
import 'package:endec/serializer.dart';

import 'json_deserializer.dart';
import 'json_serializer.dart';

const jsonEndec = JsonEndec._();

class JsonEndec with Endec<Object?> {
  const JsonEndec._();

  @override
  void encode(Serializer serializer, Object? value) {
    if (serializer.selfDescribing) {
      JsonDeserializer(value).any(serializer);
    } else {
      serializer.string(jsonEncode(value));
    }
  }

  @override
  Object? decode(Deserializer deserializer) {
    if (deserializer is SelfDescribingDeserializer) {
      final visitor = JsonSerializer();
      deserializer.any(visitor);
      return visitor.result;
    } else {
      return jsonDecode(deserializer.string());
    }
  }
}

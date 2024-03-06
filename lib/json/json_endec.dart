import 'dart:convert';

import 'package:endec/json/json_deserializer.dart';
import 'package:endec/json/json_serializer.dart';

import '../deserializer.dart';
import '../endec.dart';
import '../serializer.dart';

const jsonEndec = JsonEndec._();

class JsonEndec with Endec<Object?> {
  const JsonEndec._();

  @override
  void encode<S>(Serializer<S> serializer, Object? value) {
    if (serializer.selfDescribing) {
      JsonDeserializer(value).any(serializer);
    } else {
      serializer.string(jsonEncode(value));
    }
  }

  @override
  Object? decode<S>(Deserializer<S> deserializer) {
    if (deserializer is SelfDescribingDeserializer<S>) {
      final visitor = JsonSerializer();
      deserializer.any(visitor);
      return visitor.result;
    } else {
      return jsonDecode(deserializer.string());
    }
  }
}

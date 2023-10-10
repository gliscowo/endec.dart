import 'dart:convert';

import '../codec.dart';
import '../deserializer.dart';
import '../serializer.dart';

const jsonCodec = JsonCodec._();

class JsonCodec with Codec<Object?> {
  const JsonCodec._();

  @override
  void encode<S>(Serializer<S> serializer, Object? value) {
    if (serializer.selfDescribing) {
      switch (value) {
        case int value:
          serializer.i64(value);
        case double value:
          serializer.f64(value);
        case String value:
          serializer.string(value);
        case bool value:
          serializer.boolean(value);
        case List<dynamic> value:
          listOf().encode(serializer, value.cast());
        case Map<String, dynamic> value:
          mapOf().encode(serializer, value.cast());
        case null:
          serializer.optional(this, null);
        case _:
          throw "Not a valid JSON value: $value";
      }
    } else {
      serializer.string(jsonEncode(value));
    }
  }

  @override
  Object? decode<S>(Deserializer<S> deserializer) {
    if (deserializer is SelfDescribingDeserializer<S>) {
      return deserializer.any();
    } else {
      return jsonDecode(deserializer.string());
    }
  }
}

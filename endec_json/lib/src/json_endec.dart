import 'dart:convert';

import 'package:endec/endec.dart';

import 'json_deserializer.dart';
import 'json_serializer.dart';

const jsonEndec = JsonEndec._();

class JsonEndec with Endec<Object?> {
  const JsonEndec._();

  @override
  void encode(SerializationContext ctx, Serializer serializer, Object? value) {
    if (serializer is SelfDescribingSerializer) {
      JsonDeserializer(value).any(ctx, serializer);
    } else {
      serializer.string(ctx, jsonEncode(value));
    }
  }

  @override
  Object? decode(SerializationContext ctx, Deserializer deserializer) {
    if (deserializer is SelfDescribingDeserializer) {
      final visitor = JsonSerializer();
      deserializer.any(ctx, visitor);
      return visitor.result;
    } else {
      return jsonDecode(deserializer.string(ctx));
    }
  }
}

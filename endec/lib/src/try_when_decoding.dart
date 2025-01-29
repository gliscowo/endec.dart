import 'deserializer.dart';
import 'endec_base.dart';
import 'serialization_context.dart';
import 'serializer.dart';

extension TryWhenDecoding<T> on Endec<T> {
  Endec<T> tryWhenDecoding(List<Endec<T>> alternativeDecoders) {
    if (alternativeDecoders.isEmpty) {
      throw ArgumentError('At least one alternative decoder must be provided', 'alternativeDecoders');
    }

    return _AlternativeDecoderEndec(this, alternativeDecoders);
  }
}

class _AlternativeDecoderEndec<T> with Endec<T> {
  final List<Endec<T>> _endecs;

  _AlternativeDecoderEndec(Endec<T> primary, List<Endec<T>> alternativeDecoders)
      : _endecs = [primary, ...alternativeDecoders];

  @override
  T decode(SerializationContext ctx, Deserializer deserializer) {
    for (final endec in _endecs) {
      try {
        return deserializer.tryRead((deserializer) => endec.decode(ctx, deserializer));
      } catch (_) {}
    }

    throw const AlternativesException._();
  }

  @override
  void encode(SerializationContext ctx, Serializer serializer, T value) => _endecs.first.encode(ctx, serializer, value);
}

class AlternativesException implements Exception {
  const AlternativesException._();
  @override
  String toString() => 'Failed to decode input using all available alternatives';
}

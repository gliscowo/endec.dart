// --- attributes ---

import 'deserializer.dart';
import 'endec_base.dart';
import 'serializer.dart';

const humanReadable = MarkerAttribute('human_readable');

sealed class SerializationAttribute {
  final String name;
  const SerializationAttribute(this.name);
}

sealed class AttributeInstance {
  SerializationAttribute get attribute;
  Object? get value;
}

final class MarkerAttribute extends SerializationAttribute implements AttributeInstance {
  const MarkerAttribute(super.name);

  @override
  SerializationAttribute get attribute => this;

  @override
  Object? get value => null;
}

final class ValueAttribute<T> extends SerializationAttribute {
  const ValueAttribute(super.name);

  AttributeInstance instance(T value) => _ValueAttributeInstance(this, value);
}

final class _ValueAttributeInstance<T> implements AttributeInstance {
  @override
  final ValueAttribute<T> attribute;
  @override
  final T value;

  _ValueAttributeInstance(this.attribute, this.value);
}

// --- tracing ---

sealed class EndecTraceElement {}

class FieldTraceElement implements EndecTraceElement {
  final String name;
  const FieldTraceElement(this.name);

  @override
  String toString() => '.$name';
}

class IndexTraceElement implements EndecTraceElement {
  final int index;
  const IndexTraceElement(this.index);

  @override
  String toString() => '[$index]';
}

class EndecTrace {
  final List<EndecTraceElement> elements;
  const EndecTrace({this.elements = const []});

  EndecTrace push(EndecTraceElement element) => EndecTrace(elements: [...elements, element]);

  @override
  String toString() => '\$${elements.join()}';
}

// --- context ---

class SerializationContext {
  static const empty = SerializationContext._({}, {}, EndecTrace());

  final Map<SerializationAttribute, Object?> _attributeValues;
  final Set<SerializationAttribute> _suppressedAttributes;
  final EndecTrace location;

  const SerializationContext._(this._attributeValues, this._suppressedAttributes, this.location);

  factory SerializationContext({
    List<AttributeInstance> attributes = const [],
    Set<SerializationAttribute> suppressed = const {},
  }) =>
      attributes.isNotEmpty || suppressed.isNotEmpty
          ? SerializationContext._(_unpackAttributes(attributes), suppressed, const EndecTrace())
          : empty;

  SerializationContext copyWith({
    List<AttributeInstance> attributes = const [],
    Set<SerializationAttribute> suppressed = const {},
  }) =>
      attributes.isNotEmpty || suppressed.isNotEmpty
          ? SerializationContext._(Map.of(_attributeValues)..addAll(_unpackAttributes(attributes)),
              Set.of(_suppressedAttributes)..addAll(suppressed), location)
          : this;

  SerializationContext copyWithout({
    List<AttributeInstance> attributes = const [],
    Set<SerializationAttribute> suppressed = const {},
  }) =>
      attributes.isNotEmpty || suppressed.isNotEmpty
          ? SerializationContext._((() {
              final newAttributes = Map.of(_attributeValues);
              for (final attribute in attributes) {
                newAttributes.remove(attribute.attribute);
              }
              return newAttributes;
            })(), Set.of(_suppressedAttributes)..removeAll(suppressed), location)
          : this;

  SerializationContext operator |(SerializationContext other) => this != empty || other != empty
      ? SerializationContext._(
          Map.of(_attributeValues)..addAll(other._attributeValues),
          Set.of(_suppressedAttributes)..addAll(other._suppressedAttributes),
          // TODO this is cringe
          location,
        )
      : empty;

  /// Test whether [attribute] is present on this context, irrespective
  /// of whether it has a value or not
  bool hasAttribute(SerializationAttribute attribute) => _attributeValues.containsKey(attribute);

  /// Get the value that a [ValueAttribute] has on this context. Throws
  /// [ArgumentError] if [attribute] is not present on this context.
  A getAttributeValue<A>(ValueAttribute<A> attribute) => hasAttribute(attribute)
      ? _attributeValues[attribute] as A
      : throw ArgumentError.value(attribute, "attribute", "Attribute $attribute is not present in this context");

  SerializationContext pushField(String fieldName) => SerializationContext._(
        _attributeValues,
        _suppressedAttributes,
        location.push(FieldTraceElement(fieldName)),
      );

  SerializationContext pushIndex(int index) => SerializationContext._(
        _attributeValues,
        _suppressedAttributes,
        location.push(IndexTraceElement(index)),
      );

  Never malformedInput(String message) => throw MalformedInputException(location, message);

  static Map<SerializationAttribute, Object?> _unpackAttributes(List<AttributeInstance> attributes) =>
      Map.fromEntries(attributes.map((e) => MapEntry(e.attribute, e.value)));
}

class MalformedInputException implements Exception {
  final EndecTrace location;
  final String message;

  MalformedInputException(this.location, this.message);

  @override
  String toString() => 'Malformed input at $location: $message';
}

// --- attribute branching ---

typedef _Branch<T> = (SerializationAttribute, Endec<T>);

class AttributeBranchBuilder<T> {
  final List<_Branch<T>> _branches;
  AttributeBranchBuilder._(this._branches);
  AttributeBranchBuilder(SerializationAttribute attribute, Endec<T> endec) : _branches = [(attribute, endec)];

  AttributeBranchBuilder<T> elseIf(SerializationAttribute attribute, Endec<T> branchEndec) =>
      AttributeBranchBuilder._([..._branches, (attribute, branchEndec)]);

  Endec<T> orElse(Endec<T> endec) => _AttributeBranchingEndec(_branches, endec);
}

class _AttributeBranchingEndec<T> with Endec<T> {
  final List<_Branch<T>> _branches;
  final Endec<T> _default;
  _AttributeBranchingEndec(this._branches, this._default);

  @override
  T decode(SerializationContext ctx, Deserializer deserializer) {
    for (final (attr, endec) in _branches) {
      if (!ctx.hasAttribute(attr)) continue;
      return endec.decode(ctx, deserializer);
    }

    return _default.decode(ctx, deserializer);
  }

  @override
  void encode(SerializationContext ctx, Serializer serializer, T value) {
    for (final (attr, endec) in _branches) {
      if (!ctx.hasAttribute(attr)) continue;
      return endec.encode(ctx, serializer, value);
    }

    return _default.encode(ctx, serializer, value);
  }
}

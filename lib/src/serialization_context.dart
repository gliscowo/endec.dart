// -- attributes --

sealed class AttributeInstance {
  SerializationAttribute get attribute;
  Object? get value;
}

sealed class SerializationAttribute {
  final String name;
  const SerializationAttribute(this.name);
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

// -- context --

class SerializationContext {
  static const empty = SerializationContext._({}, {});

  final Map<SerializationAttribute, Object?> _attributeValues;
  final Set<SerializationAttribute> _suppressedAttributes;

  const SerializationContext._(this._attributeValues, this._suppressedAttributes);

  factory SerializationContext({
    List<AttributeInstance> attributes = const [],
    Set<SerializationAttribute> suppressed = const {},
  }) =>
      attributes.isNotEmpty || suppressed.isNotEmpty
          ? SerializationContext._(_unpackAttributes(attributes), suppressed)
          : empty;

  SerializationContext copyWith({
    List<AttributeInstance> attributes = const [],
    Set<SerializationAttribute> suppressed = const {},
  }) =>
      attributes.isNotEmpty || suppressed.isNotEmpty
          ? SerializationContext._(
              Map.of(_attributeValues)..addAll(_unpackAttributes(attributes)),
              Set.of(_suppressedAttributes)..addAll(suppressed),
            )
          : this;

  SerializationContext copyWithout({
    List<AttributeInstance> attributes = const [],
    Set<SerializationAttribute> suppressed = const {},
  }) =>
      attributes.isNotEmpty || suppressed.isNotEmpty
          ? SerializationContext._(
              (() {
                final newAttributes = Map.of(_attributeValues);
                for (final attribute in attributes) {
                  newAttributes.remove(attribute.attribute);
                }
                return newAttributes;
              })(),
              Set.of(_suppressedAttributes)..removeAll(suppressed),
            )
          : this;

  SerializationContext operator |(SerializationContext other) => this != empty || other != empty
      ? SerializationContext._(
          Map.of(_attributeValues)..addAll(other._attributeValues),
          Set.of(_suppressedAttributes)..addAll(other._suppressedAttributes),
        )
      : empty;

  /// Test whether [attribute] is present on this context, irrespective
  /// of whether it has a value or not
  bool hasAttribute(SerializationAttribute attribute) => _attributeValues.containsKey(attribute);

  /// Get the value that a [ValueAttribute] has on this context. Throws
  ///  [ArgumentError] if [attribute] is not present on this context.
  A getAttributeValue<A>(ValueAttribute<A> attribute) => hasAttribute(attribute)
      ? _attributeValues[attribute] as A
      : throw ArgumentError.value(attribute, "attribute", "Attribute $attribute is not present in this context");

  static Map<SerializationAttribute, Object?> _unpackAttributes(List<AttributeInstance> attributes) =>
      Map.fromEntries(attributes.map((e) => MapEntry(e.attribute, e.value)));
}

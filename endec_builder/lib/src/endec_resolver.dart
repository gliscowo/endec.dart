import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:endec/endec_annotation.dart';
import 'package:source_helper/source_helper.dart';

import 'struct_endec_generator.dart';

/// Resolve the endec to use for [field] in the current [context],
/// honoring the [settings] specified on its container
String endecForField(
  GeneratorContext context,
  GeneratorSettings settings,
  FieldElement field,
  FieldSettings? fieldSettings,
) =>
    fieldSettings?.endecSupplier != null
        ? switch (fieldSettings!.endecSupplier!) {
            FunctionElement function => '${function.name}()',
            MethodElement method => '${method.enclosingElement3.name}.${method.name}()',
            _ => throw 'Unsupported endec supplier function'
          }
        : _endecForType(
            context,
            settings,
            (field.enclosingElement3 as InstanceElement).thisType,
            field.type,
            field.metadata,
          );

String _endecForType(
  GeneratorContext context,
  GeneratorSettings settings,
  DartType enclosingType,
  DartType type, [
  List<ElementAnnotation> annotations = const [],
]) {
  String? endec;

  // int
  if (type.isDartCoreInt) {
    endec = integralEndec(type, settings.defaultIntType, annotations);
  }
  // double
  else if (type.isDartCoreDouble) {
    endec = floatEndec(type, settings.defaultFloatType, annotations);
  }
  // string
  else if (type.isDartCoreString) {
    endec = 'Endec.string';
  }
  // bool
  else if (type.isDartCoreBool) {
    endec = 'Endec.bool';
  }
  // recursive reference
  else if (type.element == enclosingType.element) {
    endec = 'thisRef';
  }
  // list
  else if (type.isDartCoreList) {
    final elementType = (type as ParameterizedType).typeArguments.first;
    endec = '${_endecForType(context, settings, enclosingType, elementType)}.listOf()';
  }
  // map
  else if (type.isDartCoreMap) {
    final keyType = (type as ParameterizedType).typeArguments[0];
    final valueEndec = _endecForType(context, settings, enclosingType, type.typeArguments[1]);

    if (keyType.isDartCoreString) {
      endec = '$valueEndec.mapOf()';
    } else {
      endec = 'Endec.improperMap(${_endecForType(context, settings, enclosingType, keyType)}, $valueEndec)';
    }
  }
  // other struct
  else if (type is InterfaceType) {
    // bytes
    if (type.element.name == 'Uint8List' && type.element.library.name == 'dart.typed_data') {
      endec = 'Endec.bytes';
    }
    // serializable struct
    else if (type.element case ClassElement classElement) {
      if (context.hasGenerateAnnotation(classElement)) {
        if (classElement.library == context.library) {
          endec = endecNameForType(type);
        } else {
          endec = '${classElement.name}.endec';
        }
      } else if (classElement.fields.any(
        (field) => field.isStatic && field.name == 'endec' && context.isEndecType(field.type),
      )) {
        endec = '${classElement.name}.endec';
      }
    }
  }

  if (endec == null) throw UnimplementedError();
  return type.isNullableType ? '$endec.optionalOf()' : endec;
}

String integralEndec(DartType type, IntegralType fallback, List<ElementAnnotation> extraMetadata) =>
    _numberTypeEndec(type, 'IntegralType', fallback, IntegralType.values, extraMetadata);

String floatEndec(DartType type, FloatType fallback, List<ElementAnnotation> extraMetadata) =>
    _numberTypeEndec(type, 'FloatType', fallback, FloatType.values, extraMetadata);

String _numberTypeEndec<E extends Enum>(
  DartType type,
  String name,
  E fallback,
  List<E> values,
  List<ElementAnnotation> extraMetadata,
) {
  E? firstNumberTypeAnnotation(List<ElementAnnotation>? metadata) {
    if (metadata == null) return null;

    final annotation = metadata.cast<ElementAnnotation?>().firstWhere(
      (element) {
        final elementRef = element!.element;
        return elementRef is PropertyAccessorElement &&
            elementRef.library.identifier == 'package:endec/endec_annotation.dart' &&
            elementRef.type.returnType.element?.name == name;
      },
      orElse: () => null,
    );

    final annotationValue = annotation?.computeConstantValue();
    if (annotationValue == null) return null;

    return values[annotationValue.getField('index')!.toIntValue()!];
  }

  final alias = type.alias;
  if (alias != null) {
    final sizeFromTypedef = firstNumberTypeAnnotation(alias.element.metadata);
    if (sizeFromTypedef != null) return 'Endec.${sizeFromTypedef.name}';
  }

  final sizeFromType = firstNumberTypeAnnotation(type.element?.metadata);
  if (sizeFromType != null) return 'Endec.${sizeFromType.name}';

  final sizeFromField = firstNumberTypeAnnotation(extraMetadata);
  if (sizeFromField != null) return 'Endec.${sizeFromField.name}';

  return 'Endec.${fallback.name}';
}

String endecNameForType(InterfaceType type) {
  return '_\$${type.element.name}Endec';
}

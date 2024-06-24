import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:endec/endec_annotation.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_helper/source_helper.dart';

import 'endec_resolver.dart';

class GeneratorContext {
  final LibraryElement library;
  final BuildStep buildStep;
  final Element generateAnnotation;
  final Element excludeAnnotation;
  final Element endecFieldAnnotation;
  final InterfaceType endecType;

  GeneratorContext(
    this.library,
    this.buildStep,
    this.generateAnnotation,
    this.excludeAnnotation,
    this.endecFieldAnnotation,
    this.endecType,
  );

  bool isEndecType(DartType type) => type.element == endecType.element;
  bool isExcluded(FieldElement field) => field.metadata.any((element) => element.element == excludeAnnotation);
  bool hasGenerateAnnotation(Element element) =>
      element.metadata.any((element) => element.element?.enclosingElement == generateAnnotation);

  /// Try to resolve the @EndecField annotation on [field]. If no such
  /// annotation was applied, return [null]
  FieldSettings? settingsForField(FieldElement field) {
    final annotation = field.metadata
        .cast<ElementAnnotation?>()
        .firstWhere((element) => element!.element?.enclosingElement == endecFieldAnnotation, orElse: () => null);

    if (annotation == null) return null;
    return FieldSettings.fromAnnotation(ConstantReader(annotation.computeConstantValue()));
  }
}

class StructEndecGenerator extends GeneratorForAnnotation<GenerateStructEndec> {
  GeneratorContext? _currentContext;

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    try {
      final endecAnnotationLib = await buildStep.resolver.libraryFor(AssetId('endec', 'lib/endec_annotation.dart'));
      final generateAnnotationClass =
          endecAnnotationLib.topLevelElements.firstWhere((element) => element.name == 'GenerateStructEndec');
      final excludeAnnotationConstant =
          endecAnnotationLib.topLevelElements.firstWhere((element) => element.name == 'excludeField');
      final endecFieldAnnotationClass =
          endecAnnotationLib.topLevelElements.firstWhere((element) => element.name == 'EndecField');

      final endecLib = await buildStep.resolver.libraryFor(AssetId('endec', 'lib/src/endec_base.dart'));
      final endecType =
          endecLib.topLevelElements.whereType<ClassElement>().firstWhere((element) => element.name == 'Endec').thisType;

      _currentContext = GeneratorContext(
        library.element,
        buildStep,
        generateAnnotationClass,
        excludeAnnotationConstant,
        endecFieldAnnotationClass,
        endecType,
      );
      return await super.generate(library, buildStep);
    } finally {
      _currentContext = null;
    }
  }

  @override
  Future<String> generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (element is! ClassElement) throw Exception('@GenerateStructEndec annocation can only be applied to classes');

    final context = _currentContext!;
    final settings = GeneratorSettings.fromAnnotation(annotation);
    final endecName = endecNameForType(element.thisType);

    final fields = element.fields
        // ignore all fields which are either
        // - static
        // - annotated with @exludeField
        // - both final and initialized in their declaration
        .where((field) => !field.isStatic && !context.isExcluded(field) && !(field.isFinal && field.hasInitializer))
        .map((field) {
      return (
        name: field.name,
        type: field.type,
        renamed: settings.renameField(field.name),
        endec: endecForField(context, settings, field, context.settingsForField(field)),
      );
    }).toList();

    final (:constructor, :fieldRefs) = _resolveConstructor(
      element,
      fields.map((e) => (type: e.type, name: e.name)).toList(),
    );

    final fieldParams = fields.map((e) => e.name).toList();
    final constructorParams = fieldRefs.map((e) => e.$2 ? '${e.$1}: ${e.$1}' : e.$1);
    final constructorInvocation = '${element.name}${constructor.name.isEmpty ? '' : '.${constructor.name}'}';

    final result = StringBuffer();
    result.writeln('// static final Endec<${element.name}> endec = $endecName;');

    final endec = '''
structEndec<${element.name}>().with${fields.length}Field${fields.length > 1 ? 's' : ''}(
  ${fields.map((field) => '${field.endec}.fieldOf(\'${field.renamed}\', (struct) => struct.${field.name})').join(',')},
  (${fieldParams.join(',')}) => $constructorInvocation(${constructorParams.join(',')}),
)
''';

    if (fields.any((element) => element.endec.contains('thisRef'))) {
      result
        ..write('final $endecName = StructEndec<${element.name}>.recursive((thisRef) => ')
        ..write(endec)
        ..write(',);');
    } else {
      result
        ..write('final $endecName = ')
        ..write(endec)
        ..write(';');
    }

    return result.toString();
  }

  ({ConstructorElement constructor, List<(String, bool)> fieldRefs}) _resolveConstructor(
    ClassElement classElement,
    List<({DartType type, String name})> fields,
  ) {
    if (classElement.constructors.isEmpty) throw Exception('No constructor available for class ${classElement.name}');

    for (final candidate in classElement.constructors) {
      final params = candidate.parameters;
      if (fields.length != params.length) continue;
      if (fields.any((field) => !params.any((param) => param.name == field.name && param.type == field.type))) continue;

      final fieldRefs = <(String, bool)>[];

      for (final param in params) {
        for (final field in fields) {
          if (field.name != param.name) continue;
          fieldRefs.add((field.name, param.isOptional));
        }
      }

      return (constructor: candidate, fieldRefs: fieldRefs);
    }

    throw Exception('No applicable constructor available for class ${classElement.name}');
  }
}

class GeneratorSettings {
  final ExecutableElement? constructor;
  final FieldNaming fieldNaming;
  final IntegralType defaultIntType;
  final FloatType defaultFloatType;

  GeneratorSettings._(this.constructor, this.fieldNaming, this.defaultIntType, this.defaultFloatType);
  factory GeneratorSettings.fromAnnotation(ConstantReader annotation) => GeneratorSettings._(
        annotation.objectValue.getField('constructor')?.toFunctionValue(),
        FieldNaming.values[annotation.objectValue.getField('fieldNaming')!.getField('index')!.toIntValue()!],
        IntegralType.values[annotation.objectValue.getField('defaultIntType')!.getField('index')!.toIntValue()!],
        FloatType.values[annotation.objectValue.getField('defaultFloatType')!.getField('index')!.toIntValue()!],
      );

  String renameField(String field) => switch (fieldNaming) {
        FieldNaming.pascalCase => field.pascal,
        FieldNaming.kebabCase => field.kebab,
        FieldNaming.snakeCase => field.snake,
        FieldNaming.camelCase => field,
      };

  @override
  String toString() => 'GeneratorSettings($constructor, $fieldNaming, $defaultIntType, $defaultFloatType)';
}

class FieldSettings {
  final ExecutableElement? endecSupplier;

  FieldSettings._(this.endecSupplier);
  factory FieldSettings.fromAnnotation(ConstantReader annotation) => FieldSettings._(
        annotation.objectValue.getField('endec')?.toFunctionValue(),
      );

  @override
  String toString() => 'FieldSettings($endecSupplier)';
}

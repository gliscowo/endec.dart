import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:meta/meta_meta.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_helper/source_helper.dart';

Builder endecBuilder(BuilderOptions options) => SharedPartBuilder([StructEndecGenerator()], "endec");

class StructEndecGenerator extends GeneratorForAnnotation<GenerateStructEndec> {
  @override
  String generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) throw 'bruh, need a class you disphit';

    final fields =
        element.fields.where((element) => !element.isStatic).map((e) => (e.name, endecForType(e.type))).toList();
    final fieldParams = List.generate(fields.length, (idx) => "f$idx");

    return '''
final generatedEndec = structEndec<${element.name}>().with${fields.length}Fields(
  ${fields.map((e) => '${e.$2}.fieldOf(\'${e.$1}\', (struct) => struct.${e.$1})').join(',\n  ')},
  (${fieldParams.join(", ")}) => ${element.name}(${fieldParams.join(", ")}),
);
''';
  }

  static String endecForType(DartType type) {
    String? endec;
    if (type.isDartCoreInt) endec = 'Endec.i32';
    if (type.isDartCoreString) endec = 'Endec.string';

    if (endec == null) throw UnimplementedError();
    return type.isNullableType ? "$endec.optionalOf()" : endec;
  }
}

const GenerateStructEndec generateStructEndec = GenerateStructEndec._();

@Target({TargetKind.classType})
class GenerateStructEndec {
  const GenerateStructEndec._();
}

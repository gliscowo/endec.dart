import 'package:endec/endec.dart';
import 'package:endec_builder/endec_builder.dart';

part 'build_test.g.dart';

@generateStructEndec
class ThisHasFields {
  static Endec<ThisHasFields> endec = generatedEndec;

  final int oneField;
  final String? another;

  ThisHasFields(this.oneField, this.another);
}

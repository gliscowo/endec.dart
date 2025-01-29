import 'package:endec/endec.dart';

import '../../endec/lib/endec_annotation.dart';
import 'build_test.dart';

part 'build_test_2.g.dart';

@GenerateStructEndec(fieldNaming: FieldNaming.pascalCase)
class YepThatHasStuffInIt {
  static final endec = _$YepThatHasStuffInItEndec;

  final Class2 valueTime;
  final List<Map<String, YepThatHasStuffInIt>>? recursive;

  YepThatHasStuffInIt(this.valueTime, {this.recursive});
}

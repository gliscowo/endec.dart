import 'package:endec/endec.dart';

import '../../endec/lib/endec_annotation.dart';

part 'build_test.g.dart';

@GenerateStructEndec(defaultIntType: IntegralType.u64)
class ThisHasFields {
  static Endec<ThisHasFields> endec = _$ThisHasFieldsEndec;

  @IntegralType.i16
  final int oneField;
  final String? another;

  ThisHasFields(this.oneField, this.another);
}

@GenerateStructEndec(defaultFloatType: FloatType.f32)
class Class2 {
  static Endec<Class2> endec = _$Class2Endec;

  final ThisHasFields asAField;
  @excludeField
  final String bruh = 'b';
  @EndecField(endec: myEndec)
  final List<bool> boolList;
  final Map<int, List<double?>>? mapnite;
  final Map<String, ThisHasFields> mapnite2;

  Class2()
      : asAField = ThisHasFields(0, null),
        boolList = const [],
        mapnite2 = const {},
        mapnite = null;

  Class2._fromEndec(this.boolList, ThisHasFields asAField, this.mapnite2, {this.mapnite})
      : asAField = ThisHasFields(asAField.oneField, null);
}

Endec<List<bool>> myEndec() => Endec.bool.listOf();

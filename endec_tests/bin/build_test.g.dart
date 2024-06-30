// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_test.dart';

// **************************************************************************
// StructEndecGenerator
// **************************************************************************

// static final Endec<ThisHasFields> endec = _$ThisHasFieldsEndec;
final _$ThisHasFieldsEndec = structEndec<ThisHasFields>().with2Fields(
  Endec.i16.fieldOf('one_field', (struct) => struct.oneField),
  Endec.string.optionalOf().fieldOf('another', (struct) => struct.another),
  (oneField, another) => ThisHasFields(oneField, another),
);

// static final Endec<Class2> endec = _$Class2Endec;
final _$Class2Endec = structEndec<Class2>().with4Fields(
  _$ThisHasFieldsEndec.fieldOf('as_a_field', (struct) => struct.asAField),
  myEndec().fieldOf('bool_list', (struct) => struct.boolList),
  Endec.improperMap(Endec.i64, Endec.f32.optionalOf().listOf())
      .optionalOf()
      .fieldOf('mapnite', (struct) => struct.mapnite),
  _$ThisHasFieldsEndec.mapOf().fieldOf('mapnite2', (struct) => struct.mapnite2),
  (asAField, boolList, mapnite, mapnite2) =>
      Class2._fromEndec(boolList, asAField, mapnite2, mapnite: mapnite),
);

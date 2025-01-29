// ignore_for_file: camel_case_types

import 'package:meta/meta_meta.dart';

import 'src/endec_base.dart';

enum IntegralType {
  i8,
  i16,
  i32,
  i64,
  u8,
  u16,
  u32,
  u64,
}

@IntegralType.i8
typedef i8 = int;
@IntegralType.i16
typedef i16 = int;
@IntegralType.i32
typedef i32 = int;
@IntegralType.i64
typedef i64 = int;
@IntegralType.u8
typedef u8 = int;
@IntegralType.u16
typedef u16 = int;
@IntegralType.u32
typedef u32 = int;
@IntegralType.u64
typedef u64 = int;

enum FloatType {
  f32,
  f64,
}

@FloatType.f32
typedef f32 = double;
@FloatType.f64
typedef f64 = double;

// ---

@Target({TargetKind.classType})
class GenerateStructEndec {
  final Function? constructor;
  final FieldNaming fieldNaming;
  final IntegralType defaultIntType;
  final FloatType defaultFloatType;

  const GenerateStructEndec({
    this.constructor,
    this.fieldNaming = FieldNaming.snakeCase,
    this.defaultIntType = IntegralType.i64,
    this.defaultFloatType = FloatType.f64,
  });
}

enum FieldNaming {
  snakeCase,
  pascalCase,
  kebabCase,
  camelCase,
}

// ---

const excludeField = _ExcludeField();

@Target({TargetKind.field})
class _ExcludeField {
  const _ExcludeField();
}

@Target({TargetKind.field})
class EndecField {
  final Endec Function()? endec;
  const EndecField({this.endec});
}

import 'dart:convert';

import 'package:endec/endec.dart';
import 'package:endec_json/endec_json.dart';

abstract class ParentClass {
  static final fieldsEndec = structEndec<(String, int)>().with2Fields(
    Endec.string.fieldOf("a_field", (tuple) => tuple.$1),
    Endec.int.fieldOf("another_field", (tuple) => tuple.$2),
    (p0, p1) => (p0, p1),
  );

  final String aField;
  final int anotherField;

  ParentClass(this.aField, this.anotherField);
}

class ChildClass extends ParentClass {
  static final endec = structEndec<ChildClass>().with2Fields(
    ParentClass.fieldsEndec.flatFieldOf((struct) => (struct.aField, struct.anotherField)),
    Endec.double.listOf().fieldOf("third_field", (struct) => struct.thirdField),
    (p0, p1) => ChildClass(p0.$1, p0.$2, p1),
  );

  final List<double> thirdField;
  ChildClass(super.aField, super.anotherField, this.thirdField);
}

class GrandchildClass extends ChildClass {
  static final endec = structEndec<GrandchildClass>().with2Fields(
    ChildClass.endec.flatFieldOf((struct) => ChildClass(struct.aField, struct.anotherField, struct.thirdField)),
    Endec.bool.fieldOf("bruh", (struct) => struct.bruh),
    (p0, p1) => GrandchildClass(p0.aField, p0.anotherField, p0.thirdField, p1),
  );

  final bool bruh;
  GrandchildClass(super.aField, super.anotherField, super.thirdField, this.bruh);
}

void main(List<String> args) {
  print(jsonEncode(toJson(ChildClass.endec, ChildClass("a", 7, [1.2, 2.4]))));
  print(jsonEncode(toJson(GrandchildClass.endec, GrandchildClass("b", 77, [3.4, 3.5], false))));
}

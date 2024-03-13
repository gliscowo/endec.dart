import 'package:endec/endec.dart';
import 'package:endec_json/endec_json.dart';
import 'package:test/test.dart';

void main() {
  test('encode child class to json', () {
    final fieldsEndec = structEndec<(String, int)>().with2Fields(
      Endec.string.fieldOf("a_field", (tuple) => tuple.$1),
      Endec.int.fieldOf("another_field", (tuple) => tuple.$2),
      (p0, p1) => (p0, p1),
    );

    final childClassEndec = structEndec<ChildClass>().with2Fields(
      fieldsEndec.flatFieldOf((struct) => (struct.aField, struct.anotherField)),
      Endec.double.listOf().fieldOf("third_field", (struct) => struct.thirdField),
      (p0, p1) => ChildClass(p0.$1, p0.$2, p1),
    );

    expect(
      toJson(childClassEndec, ChildClass("a", 7, [1.2, 2.4])),
      {
        "a_field": "a",
        "another_field": 7,
        "third_field": [1.2, 2.4]
      },
    );
  });

  test('encode grandchild class to json', () {
    final fieldsEndec = structEndec<(String, int)>().with2Fields(
      Endec.string.fieldOf("a_field", (tuple) => tuple.$1),
      Endec.int.fieldOf("another_field", (tuple) => tuple.$2),
      (p0, p1) => (p0, p1),
    );

    final childClassEndec = structEndec<ChildClass>().with2Fields(
      fieldsEndec.flatFieldOf((struct) => (struct.aField, struct.anotherField)),
      Endec.double.listOf().fieldOf("third_field", (struct) => struct.thirdField),
      (p0, p1) => ChildClass(p0.$1, p0.$2, p1),
    );

    final grandChildClassEndec = structEndec<GrandchildClass>().with2Fields(
      childClassEndec.flatFieldOf((struct) => ChildClass(struct.aField, struct.anotherField, struct.thirdField)),
      Endec.bool.fieldOf("bruh", (struct) => struct.bruh),
      (p0, p1) => GrandchildClass(p0.aField, p0.anotherField, p0.thirdField, p1),
    );

    expect(
      toJson(grandChildClassEndec, GrandchildClass("b", 77, [3.4, 3.5], false)),
      {
        "a_field": "b",
        "another_field": 77,
        "third_field": [3.4, 3.5],
        "bruh": false
      },
    );
  });
}

abstract class ParentClass {
  final String aField;
  final int anotherField;

  ParentClass(this.aField, this.anotherField);
}

class ChildClass extends ParentClass {
  final List<double> thirdField;
  ChildClass(super.aField, super.anotherField, this.thirdField);
}

class GrandchildClass extends ChildClass {
  final bool bruh;
  GrandchildClass(super.aField, super.anotherField, super.thirdField, this.bruh);
}

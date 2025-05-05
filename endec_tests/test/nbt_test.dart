import 'dart:io';
import 'dart:typed_data';

import 'package:endec/endec.dart';
import 'package:endec_nbt/endec_nbt.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  File asset(List<String> nameParts) => File(joinAll(["assets", "nbt", ...nameParts]));

  test('element equality', () {
    expect(NbtString("that's a string"), NbtString("that's a string"));
    expect(NbtInt(7), NbtInt(7));
    expect(NbtCompound({"a_key": NbtDouble(.75)}), NbtCompound({"a_key": NbtDouble(.75)}));
    expect(
      NbtList([
        NbtByteArray(Int8List.fromList([0, 1, 2]))
      ]),
      NbtList([
        NbtByteArray(Int8List.fromList([0, 1, 2]))
      ]),
    );
  });

  test('read bigtest', () {
    expect(() => binaryToNbt(asset(const ["bigtest.nbt"]).readAsBytesSync()), throwsA(isA<NbtParsingException>()));
    expect(binaryToNbt(asset(const ["bigtest.nbt"]).readAsBytesSync(), compressed: true), isA<NbtCompound>());
  });

  test('bigtest to snbt', () {
    expect(
      binaryToNbt(asset(const ["bigtest.nbt"]).readAsBytesSync(), compressed: true).toSnbt(),
      asset(["bigtest.snbt"]).readAsStringSync(),
    );
  });

  test('binaryToNbt(bigtest.nbt) == snbtToNbt(bigtest.snbt)', () {
    expect(
      binaryToNbt(asset(const ["bigtest.nbt"]).readAsBytesSync(), compressed: true),
      snbtToNbt(asset(const ["bigtest.snbt"]).readAsStringSync()),
    );
  });

  test('omit optional field during encoding / read default during decoding', () {
    final endec = structEndec<(int?,)>().with1Field(
        Endec.i64.optionalOf().fieldOf("field", (struct) => struct.$1, defaultValueFactory: () => 0), (p0) => (p0,));

    expect(toNbt(endec, (null,)), NbtCompound(const {}));
    expect(fromNbt(endec, NbtCompound(const {})), (0,));
  });

  test('flatten present optional in optional field value', () {
    final optionalFieldEndec = structEndec<(int?,)>().with1Field(
      Endec.i64.optionalOf().fieldOf("field", (struct) => struct.$1, defaultValueFactory: () => 0),
      (p0) => (p0,),
    );

    final requiredFieldEndec = structEndec<(int?,)>().with1Field(
      Endec.i64.optionalOf().fieldOf("field", (struct) => struct.$1),
      (p0) => (p0,),
    );

    expect(toNbt(optionalFieldEndec, (7,)), const NbtCompound({"field": NbtLong(7)}));
    expect(
        toNbt(requiredFieldEndec, (7,)),
        const NbtCompound({
          "field": NbtCompound({"present": NbtByte(1), "value": NbtLong(7)})
        }));
  });

  test('omit only optional fields / retain required fields with optional values', () {
    final optionalFieldEndec = structEndec<(int?,)>().with1Field(
      Endec.i64.optionalOf().fieldOf("field", (struct) => struct.$1, defaultValueFactory: () => 0),
      (p0) => (p0,),
    );

    final requiredFieldEndec = structEndec<(int?,)>().with1Field(
      Endec.i64.optionalOf().fieldOf("field", (struct) => struct.$1),
      (p0) => (p0,),
    );

    expect(toNbt(optionalFieldEndec, (null,)), const NbtCompound({}));
    expect(
        toNbt(requiredFieldEndec, (null,)),
        const NbtCompound({
          "field": NbtCompound({"present": NbtByte(0)})
        }));
  });

  test('decode flattened optional field', () {
    final optionalFieldEndec = structEndec<(int?,)>().with1Field(
      Endec.i64.optionalOf().fieldOf("field", (struct) => struct.$1, defaultValueFactory: () => 0),
      (p0) => (p0,),
    );

    expect(fromNbt(optionalFieldEndec, const NbtCompound({'field': NbtLong(69)})), (69,));
  });

  test('decode non-optional defaulted field', () {
    final optionalFieldEndec = structEndec<(int,)>().with1Field(
      Endec.i64.fieldOf("field", (struct) => struct.$1, defaultValueFactory: () => 0),
      (p0) => (p0,),
    );

    expect(fromNbt(optionalFieldEndec, const NbtCompound({'field': NbtLong(69)})), (69,));
    expect(fromNbt(optionalFieldEndec, const NbtCompound({})), (0,));
  });

  test('test name', () {
    expect(
      () => fromNbt(Endec.i32, NbtLong(69)),
      throwsA(isA<MalformedInputException>().having(
        (e) => e.toString(),
        'toString()',
        r'Malformed input at $: Expected a NbtInt, got a NbtLong',
      )),
    );
  });

  test('snbt primitives', () {
    expect(snbtToNbt('true'), NbtByte(1));
    expect(snbtToNbt('false'), NbtByte(0));
    expect(snbtToNbt('15l'), NbtLong(15));
    expect(snbtToNbt('bruh'), NbtString('bruh'));
    expect(snbtToNbt("'br\\'uh'"), NbtString('br\'uh'));
  });
}

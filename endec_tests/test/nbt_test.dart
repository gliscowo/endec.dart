import 'dart:io';
import 'dart:typed_data';

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
}

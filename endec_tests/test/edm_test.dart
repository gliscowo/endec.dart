import 'dart:typed_data';

import 'package:endec/endec.dart';
import 'package:endec_edm/endec_edm.dart';
import 'package:test/test.dart';

void main() {
  test('toString formatting', () {
    expect(
      EdmElement.map({
        "ah_yes": EdmElement.sequence([EdmElement.i32(17), EdmElement.string("a")]),
        "hmmm": EdmElement.optional(null),
        "uhhh": EdmElement.optional(EdmElement.map({"b": EdmElement.optional(EdmElement.f32(16.5))}))
      }).toString(),
      """
map({
  ah_yes: sequence([
    i32(17),
    string(a)
  ]),
  hmmm: optional(),
  uhhh: optional(map({
    b: optional(f32(16.5))
  }))
})""",
    );
  });

  test('struct encode', () {
    final endec = structEndec<(List<int>, String?, Map<String, double?>?)>().with3Fields(
      Endec.i32.listOf().fieldOf('ah_yes', (struct) => struct.$1),
      Endec.string.optionalOf().fieldOf('hmmm', (struct) => struct.$2),
      Endec.f32.optionalOf().mapOf().optionalOf().fieldOf('uhhh', (struct) => struct.$3),
      (p0, p1, p2) => (p0, p1, p2),
    );

    expect(
      toEdm(endec, ([34, 35], null, {'b': 16.5})),
      EdmElement.map({
        'ah_yes': EdmElement.sequence([EdmElement.i32(34), EdmElement.i32(35)]),
        'hmmm': EdmElement.optional(null),
        'uhhh': EdmElement.optional(EdmElement.map({'b': EdmElement.optional(EdmElement.f32(16.5))}))
      }),
    );
  });

  test('struct decode', () {
    final endec = structEndec<(List<int>, String?, Map<String, double?>?)>().with3Fields(
      Endec.i32.listOf().fieldOf('ah_yes', (struct) => struct.$1),
      Endec.string.optionalOf().fieldOf('hmmm', (struct) => struct.$2),
      Endec.f32.optionalOf().mapOf().optionalOf().fieldOf('uhhh', (struct) => struct.$3),
      (p0, p1, p2) => (p0, p1, p2),
    );

    final decoded = fromEdm(
      endec,
      EdmElement.map({
        'ah_yes': EdmElement.sequence([EdmElement.i32(34), EdmElement.i32(35)]),
        'hmmm': EdmElement.optional(null),
        'uhhh': EdmElement.optional(EdmElement.map({'b': EdmElement.optional(EdmElement.f32(16.5))}))
      }),
    );

    expect(decoded.$1, [34, 35]);
    expect(decoded.$2, isNull);
    expect(decoded.$3, equals({'b': 16.5}));
  });

  test('edm encode / decode', () {
    final edm = EdmElement.map({
      "ah_yes": EdmElement.sequence([EdmElement.i32(17), EdmElement.string("a")]),
      "hmmm": EdmElement.optional(null),
      "uhhh": EdmElement.optional(EdmElement.map({"b": EdmElement.optional(EdmElement.f32(16.5))}))
    });

    expect(decodeEdmElement(encodeEdmElement(edm)), edm);
  });

  test('bytes formatting', () {
    print(EdmElement.bytes(Uint8List.fromList([1, 2, 4, 8, 16])));
  });
}

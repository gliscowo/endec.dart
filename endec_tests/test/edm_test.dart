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
  hmmm: optional(null),
  uhhh: optional(map({
    b: optional(f32(16.5))
  }))
})""",
    );
  });
}

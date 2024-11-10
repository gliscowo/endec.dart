import 'dart:convert';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:endec/endec.dart';
import 'package:endec_json/endec_json.dart';

class JsonStringBenchmark extends BenchmarkBase {
  static const _json = r'''
{
  "string": "bruh",
  "bruh": [
    {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false},
        {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false},
        {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false},
        {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false},
        {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false},    {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false},    {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false},
        {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false},
        {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false},
        {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false},
        {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false},    {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false},


        {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false},

        {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false},
        {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false},
        {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false},
        {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false},
        {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false},
        {"1.5": false, "3.8678": true},
    {"-1.5": true, "2.1e5": false}




  ],
  "int": 69
}
''';

  final _endec = structEndec<(int, String, List<Map<double, bool>>)>().with3Fields(
    Endec.i32.fieldOf('int', (struct) => struct.$1),
    Endec.string.fieldOf('string', (struct) => struct.$2),
    Endec.map((d) => d.toString(), double.parse, Endec.bool).listOf().fieldOf('bruh', (struct) => struct.$3),
    (p0, p1, p2) => (p0, p1, p2),
  );

  JsonStringBenchmark(super.name);

  @override
  void run() => _endec.decode(SerializationContext.empty, JsonDeserializer(jsonDecode(_json)));

  @override
  void exercise() => run();
}

void main(List<String> args) {
  JsonStringBenchmark('json deserializer').report();
}

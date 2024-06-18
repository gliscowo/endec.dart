import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/struct_endec_generator.dart';

Builder endecBuilder(BuilderOptions options) => SharedPartBuilder([StructEndecGenerator()], 'endec');

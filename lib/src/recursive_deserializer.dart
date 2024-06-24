import 'dart:collection';

import 'package:endec/endec.dart';
import 'package:meta/meta.dart';

typedef _Frame<T> = ({T Function() source, bool isStructField});

abstract class RecursiveDeserializer<T> implements Deserializer {
  final Queue<_Frame<T>> _frames = Queue();
  final T _serialized;

  RecursiveDeserializer(this._serialized) {
    _frames.add((source: () => _serialized, isStructField: false));
  }

  @protected
  bool get isReadingStructField => _frames.last.isStructField;

  V currentValue<V extends T>() => _frames.last.source() as V;

  V frame<V>(T Function() nextValue, V Function() action, bool isStructField) {
    try {
      _frames.add((source: nextValue, isStructField: isStructField));
      return action();
    } finally {
      _frames.removeLast();
    }
  }

  @override
  V tryRead<V>(V Function(Deserializer deserializer) reader) {
    final framesBackup = Queue.of(_frames);

    try {
      return reader(this);
    } catch (_) {
      _frames.clear();
      _frames.addAll(framesBackup);

      rethrow;
    }
  }
}

import 'dart:collection';

import '../endec.dart';

typedef _Frame<T> = T Function();

abstract class RecursiveDeserializer<T> implements Deserializer {
  final Queue<_Frame<T>> _frames = Queue();
  final T _serialized;

  RecursiveDeserializer(this._serialized) {
    _frames.add(() => _serialized);
  }

  V currentValue<V extends T>(SerializationContext ctx) {
    final lastValue = _frames.last();
    return lastValue is V ? lastValue : ctx.malformedInput('Expected a $V, got a ${lastValue.runtimeType}');
  }

  V frame<V>(T Function() nextValue, V Function() action) {
    try {
      _frames.add(nextValue);
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

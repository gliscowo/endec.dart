import 'dart:collection';

import 'package:endec/endec.dart';
import 'package:meta/meta.dart';

typedef _Frame<T> = ({void Function(T) sink, bool isStructField});

abstract class RecursiveSerializer<T> implements Serializer {
  final Queue<_Frame<T>> _frames = Queue();
  T _result;

  RecursiveSerializer(this._result) {
    _frames.add((sink: (t) => _result = t, isStructField: false));
  }

  @protected
  bool get isWritingStructField => _frames.last.isStructField;

  void consume(T value) => _frames.last.sink(value);

  void frame(void Function(EncodedValue<T> holder) action, bool isStructField) {
    final holder = EncodedValue<T>();

    _frames.add((sink: holder._set, isStructField: isStructField));
    action(holder);
    _frames.removeLast();
  }

  T get result => _result;
}

class EncodedValue<T> {
  T? _value;
  bool _encoded = false;

  void _set(T value) {
    _value = value;
    _encoded = true;
  }

  T get get => _value as T;
  bool get wasEncoded => _encoded;

  T require(String name) {
    if (!_encoded) throw RecursiveEncodingError("Endec for $name serialized nothing");
    return get;
  }
}

class RecursiveEncodingError extends Error {
  final String message;
  RecursiveEncodingError(this.message);

  @override
  String toString() => message;
}

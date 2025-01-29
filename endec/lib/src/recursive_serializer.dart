import 'dart:collection';

import '../endec.dart';

typedef _Frame<T> = void Function(T);

abstract class RecursiveSerializer<T> implements Serializer {
  final Queue<_Frame<T>> _frames = Queue();
  T _result;

  RecursiveSerializer(this._result) {
    _frames.add((t) => _result = t);
  }

  void consume(T value) => _frames.last(value);

  void frame(void Function(EncodedValue<T> holder) action) {
    final holder = EncodedValue<T>();

    _frames.add(holder._set);
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

  T get value => _value as T;
  bool get wasEncoded => _encoded;

  T require(String name) {
    if (!_encoded) throw RecursiveEncodingError('Endec for $name serialized nothing');
    return value;
  }
}

class RecursiveEncodingError extends Error {
  final String message;
  RecursiveEncodingError(this.message);

  @override
  String toString() => message;
}

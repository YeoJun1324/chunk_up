// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'word.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Word _$WordFromJson(Map<String, dynamic> json) {
  return _Word.fromJson(json);
}

/// @nodoc
mixin _$Word {
  String get english => throw _privateConstructorUsedError;
  String get korean => throw _privateConstructorUsedError;
  bool get isInChunk => throw _privateConstructorUsedError;
  double get learningProgress => throw _privateConstructorUsedError;
  DateTime? get lastLearned => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  List<String> get examples => throw _privateConstructorUsedError;
  String? get memo => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WordCopyWith<Word> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WordCopyWith<$Res> {
  factory $WordCopyWith(Word value, $Res Function(Word) then) =
      _$WordCopyWithImpl<$Res, Word>;
  @useResult
  $Res call(
      {String english,
      String korean,
      bool isInChunk,
      double learningProgress,
      DateTime? lastLearned,
      String? category,
      List<String> examples,
      String? memo});
}

/// @nodoc
class _$WordCopyWithImpl<$Res, $Val extends Word>
    implements $WordCopyWith<$Res> {
  _$WordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? english = null,
    Object? korean = null,
    Object? isInChunk = null,
    Object? learningProgress = null,
    Object? lastLearned = freezed,
    Object? category = freezed,
    Object? examples = null,
    Object? memo = freezed,
  }) {
    return _then(_value.copyWith(
      english: null == english
          ? _value.english
          : english // ignore: cast_nullable_to_non_nullable
              as String,
      korean: null == korean
          ? _value.korean
          : korean // ignore: cast_nullable_to_non_nullable
              as String,
      isInChunk: null == isInChunk
          ? _value.isInChunk
          : isInChunk // ignore: cast_nullable_to_non_nullable
              as bool,
      learningProgress: null == learningProgress
          ? _value.learningProgress
          : learningProgress // ignore: cast_nullable_to_non_nullable
              as double,
      lastLearned: freezed == lastLearned
          ? _value.lastLearned
          : lastLearned // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      examples: null == examples
          ? _value.examples
          : examples // ignore: cast_nullable_to_non_nullable
              as List<String>,
      memo: freezed == memo
          ? _value.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WordImplCopyWith<$Res> implements $WordCopyWith<$Res> {
  factory _$$WordImplCopyWith(
          _$WordImpl value, $Res Function(_$WordImpl) then) =
      __$$WordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String english,
      String korean,
      bool isInChunk,
      double learningProgress,
      DateTime? lastLearned,
      String? category,
      List<String> examples,
      String? memo});
}

/// @nodoc
class __$$WordImplCopyWithImpl<$Res>
    extends _$WordCopyWithImpl<$Res, _$WordImpl>
    implements _$$WordImplCopyWith<$Res> {
  __$$WordImplCopyWithImpl(_$WordImpl _value, $Res Function(_$WordImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? english = null,
    Object? korean = null,
    Object? isInChunk = null,
    Object? learningProgress = null,
    Object? lastLearned = freezed,
    Object? category = freezed,
    Object? examples = null,
    Object? memo = freezed,
  }) {
    return _then(_$WordImpl(
      english: null == english
          ? _value.english
          : english // ignore: cast_nullable_to_non_nullable
              as String,
      korean: null == korean
          ? _value.korean
          : korean // ignore: cast_nullable_to_non_nullable
              as String,
      isInChunk: null == isInChunk
          ? _value.isInChunk
          : isInChunk // ignore: cast_nullable_to_non_nullable
              as bool,
      learningProgress: null == learningProgress
          ? _value.learningProgress
          : learningProgress // ignore: cast_nullable_to_non_nullable
              as double,
      lastLearned: freezed == lastLearned
          ? _value.lastLearned
          : lastLearned // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      examples: null == examples
          ? _value._examples
          : examples // ignore: cast_nullable_to_non_nullable
              as List<String>,
      memo: freezed == memo
          ? _value.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WordImpl extends _Word {
  const _$WordImpl(
      {required this.english,
      required this.korean,
      this.isInChunk = false,
      this.learningProgress = 0.0,
      this.lastLearned,
      this.category,
      final List<String> examples = const [],
      this.memo})
      : _examples = examples,
        super._();

  factory _$WordImpl.fromJson(Map<String, dynamic> json) =>
      _$$WordImplFromJson(json);

  @override
  final String english;
  @override
  final String korean;
  @override
  @JsonKey()
  final bool isInChunk;
  @override
  @JsonKey()
  final double learningProgress;
  @override
  final DateTime? lastLearned;
  @override
  final String? category;
  final List<String> _examples;
  @override
  @JsonKey()
  List<String> get examples {
    if (_examples is EqualUnmodifiableListView) return _examples;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_examples);
  }

  @override
  final String? memo;

  @override
  String toString() {
    return 'Word(english: $english, korean: $korean, isInChunk: $isInChunk, learningProgress: $learningProgress, lastLearned: $lastLearned, category: $category, examples: $examples, memo: $memo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WordImpl &&
            (identical(other.english, english) || other.english == english) &&
            (identical(other.korean, korean) || other.korean == korean) &&
            (identical(other.isInChunk, isInChunk) ||
                other.isInChunk == isInChunk) &&
            (identical(other.learningProgress, learningProgress) ||
                other.learningProgress == learningProgress) &&
            (identical(other.lastLearned, lastLearned) ||
                other.lastLearned == lastLearned) &&
            (identical(other.category, category) ||
                other.category == category) &&
            const DeepCollectionEquality().equals(other._examples, _examples) &&
            (identical(other.memo, memo) || other.memo == memo));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      english,
      korean,
      isInChunk,
      learningProgress,
      lastLearned,
      category,
      const DeepCollectionEquality().hash(_examples),
      memo);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WordImplCopyWith<_$WordImpl> get copyWith =>
      __$$WordImplCopyWithImpl<_$WordImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WordImplToJson(
      this,
    );
  }
}

abstract class _Word extends Word {
  const factory _Word(
      {required final String english,
      required final String korean,
      final bool isInChunk,
      final double learningProgress,
      final DateTime? lastLearned,
      final String? category,
      final List<String> examples,
      final String? memo}) = _$WordImpl;
  const _Word._() : super._();

  factory _Word.fromJson(Map<String, dynamic> json) = _$WordImpl.fromJson;

  @override
  String get english;
  @override
  String get korean;
  @override
  bool get isInChunk;
  @override
  double get learningProgress;
  @override
  DateTime? get lastLearned;
  @override
  String? get category;
  @override
  List<String> get examples;
  @override
  String? get memo;
  @override
  @JsonKey(ignore: true)
  _$$WordImplCopyWith<_$WordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
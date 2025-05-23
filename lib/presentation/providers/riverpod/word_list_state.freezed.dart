// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'word_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WordListInfo _$WordListInfoFromJson(Map<String, dynamic> json) {
  return _WordListInfo.fromJson(json);
}

/// @nodoc
mixin _$WordListInfo {
  String get name => throw _privateConstructorUsedError;
  List<Word> get words => throw _privateConstructorUsedError;
  List<Chunk> get chunks => throw _privateConstructorUsedError;
  int get chunkCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WordListInfoCopyWith<WordListInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WordListInfoCopyWith<$Res> {
  factory $WordListInfoCopyWith(
          WordListInfo value, $Res Function(WordListInfo) then) =
      _$WordListInfoCopyWithImpl<$Res, WordListInfo>;
  @useResult
  $Res call(
      {String name, List<Word> words, List<Chunk> chunks, int chunkCount});
}

/// @nodoc
class _$WordListInfoCopyWithImpl<$Res, $Val extends WordListInfo>
    implements $WordListInfoCopyWith<$Res> {
  _$WordListInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? words = null,
    Object? chunks = null,
    Object? chunkCount = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      words: null == words
          ? _value.words
          : words // ignore: cast_nullable_to_non_nullable
              as List<Word>,
      chunks: null == chunks
          ? _value.chunks
          : chunks // ignore: cast_nullable_to_non_nullable
              as List<Chunk>,
      chunkCount: null == chunkCount
          ? _value.chunkCount
          : chunkCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WordListInfoImplCopyWith<$Res>
    implements $WordListInfoCopyWith<$Res> {
  factory _$$WordListInfoImplCopyWith(
          _$WordListInfoImpl value, $Res Function(_$WordListInfoImpl) then) =
      __$$WordListInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name, List<Word> words, List<Chunk> chunks, int chunkCount});
}

/// @nodoc
class __$$WordListInfoImplCopyWithImpl<$Res>
    extends _$WordListInfoCopyWithImpl<$Res, _$WordListInfoImpl>
    implements _$$WordListInfoImplCopyWith<$Res> {
  __$$WordListInfoImplCopyWithImpl(
      _$WordListInfoImpl _value, $Res Function(_$WordListInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? words = null,
    Object? chunks = null,
    Object? chunkCount = null,
  }) {
    return _then(_$WordListInfoImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      words: null == words
          ? _value._words
          : words // ignore: cast_nullable_to_non_nullable
              as List<Word>,
      chunks: null == chunks
          ? _value._chunks
          : chunks // ignore: cast_nullable_to_non_nullable
              as List<Chunk>,
      chunkCount: null == chunkCount
          ? _value.chunkCount
          : chunkCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WordListInfoImpl extends _WordListInfo {
  const _$WordListInfoImpl(
      {required this.name,
      final List<Word> words = const [],
      final List<Chunk> chunks = const [],
      this.chunkCount = 0})
      : _words = words,
        _chunks = chunks,
        super._();

  factory _$WordListInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$WordListInfoImplFromJson(json);

  @override
  final String name;
  final List<Word> _words;
  @override
  @JsonKey()
  List<Word> get words {
    if (_words is EqualUnmodifiableListView) return _words;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_words);
  }

  final List<Chunk> _chunks;
  @override
  @JsonKey()
  List<Chunk> get chunks {
    if (_chunks is EqualUnmodifiableListView) return _chunks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_chunks);
  }

  @override
  @JsonKey()
  final int chunkCount;

  @override
  String toString() {
    return 'WordListInfo(name: $name, words: $words, chunks: $chunks, chunkCount: $chunkCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WordListInfoImpl &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._words, _words) &&
            const DeepCollectionEquality().equals(other._chunks, _chunks) &&
            (identical(other.chunkCount, chunkCount) ||
                other.chunkCount == chunkCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      const DeepCollectionEquality().hash(_words),
      const DeepCollectionEquality().hash(_chunks),
      chunkCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WordListInfoImplCopyWith<_$WordListInfoImpl> get copyWith =>
      __$$WordListInfoImplCopyWithImpl<_$WordListInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WordListInfoImplToJson(
      this,
    );
  }
}

abstract class _WordListInfo extends WordListInfo {
  const factory _WordListInfo(
      {required final String name,
      final List<Word> words,
      final List<Chunk> chunks,
      final int chunkCount}) = _$WordListInfoImpl;
  const _WordListInfo._() : super._();

  factory _WordListInfo.fromJson(Map<String, dynamic> json) =
      _$WordListInfoImpl.fromJson;

  @override
  String get name;
  @override
  List<Word> get words;
  @override
  List<Chunk> get chunks;
  @override
  int get chunkCount;
  @override
  @JsonKey(ignore: true)
  _$$WordListInfoImplCopyWith<_$WordListInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$WordListState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(String message, List<WordListInfo> wordLists)
        error,
    required TResult Function(
            List<WordListInfo> wordLists, String? selectedWordListName)
        loaded,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(String message, List<WordListInfo> wordLists)? error,
    TResult? Function(
            List<WordListInfo> wordLists, String? selectedWordListName)?
        loaded,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(String message, List<WordListInfo> wordLists)? error,
    TResult Function(
            List<WordListInfo> wordLists, String? selectedWordListName)?
        loaded,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Loading value) loading,
    required TResult Function(_Error value) error,
    required TResult Function(_Loaded value) loaded,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Error value)? error,
    TResult? Function(_Loaded value)? loaded,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Loading value)? loading,
    TResult Function(_Error value)? error,
    TResult Function(_Loaded value)? loaded,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WordListStateCopyWith<$Res> {
  factory $WordListStateCopyWith(
          WordListState value, $Res Function(WordListState) then) =
      _$WordListStateCopyWithImpl<$Res, WordListState>;
}

/// @nodoc
class _$WordListStateCopyWithImpl<$Res, $Val extends WordListState>
    implements $WordListStateCopyWith<$Res> {
  _$WordListStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$LoadingImplCopyWith<$Res> {
  factory _$$LoadingImplCopyWith(
          _$LoadingImpl value, $Res Function(_$LoadingImpl) then) =
      __$$LoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadingImplCopyWithImpl<$Res>
    extends _$WordListStateCopyWithImpl<$Res, _$LoadingImpl>
    implements _$$LoadingImplCopyWith<$Res> {
  __$$LoadingImplCopyWithImpl(
      _$LoadingImpl _value, $Res Function(_$LoadingImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$LoadingImpl extends _Loading {
  const _$LoadingImpl() : super._();

  @override
  String toString() {
    return 'WordListState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(String message, List<WordListInfo> wordLists)
        error,
    required TResult Function(
            List<WordListInfo> wordLists, String? selectedWordListName)
        loaded,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(String message, List<WordListInfo> wordLists)? error,
    TResult? Function(
            List<WordListInfo> wordLists, String? selectedWordListName)?
        loaded,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(String message, List<WordListInfo> wordLists)? error,
    TResult Function(
            List<WordListInfo> wordLists, String? selectedWordListName)?
        loaded,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Loading value) loading,
    required TResult Function(_Error value) error,
    required TResult Function(_Loaded value) loaded,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Error value)? error,
    TResult? Function(_Loaded value)? loaded,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Loading value)? loading,
    TResult Function(_Error value)? error,
    TResult Function(_Loaded value)? loaded,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _Loading extends WordListState {
  const factory _Loading() = _$LoadingImpl;
  const _Loading._() : super._();
}

/// @nodoc
abstract class _$$ErrorImplCopyWith<$Res> {
  factory _$$ErrorImplCopyWith(
          _$ErrorImpl value, $Res Function(_$ErrorImpl) then) =
      __$$ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message, List<WordListInfo> wordLists});
}

/// @nodoc
class __$$ErrorImplCopyWithImpl<$Res>
    extends _$WordListStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
      _$ErrorImpl _value, $Res Function(_$ErrorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? wordLists = null,
  }) {
    return _then(_$ErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      wordLists: null == wordLists
          ? _value._wordLists
          : wordLists // ignore: cast_nullable_to_non_nullable
              as List<WordListInfo>,
    ));
  }
}

/// @nodoc

class _$ErrorImpl extends _Error {
  const _$ErrorImpl(
      {required this.message, final List<WordListInfo> wordLists = const []})
      : _wordLists = wordLists,
        super._();

  @override
  final String message;
  final List<WordListInfo> _wordLists;
  @override
  @JsonKey()
  List<WordListInfo> get wordLists {
    if (_wordLists is EqualUnmodifiableListView) return _wordLists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_wordLists);
  }

  @override
  String toString() {
    return 'WordListState.error(message: $message, wordLists: $wordLists)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorImpl &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality()
                .equals(other._wordLists, _wordLists));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, message, const DeepCollectionEquality().hash(_wordLists));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      __$$ErrorImplCopyWithImpl<_$ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(String message, List<WordListInfo> wordLists)
        error,
    required TResult Function(
            List<WordListInfo> wordLists, String? selectedWordListName)
        loaded,
  }) {
    return error(message, wordLists);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(String message, List<WordListInfo> wordLists)? error,
    TResult? Function(
            List<WordListInfo> wordLists, String? selectedWordListName)?
        loaded,
  }) {
    return error?.call(message, wordLists);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(String message, List<WordListInfo> wordLists)? error,
    TResult Function(
            List<WordListInfo> wordLists, String? selectedWordListName)?
        loaded,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message, wordLists);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Loading value) loading,
    required TResult Function(_Error value) error,
    required TResult Function(_Loaded value) loaded,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Error value)? error,
    TResult? Function(_Loaded value)? loaded,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Loading value)? loading,
    TResult Function(_Error value)? error,
    TResult Function(_Loaded value)? loaded,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error extends WordListState {
  const factory _Error(
      {required final String message,
      final List<WordListInfo> wordLists}) = _$ErrorImpl;
  const _Error._() : super._();

  String get message;
  List<WordListInfo> get wordLists;
  @JsonKey(ignore: true)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LoadedImplCopyWith<$Res> {
  factory _$$LoadedImplCopyWith(
          _$LoadedImpl value, $Res Function(_$LoadedImpl) then) =
      __$$LoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<WordListInfo> wordLists, String? selectedWordListName});
}

/// @nodoc
class __$$LoadedImplCopyWithImpl<$Res>
    extends _$WordListStateCopyWithImpl<$Res, _$LoadedImpl>
    implements _$$LoadedImplCopyWith<$Res> {
  __$$LoadedImplCopyWithImpl(
      _$LoadedImpl _value, $Res Function(_$LoadedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? wordLists = null,
    Object? selectedWordListName = freezed,
  }) {
    return _then(_$LoadedImpl(
      wordLists: null == wordLists
          ? _value._wordLists
          : wordLists // ignore: cast_nullable_to_non_nullable
              as List<WordListInfo>,
      selectedWordListName: freezed == selectedWordListName
          ? _value.selectedWordListName
          : selectedWordListName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$LoadedImpl extends _Loaded {
  const _$LoadedImpl(
      {required final List<WordListInfo> wordLists, this.selectedWordListName})
      : _wordLists = wordLists,
        super._();

  final List<WordListInfo> _wordLists;
  @override
  List<WordListInfo> get wordLists {
    if (_wordLists is EqualUnmodifiableListView) return _wordLists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_wordLists);
  }

  @override
  final String? selectedWordListName;

  @override
  String toString() {
    return 'WordListState.loaded(wordLists: $wordLists, selectedWordListName: $selectedWordListName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadedImpl &&
            const DeepCollectionEquality()
                .equals(other._wordLists, _wordLists) &&
            (identical(other.selectedWordListName, selectedWordListName) ||
                other.selectedWordListName == selectedWordListName));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_wordLists), selectedWordListName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
      __$$LoadedImplCopyWithImpl<_$LoadedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(String message, List<WordListInfo> wordLists)
        error,
    required TResult Function(
            List<WordListInfo> wordLists, String? selectedWordListName)
        loaded,
  }) {
    return loaded(wordLists, selectedWordListName);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(String message, List<WordListInfo> wordLists)? error,
    TResult? Function(
            List<WordListInfo> wordLists, String? selectedWordListName)?
        loaded,
  }) {
    return loaded?.call(wordLists, selectedWordListName);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(String message, List<WordListInfo> wordLists)? error,
    TResult Function(
            List<WordListInfo> wordLists, String? selectedWordListName)?
        loaded,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(wordLists, selectedWordListName);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Loading value) loading,
    required TResult Function(_Error value) error,
    required TResult Function(_Loaded value) loaded,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Error value)? error,
    TResult? Function(_Loaded value)? loaded,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Loading value)? loading,
    TResult Function(_Error value)? error,
    TResult Function(_Loaded value)? loaded,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class _Loaded extends WordListState {
  const factory _Loaded(
      {required final List<WordListInfo> wordLists,
      final String? selectedWordListName}) = _$LoadedImpl;
  const _Loaded._() : super._();

  List<WordListInfo> get wordLists;
  String? get selectedWordListName;
  @JsonKey(ignore: true)
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
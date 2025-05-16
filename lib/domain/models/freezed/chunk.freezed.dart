// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chunk.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Chunk _$ChunkFromJson(Map<String, dynamic> json) {
  return _Chunk.fromJson(json);
}

/// @nodoc
mixin _$Chunk {
  String? get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get englishContent => throw _privateConstructorUsedError;
  String get koreanTranslation => throw _privateConstructorUsedError;
  List<Word> get includedWords => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  Map<String, String> get wordExplanations => throw _privateConstructorUsedError;
  String? get character => throw _privateConstructorUsedError;
  String? get scenario => throw _privateConstructorUsedError;
  String? get additionalDetails => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ChunkCopyWith<Chunk> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChunkCopyWith<$Res> {
  factory $ChunkCopyWith(Chunk value, $Res Function(Chunk) then) =
      _$ChunkCopyWithImpl<$Res, Chunk>;
  @useResult
  $Res call(
      {String? id,
      String title,
      String englishContent,
      String koreanTranslation,
      List<Word> includedWords,
      DateTime? createdAt,
      Map<String, String> wordExplanations,
      String? character,
      String? scenario,
      String? additionalDetails});
}

/// @nodoc
class _$ChunkCopyWithImpl<$Res, $Val extends Chunk>
    implements $ChunkCopyWith<$Res> {
  _$ChunkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? title = null,
    Object? englishContent = null,
    Object? koreanTranslation = null,
    Object? includedWords = null,
    Object? createdAt = freezed,
    Object? wordExplanations = null,
    Object? character = freezed,
    Object? scenario = freezed,
    Object? additionalDetails = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      englishContent: null == englishContent
          ? _value.englishContent
          : englishContent // ignore: cast_nullable_to_non_nullable
              as String,
      koreanTranslation: null == koreanTranslation
          ? _value.koreanTranslation
          : koreanTranslation // ignore: cast_nullable_to_non_nullable
              as String,
      includedWords: null == includedWords
          ? _value.includedWords
          : includedWords // ignore: cast_nullable_to_non_nullable
              as List<Word>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      wordExplanations: null == wordExplanations
          ? _value.wordExplanations
          : wordExplanations // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      character: freezed == character
          ? _value.character
          : character // ignore: cast_nullable_to_non_nullable
              as String?,
      scenario: freezed == scenario
          ? _value.scenario
          : scenario // ignore: cast_nullable_to_non_nullable
              as String?,
      additionalDetails: freezed == additionalDetails
          ? _value.additionalDetails
          : additionalDetails // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChunkImplCopyWith<$Res> implements $ChunkCopyWith<$Res> {
  factory _$$ChunkImplCopyWith(
          _$ChunkImpl value, $Res Function(_$ChunkImpl) then) =
      __$$ChunkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? id,
      String title,
      String englishContent,
      String koreanTranslation,
      List<Word> includedWords,
      DateTime? createdAt,
      Map<String, String> wordExplanations,
      String? character,
      String? scenario,
      String? additionalDetails});
}

/// @nodoc
class __$$ChunkImplCopyWithImpl<$Res>
    extends _$ChunkCopyWithImpl<$Res, _$ChunkImpl>
    implements _$$ChunkImplCopyWith<$Res> {
  __$$ChunkImplCopyWithImpl(
      _$ChunkImpl _value, $Res Function(_$ChunkImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? title = null,
    Object? englishContent = null,
    Object? koreanTranslation = null,
    Object? includedWords = null,
    Object? createdAt = freezed,
    Object? wordExplanations = null,
    Object? character = freezed,
    Object? scenario = freezed,
    Object? additionalDetails = freezed,
  }) {
    return _then(_$ChunkImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      englishContent: null == englishContent
          ? _value.englishContent
          : englishContent // ignore: cast_nullable_to_non_nullable
              as String,
      koreanTranslation: null == koreanTranslation
          ? _value.koreanTranslation
          : koreanTranslation // ignore: cast_nullable_to_non_nullable
              as String,
      includedWords: null == includedWords
          ? _value._includedWords
          : includedWords // ignore: cast_nullable_to_non_nullable
              as List<Word>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      wordExplanations: null == wordExplanations
          ? _value._wordExplanations
          : wordExplanations // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      character: freezed == character
          ? _value.character
          : character // ignore: cast_nullable_to_non_nullable
              as String?,
      scenario: freezed == scenario
          ? _value.scenario
          : scenario // ignore: cast_nullable_to_non_nullable
              as String?,
      additionalDetails: freezed == additionalDetails
          ? _value.additionalDetails
          : additionalDetails // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChunkImpl extends _Chunk {
  _$ChunkImpl(
      {this.id,
      required this.title,
      required this.englishContent,
      required this.koreanTranslation,
      required final List<Word> includedWords,
      this.createdAt,
      final Map<String, String> wordExplanations = const <String, String>{},
      this.character,
      this.scenario,
      this.additionalDetails})
      : _includedWords = includedWords,
        _wordExplanations = wordExplanations,
        super._();

  factory _$ChunkImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChunkImplFromJson(json);

  @override
  final String? id;
  @override
  final String title;
  @override
  final String englishContent;
  @override
  final String koreanTranslation;
  final List<Word> _includedWords;
  @override
  List<Word> get includedWords {
    if (_includedWords is EqualUnmodifiableListView) return _includedWords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_includedWords);
  }

  @override
  final DateTime? createdAt;
  final Map<String, String> _wordExplanations;
  @override
  @JsonKey()
  Map<String, String> get wordExplanations {
    if (_wordExplanations is EqualUnmodifiableMapView) return _wordExplanations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_wordExplanations);
  }

  @override
  final String? character;
  @override
  final String? scenario;
  @override
  final String? additionalDetails;

  @override
  String toString() {
    return 'Chunk(id: $id, title: $title, englishContent: $englishContent, koreanTranslation: $koreanTranslation, includedWords: $includedWords, createdAt: $createdAt, wordExplanations: $wordExplanations, character: $character, scenario: $scenario, additionalDetails: $additionalDetails)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChunkImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.englishContent, englishContent) ||
                other.englishContent == englishContent) &&
            (identical(other.koreanTranslation, koreanTranslation) ||
                other.koreanTranslation == koreanTranslation) &&
            const DeepCollectionEquality()
                .equals(other._includedWords, _includedWords) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality()
                .equals(other._wordExplanations, _wordExplanations) &&
            (identical(other.character, character) ||
                other.character == character) &&
            (identical(other.scenario, scenario) ||
                other.scenario == scenario) &&
            (identical(other.additionalDetails, additionalDetails) ||
                other.additionalDetails == additionalDetails));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      englishContent,
      koreanTranslation,
      const DeepCollectionEquality().hash(_includedWords),
      createdAt,
      const DeepCollectionEquality().hash(_wordExplanations),
      character,
      scenario,
      additionalDetails);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChunkImplCopyWith<_$ChunkImpl> get copyWith =>
      __$$ChunkImplCopyWithImpl<_$ChunkImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChunkImplToJson(
      this,
    );
  }
}

abstract class _Chunk extends Chunk {
  factory _Chunk(
      {final String? id,
      required final String title,
      required final String englishContent,
      required final String koreanTranslation,
      required final List<Word> includedWords,
      final DateTime? createdAt,
      final Map<String, String> wordExplanations,
      final String? character,
      final String? scenario,
      final String? additionalDetails}) = _$ChunkImpl;
  _Chunk._() : super._();

  factory _Chunk.fromJson(Map<String, dynamic> json) = _$ChunkImpl.fromJson;

  @override
  String? get id;
  @override
  String get title;
  @override
  String get englishContent;
  @override
  String get koreanTranslation;
  @override
  List<Word> get includedWords;
  @override
  DateTime? get createdAt;
  @override
  Map<String, String> get wordExplanations;
  @override
  String? get character;
  @override
  String? get scenario;
  @override
  String? get additionalDetails;
  @override
  @JsonKey(ignore: true)
  _$$ChunkImplCopyWith<_$ChunkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chunk.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChunkImpl _$$ChunkImplFromJson(Map<String, dynamic> json) => _$ChunkImpl(
      id: json['id'] as String?,
      title: json['title'] as String,
      englishContent: json['englishContent'] as String,
      koreanTranslation: json['koreanTranslation'] as String,
      includedWords: (json['includedWords'] as List<dynamic>)
          .map((e) => Word.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      wordExplanations: (json['wordExplanations'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      character: json['character'] as String?,
      scenario: json['scenario'] as String?,
      additionalDetails: json['additionalDetails'] as String?,
    );

Map<String, dynamic> _$$ChunkImplToJson(_$ChunkImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'englishContent': instance.englishContent,
      'koreanTranslation': instance.koreanTranslation,
      'includedWords': instance.includedWords.map((e) => e.toJson()).toList(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'wordExplanations': instance.wordExplanations,
      'character': instance.character,
      'scenario': instance.scenario,
      'additionalDetails': instance.additionalDetails,
    };
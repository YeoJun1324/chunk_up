// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WordImpl _$$WordImplFromJson(Map<String, dynamic> json) => _$WordImpl(
      english: json['english'] as String,
      korean: json['korean'] as String,
      isInChunk: json['isInChunk'] as bool? ?? false,
      learningProgress: (json['learningProgress'] as num?)?.toDouble() ?? 0.0,
      lastLearned: json['lastLearned'] == null
          ? null
          : DateTime.parse(json['lastLearned'] as String),
      category: json['category'] as String?,
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      memo: json['memo'] as String?,
    );

Map<String, dynamic> _$$WordImplToJson(_$WordImpl instance) =>
    <String, dynamic>{
      'english': instance.english,
      'korean': instance.korean,
      'isInChunk': instance.isInChunk,
      'learningProgress': instance.learningProgress,
      'lastLearned': instance.lastLearned?.toIso8601String(),
      'category': instance.category,
      'examples': instance.examples,
      'memo': instance.memo,
    };
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_list_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WordListInfoImpl _$$WordListInfoImplFromJson(Map<String, dynamic> json) =>
    _$WordListInfoImpl(
      name: json['name'] as String,
      words: (json['words'] as List<dynamic>?)
              ?.map((e) => Word.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      chunks: (json['chunks'] as List<dynamic>?)
              ?.map((e) => Chunk.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      chunkCount: json['chunkCount'] as int? ?? 0,
    );

Map<String, dynamic> _$$WordListInfoImplToJson(_$WordListInfoImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'words': instance.words.map((e) => e.toJson()).toList(),
      'chunks': instance.chunks.map((e) => e.toJson()).toList(),
      'chunkCount': instance.chunkCount,
    };
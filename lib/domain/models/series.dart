// lib/domain/models/series.dart
import 'package:chunk_up/domain/models/character.dart';

/// 시리즈 설정
class SeriesSettings {
  final String genre;
  final String worldSetting;
  final Map<String, dynamic> customSettings;

  SeriesSettings({
    this.genre = '',
    this.worldSetting = '',
    this.customSettings = const {},
  });

  Map<String, dynamic> toJson() => {
    'genre': genre,
    'worldSetting': worldSetting,
    'customSettings': customSettings,
  };

  factory SeriesSettings.fromJson(Map<String, dynamic> json) {
    return SeriesSettings(
      genre: json['genre'] ?? '',
      worldSetting: json['worldSetting'] ?? '',
      customSettings: Map<String, dynamic>.from(json['customSettings'] ?? {}),
    );
  }
}

/// 시리즈 모델
class Series {
  final String id;
  final String name;
  final String description;
  final List<String> characterIds;
  final List<String> relationshipIds;
  final SeriesSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  Series({
    required this.id,
    required this.name,
    required this.description,
    this.characterIds = const [],
    this.relationshipIds = const [],
    SeriesSettings? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    settings = settings ?? SeriesSettings(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Series copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? characterIds,
    List<String>? relationshipIds,
    SeriesSettings? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Series(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      characterIds: characterIds ?? List<String>.from(this.characterIds),
      relationshipIds: relationshipIds ?? List<String>.from(this.relationshipIds),
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'characterIds': characterIds,
    'relationshipIds': relationshipIds,
    'settings': settings.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      characterIds: List<String>.from(json['characterIds'] ?? []),
      relationshipIds: List<String>.from(json['relationshipIds'] ?? []),
      settings: SeriesSettings.fromJson(json['settings'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
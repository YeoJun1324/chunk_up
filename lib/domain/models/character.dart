// lib/domain/models/character.dart

class Character {
  final String id;
  final String name;
  final String seriesId;
  final String seriesName;
  final String description;
  final String personality;
  final List<String> catchPhrases;
  final List<String> abilities;
  final String backgroundInfo;
  final String imageUrl;
  final List<String> tags;

  Character({
    required this.id,
    required this.name,
    required this.seriesId,
    required this.seriesName,
    required this.description,
    this.personality = '',
    this.catchPhrases = const [],
    this.abilities = const [],
    this.backgroundInfo = '',
    this.imageUrl = '',
    this.tags = const [],
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as String,
      name: json['name'] as String,
      seriesId: json['seriesId'] as String,
      seriesName: json['seriesName'] as String,
      description: json['description'] as String,
      personality: json['personality'] as String? ?? '',
      catchPhrases: (json['catchPhrases'] as List<dynamic>?)?.cast<String>() ?? [],
      abilities: (json['abilities'] as List<dynamic>?)?.cast<String>() ?? [],
      backgroundInfo: json['backgroundInfo'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'seriesId': seriesId,
      'seriesName': seriesName,
      'description': description,
      'personality': personality,
      'catchPhrases': catchPhrases,
      'abilities': abilities,
      'backgroundInfo': backgroundInfo,
      'imageUrl': imageUrl,
      'tags': tags,
    };
  }
}

class CharacterRelationship {
  final String id;
  final String characterAId;
  final String characterBId;
  final RelationshipType type;
  final String description;
  final RelationshipStatus status;
  final List<String> keyEvents;

  CharacterRelationship({
    required this.id,
    required this.characterAId,
    required this.characterBId,
    required this.type,
    required this.description,
    this.status = RelationshipStatus.normal,
    this.keyEvents = const [],
  });

  factory CharacterRelationship.fromJson(Map<String, dynamic> json) {
    return CharacterRelationship(
      id: json['id'] as String,
      characterAId: json['characterAId'] as String,
      characterBId: json['characterBId'] as String,
      type: RelationshipType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RelationshipType.complex,
      ),
      description: json['description'] as String,
      status: RelationshipStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RelationshipStatus.normal,
      ),
      keyEvents: (json['keyEvents'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'characterAId': characterAId,
      'characterBId': characterBId,
      'type': type.name,
      'description': description,
      'status': status.name,
      'keyEvents': keyEvents,
    };
  }
}

enum RelationshipType {
  romantic,        // 연인/로맨스
  friendship,      // 친구
  rivalry,         // 라이벌
  familial,        // 가족
  mentor,          // 스승/제자
  enemy,           // 적대관계
  colleague,       // 동료
  master,          // 주종관계
  complex,         // 복잡한 관계
}

enum RelationshipStatus {
  harmonious,      // 화목한
  tense,           // 긴장된
  conflicted,      // 갈등 중
  estranged,       // 소원한
  developing,      // 발전 중
  broken,          // 깨진
  normal,          // 평범한
}

// Helper extensions
extension RelationshipTypeExtension on RelationshipType {
  String get displayName {
    switch (this) {
      case RelationshipType.romantic:
        return '연인/로맨스';
      case RelationshipType.friendship:
        return '친구';
      case RelationshipType.rivalry:
        return '라이벌';
      case RelationshipType.familial:
        return '가족';
      case RelationshipType.mentor:
        return '스승/제자';
      case RelationshipType.enemy:
        return '적대관계';
      case RelationshipType.colleague:
        return '동료';
      case RelationshipType.master:
        return '주종관계';
      case RelationshipType.complex:
        return '복잡한 관계';
    }
  }
  
  String get englishName {
    switch (this) {
      case RelationshipType.romantic:
        return 'Romantic partners';
      case RelationshipType.friendship:
        return 'Friends';
      case RelationshipType.rivalry:
        return 'Rivals';
      case RelationshipType.familial:
        return 'Family';
      case RelationshipType.mentor:
        return 'Mentor/Student';
      case RelationshipType.enemy:
        return 'Enemies';
      case RelationshipType.colleague:
        return 'Colleagues';
      case RelationshipType.master:
        return 'Master/Servant';
      case RelationshipType.complex:
        return 'Complex relationship';
    }
  }
}

extension RelationshipStatusExtension on RelationshipStatus {
  String get displayName {
    switch (this) {
      case RelationshipStatus.harmonious:
        return '화목한';
      case RelationshipStatus.tense:
        return '긴장된';
      case RelationshipStatus.conflicted:
        return '갈등 중';
      case RelationshipStatus.estranged:
        return '소원한';
      case RelationshipStatus.developing:
        return '발전 중';
      case RelationshipStatus.broken:
        return '깨진';
      case RelationshipStatus.normal:
        return '평범한';
    }
  }
  
  String get englishName {
    switch (this) {
      case RelationshipStatus.harmonious:
        return 'Harmonious';
      case RelationshipStatus.tense:
        return 'Tense';
      case RelationshipStatus.conflicted:
        return 'In conflict';
      case RelationshipStatus.estranged:
        return 'Estranged';
      case RelationshipStatus.developing:
        return 'Developing';
      case RelationshipStatus.broken:
        return 'Broken';
      case RelationshipStatus.normal:
        return 'Normal';
    }
  }
}
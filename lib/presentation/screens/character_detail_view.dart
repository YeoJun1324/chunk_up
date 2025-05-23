// lib/presentation/screens/character_detail_view.dart
import 'package:flutter/material.dart';
import 'package:chunk_up/domain/models/character.dart';
import 'package:chunk_up/core/services/enhanced_character_service.dart';

class CharacterDetailView extends StatelessWidget {
  final Character character;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CharacterDetailView({
    Key? key,
    required this.character,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                child: Text(
                  character.name[0],
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      character.seriesName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
                tooltip: '편집',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
                tooltip: '삭제',
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // 정보 카드들
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    context,
                    title: '설명',
                    content: character.description,
                    icon: Icons.description,
                  ),
                  const SizedBox(height: 16),
                  
                  if (character.personality.isNotEmpty)
                    _buildInfoCard(
                      context,
                      title: '성격',
                      content: character.personality,
                      icon: Icons.psychology,
                    ),
                  if (character.personality.isNotEmpty)
                    const SizedBox(height: 16),
                  
                  if (character.catchPhrases.isNotEmpty)
                    _buildListCard(
                      context,
                      title: '대표 대사',
                      items: character.catchPhrases,
                      icon: Icons.format_quote,
                    ),
                  if (character.catchPhrases.isNotEmpty)
                    const SizedBox(height: 16),
                  
                  if (character.tags.isNotEmpty)
                    _buildTagsCard(
                      context,
                      title: '태그',
                      tags: character.tags,
                      icon: Icons.label,
                    ),
                  
                  // 관계 정보
                  FutureBuilder<List<CharacterRelationship>>(
                    future: EnhancedCharacterService().getCharacterRelationships(character.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      return Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildRelationshipsCard(context, snapshot.data!),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(
    BuildContext context, {
    required String title,
    required List<String> items,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(item)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsCard(
    BuildContext context, {
    required String title,
    required List<String> tags,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) => Chip(
                label: Text(tag, style: const TextStyle(fontSize: 12)),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationshipsCard(
    BuildContext context,
    List<CharacterRelationship> relationships,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '관계',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...relationships.map((rel) => FutureBuilder<List<Character>>(
              future: EnhancedCharacterService().getCharactersByNames([
                if (rel.characterAId != character.id) rel.characterAId,
                if (rel.characterBId != character.id) rel.characterBId,
              ]),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                final otherCharacter = snapshot.data!.first;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            child: Text(otherCharacter.name[0]),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  otherCharacter.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${_getRelationshipTypeName(rel.type)} (${_getRelationshipStatusName(rel.status)})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (rel.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 40),
                          child: Text(
                            rel.description,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                );
              },
            )),
          ],
        ),
      ),
    );
  }

  String _getRelationshipTypeName(RelationshipType type) {
    switch (type) {
      case RelationshipType.romantic: return '연인';
      case RelationshipType.friendship: return '친구';
      case RelationshipType.rivalry: return '라이벌';
      case RelationshipType.familial: return '가족';
      case RelationshipType.mentor: return '스승/제자';
      case RelationshipType.enemy: return '적대';
      case RelationshipType.colleague: return '동료';
      case RelationshipType.master: return '주종';
      case RelationshipType.complex: return '복잡한 관계';
    }
  }

  String _getRelationshipStatusName(RelationshipStatus status) {
    switch (status) {
      case RelationshipStatus.harmonious: return '화목함';
      case RelationshipStatus.tense: return '긴장됨';
      case RelationshipStatus.conflicted: return '갈등중';
      case RelationshipStatus.estranged: return '소원함';
      case RelationshipStatus.developing: return '발전중';
      case RelationshipStatus.broken: return '깨짐';
      case RelationshipStatus.normal: return '평범함';
    }
  }
}
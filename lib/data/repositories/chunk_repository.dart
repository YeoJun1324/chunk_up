// lib/data/repositories/chunk_repository.dart
import 'package:chunk_up/core/utils/business_exception.dart';
import 'package:chunk_up/data/repositories/base_repository.dart';
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/domain/repositories/chunk_repository_interface.dart';
import 'package:chunk_up/domain/repositories/word_list_repository_interface.dart';
import 'package:chunk_up/domain/services/api_service_interface.dart';

class ChunkRepositoryImpl extends BaseRepository<Chunk> implements ChunkRepositoryInterface {
  static const String _storageKey = 'chunks';
  final WordListRepositoryInterface _wordListRepository;
  final ApiServiceInterface _apiService;

  ChunkRepositoryImpl(
    this._wordListRepository,
    this._apiService,
  );

  @override
  String get storageKey => _storageKey;

  @override
  Chunk fromJson(Map<String, dynamic> json) => Chunk.fromJson(json);

  @override
  Map<String, dynamic> toJson(Chunk entity) => entity.toJson();

  @override
  Future<Map<String, dynamic>> generateChunk(String prompt) async {
    return await _apiService.generateChunk(prompt);
  }

  @override
  Future<List<Chunk>> generateChunks(String wordListId, {String? modelOverride}) async {
    final wordList = await _wordListRepository.getWordListById(wordListId);
    if (wordList == null) {
      throw BusinessException(
        type: BusinessErrorType.wordNotFound,
        message: 'No word list with the ID $wordListId was found',
      );
    }

    // Get existing chunks
    final existingChunks = await getChunksForWordList(wordListId);

    // Generate chunks based on the words using the API service
    final responses = await _apiService.generateChunksForWords(
      wordList.words,
      modelOverride: modelOverride,
    );

    // Create new chunks from the responses
    final newChunks = responses.asMap().entries.map((entry) {
      final index = entry.key;
      final response = entry.value;
      final content = response['content'] ?? 'Generated content';

      return Chunk(
        id: 'chunk_${wordListId}_${existingChunks.length + index + 1}',
        title: 'Generated Chunk ${existingChunks.length + index + 1}',
        englishContent: content,
        koreanTranslation: '', // Translation would be done separately
        includedWords: wordList.words,
        wordExplanations: {},
      );
    }).toList();

    // Save all new chunks
    for (final chunk in newChunks) {
      await saveChunk(chunk);
    }

    // Update the word list with the new chunk count
    final allChunks = [...existingChunks, ...newChunks];
    final updatedWordList = WordListInfo(
      name: wordList.name,
      words: wordList.words,
      chunks: allChunks,
      chunkCount: allChunks.length,
    );
    await _wordListRepository.updateWordList(updatedWordList);

    return newChunks;
  }

  @override
  Future<List<Chunk>> getChunksForWordList(String wordListId) async {
    final allChunks = await getAll();
    return allChunks.where((chunk) => chunk.id.contains(wordListId)).toList();
  }

  @override
  Future<Chunk?> getChunkById(String id) async {
    try {
      return await findBy((chunk) => chunk.id == id);
    } catch (e) {
      throw BusinessException(
        type: BusinessErrorType.wordNotFound,
        message: 'No chunk with the ID $id was found',
      );
    }
  }

  @override
  Future<Chunk> saveChunk(Chunk chunk) async {
    final chunks = await getAll();
    final index = chunks.indexWhere((c) => c.id == chunk.id);

    if (index != -1) {
      // Update existing chunk
      return await update(chunk, (c) => c.id == chunk.id);
    } else {
      // Create new chunk
      return await create(chunk);
    }
  }

  @override
  Future<bool> deleteChunk(String id) async {
    return await delete((chunk) => chunk.id == id);
  }
}
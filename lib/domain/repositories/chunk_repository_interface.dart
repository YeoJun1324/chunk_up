// lib/domain/repositories/chunk_repository_interface.dart
import 'package:chunk_up/domain/models/chunk.dart';

/// Interface for the chunk repository
abstract class ChunkRepositoryInterface {
  /// Generate chunks for a word list
  /// [modelOverride] Optional parameter to specify which AI model to use
  Future<List<Chunk>> generateChunks(String wordListId, {String? modelOverride});

  /// Generate a single chunk with a prompt
  Future<Map<String, dynamic>> generateChunk(String prompt);

  /// Get all chunks for a word list
  Future<List<Chunk>> getChunksForWordList(String wordListId);

  /// Get chunk by id
  Future<Chunk?> getChunkById(String id);

  /// Save a chunk
  Future<Chunk> saveChunk(Chunk chunk);

  /// Delete a chunk
  Future<bool> deleteChunk(String id);
}
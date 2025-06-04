// This file contains functions to examine directory paths

import 'dart:io';
import 'package:path/path.dart' as path;

/// PathService provides utilities for working with file system paths
/// in both local and remote contexts.
class PathService {
  /// Creates a new PathService instance
  PathService();
  
  /// Returns a list of all files and directories in the specified directory path.
  /// 
  /// If the directory doesn't exist, returns an empty list.
  /// Throws an exception if there are permission issues or other IO errors.
  Future<List<FileSystemEntity>> listDirectoryContents(String directoryPath) async {
    final directory = Directory(directoryPath);
    
    if (await directory.exists()) {
      try {
        return directory.list().toList();
      } catch (e) {
        throw Exception('Error listing directory contents: $e');
      }
    } else {
      return [];
    }
  }
  
  /// Recursively lists all directories and files under the specified path.
  /// 
  /// Returns two lists: one with all directory paths and one with all file paths.
  /// The input directory is included in the directories list.
  /// If the directory doesn't exist, returns empty lists.
  Future<({List<String> directories, List<String> files})> listDirRecursive(String directoryPath) async {
    final List<String> directories = [];
    final List<String> files = [];
    final directory = Directory(directoryPath);
    
    if (!await directory.exists()) {
      return (directories: <String>[], files: <String>[]);
    }
    
    // Add the input directory to the list
    directories.add(directoryPath);
    
    try {
      await _processDirectory(directory, directories, files);
      return (directories: directories, files: files);
    } catch (e) {
      throw Exception('Error during recursive directory listing: $e');
    }
  }
  
  /// Helper method for recursive directory listing
  Future<void> _processDirectory(
    Directory directory, 
    List<String> directories, 
    List<String> files
  ) async {
    try {
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is Directory) {
          directories.add(entity.path);
          await _processDirectory(entity, directories, files);
        } else if (entity is File) {
          files.add(entity.path);
        }
      }
    } catch (e) {
      // Log the error but continue processing other directories
      print('Error processing directory ${directory.path}: $e');
    }
  }
}

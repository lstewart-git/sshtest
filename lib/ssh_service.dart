import 'package:dartssh2/dartssh2.dart';
import 'dart:convert';
import 'dart:io'; // Add this import for File operations
import 'dart:typed_data'; // Add this import for Uint8List
import 'package:path/path.dart' as path; // Add this import for path operations

// SSHService class to handle SSH operations
class SSHService {

  /// Attempts to connect to the SSH server and run 'uptime'.
  /// Returns the command output as a String, or throws on error.
  Future<String> testConnection({
    required String host,
    required String username,
    required String password,
    int port = 22,
  }) async {
    late SSHClient client;
    try {
      client = SSHClient(
        await SSHSocket.connect(host, port),
        username: username,
        onPasswordRequest: () => password,
      );
      
      final session = await client.execute('uptime');
      
      // Collect all bytes and then decode
      final bytes = <int>[];
      await for (final data in session.stdout) {
        bytes.addAll(data);
      }
      final result = utf8.decode(bytes);
      
      // Don't use await if these methods return void
      session.close();
      client.close();
      
      return result.trim();
    } catch (e) {
      // Clean up if needed
      try {
        client.close();
      } catch (_) {}
      rethrow;
    }
  }

  /// Uploads a file to the remote server using SFTP.
  /// Returns 'Success' or an error message.
  Future<String> uploadFile({
    required String host,
    required String username, 
    required String password,
    required String sourcePath,
    required String destinationPath,
    int port = 22,
  }) async {
    late SSHClient client;
    try {
      // Connect to the SSH server
      client = SSHClient(
        await SSHSocket.connect(host, port),
        username: username,
        onPasswordRequest: () => password,
      );
      
      // Initialize SFTP subsystem
      final sftp = await client.sftp();
      
      // Open the local file for reading
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return 'Error: Source file not found';
      }
      
      // Create/open the remote file for writing
      final remoteFile = await sftp.open(
        destinationPath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write,
      );
      
      // Stream the file contents (works with files of any size)
      final sourceStream = sourceFile.openRead();
      await for (final chunk in sourceStream) {
        // Convert List<int> to Uint8List before writing
        await remoteFile.writeBytes(Uint8List.fromList(chunk));
      }
      
      // Close the remote file
      await remoteFile.close();
      
      // Clean up
      client.close();
      
      return 'Success';
    } catch (e) {
      // Clean up on error
      try {
        client.close();
      } catch (_) {}
      return 'Error: ${e.toString()}';
    }
  }

  /// Downloads a file from the remote server using SFTP.
  /// Returns 'Success' or an error message.
  Future<String> downloadFile({
    required String host,
    required String username, 
    required String password,
    required String remotePath,
    required String localPath,
    int port = 22,
  }) async {
    late SSHClient client;
    try {
      // Connect to the SSH server
      client = SSHClient(
        await SSHSocket.connect(host, port),
        username: username,
        onPasswordRequest: () => password,
      );
      
      // Initialize SFTP subsystem
      final sftp = await client.sftp();
      
      // Check if remote file exists by trying to open it
      final remoteFile = await sftp.open(
        remotePath,
        mode: SftpFileOpenMode.read,
      );
      
      // Ensure the local directory exists
      final localDir = path.dirname(localPath);
      final directory = Directory(localDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Create/open the local file for writing
      final localFile = File(localPath);
      final localSink = localFile.openWrite();
      
      // Read the remote file content as bytes and write to the local file
      final bytes = await remoteFile.readBytes();
      localSink.add(bytes);
      
      // Close the local file
      await localSink.close();
      
      // Close the remote file
      await remoteFile.close();
      
      // Clean up
      client.close();
      
      return 'Success';
    } catch (e) {
      // Clean up on error
      try {
        client.close();
      } catch (_) {}
      return 'Error: ${e.toString()}';
    }
  }
}
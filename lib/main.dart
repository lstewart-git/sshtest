// This project is an experiment to develop
// useful ssh and sftp routines using the dartssh2 library

import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'ssh_service.dart'; // Add this import
import 'path_service.dart'; // Add this import

void main() {
  runApp(const MyApp());
}

 // This widget is the root of your application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});
   @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

// HOMEPAGE WIDGET
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  // This widget is the home page of your application. It is stateful, meaning
  // This class is the configuration for the state. It holds the values (in this
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// HOME PAGE STATE. It is where you can
// define the variables and methods that will be used in the home page.
class _MyHomePageState extends State<MyHomePage> {
  final SSHService _sshService = SSHService();
  final PathService _pathService = PathService();
  String _connectionResult = '';
  bool _isConnecting = false;

  // Add variables for SSH credentials
  String _sshUsername = 'lstewart';
  String _sshServer = 'serv';
  String _sshPassword = 'Boost2mars!';
  
  // Add variables for file paths
  String _localFilePath = '';
  String _remoteFilePath = '';
  String _directoryPath = '';

  // Add list to store output messages
  final List<String> _outputMessages = [];
  
  // Method to add a message to the output list
  void _addOutputMessage(String message) {
    setState(() {
      _outputMessages.add("${DateTime.now().toString().split('.').first}: $message");
      // Keep the list at a reasonable size
      if (_outputMessages.length > 100) {
        _outputMessages.removeAt(0);
      }
    });
  }

  // our button press function which calls our SSHService to test the connection
  Future<void> _testSshConnection() async {
    // Don't allow multiple simultaneous connection attempts
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
      _connectionResult = 'Connecting...';
    });

    try {
      final result = await _sshService.testConnection(
        host: _sshServer,
        username: _sshUsername,
        password: _sshPassword,
      );

      setState(() {
        _connectionResult = 'Success: $result';
      });
      _addOutputMessage('Connection successful: $result');
    } catch (e) {
      setState(() {
        _connectionResult = 'Error: ${e.toString()}';
      });
      _addOutputMessage('Connection error: ${e.toString()}');
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  // Add a new method to handle file upload
  Future<void> _uploadFile() async {
    // Don't allow upload during connection attempt
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
      _connectionResult = 'Uploading file...';
    });

    try {
      final result = await _sshService.uploadFile(
        host: _sshServer,
        username: _sshUsername,
        password: _sshPassword,
        sourcePath: _localFilePath,
        destinationPath: _remoteFilePath,
      );

      setState(() {
        _connectionResult = result;
      });
      _addOutputMessage('File uploaded: $result');
    } catch (e) {
      setState(() {
        _connectionResult = 'Error: ${e.toString()}';
      });
      _addOutputMessage('Upload error: ${e.toString()}');
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  // Add a new method to handle file download
  Future<void> _downloadFile() async {
    // Don't allow download during connection attempt
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
      _connectionResult = 'Downloading file...';
    });

    try {
      final result = await _sshService.downloadFile(
        host: _sshServer,
        username: _sshUsername,
        password: _sshPassword,
        remotePath: _remoteFilePath,
        localPath: _localFilePath,
      );

      setState(() {
        _connectionResult = result;
      });
      _addOutputMessage('File downloaded: $result');
    } catch (e) {
      setState(() {
        _connectionResult = 'Error: ${e.toString()}';
      });
      _addOutputMessage('Download error: ${e.toString()}');
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  // Add a new method to list directory contents
  Future<void> _listDirectory() async {
    if (_isConnecting) return;
    
    if (_directoryPath.isEmpty) {
      _addOutputMessage('Error: Please enter a directory path');
      return;
    }

    setState(() {
      _isConnecting = true;
      _connectionResult = 'Listing directory...';
    });

    try {
      final contents = await _pathService.listDirectoryContents(_directoryPath);
      _addOutputMessage('Directory contents (${contents.length} items):');
      for (var item in contents) {
        _addOutputMessage('- ${item.path}');
      }
      setState(() {
        _connectionResult = 'Listed ${contents.length} items in directory';
      });
    } catch (e) {
      _addOutputMessage('Error listing directory: ${e.toString()}');
      setState(() {
        _connectionResult = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  // Add a new method to list directory contents recursively
  Future<void> _listDirectoryRecursive() async {
    if (_isConnecting) return;
    
    if (_directoryPath.isEmpty) {
      _addOutputMessage('Error: Please enter a directory path');
      return;
    }

    setState(() {
      _isConnecting = true;
      _connectionResult = 'Listing directory recursively...';
    });

    try {
      final result = await _pathService.listDirRecursive(_directoryPath);
      
      _addOutputMessage('=== RECURSIVE DIRECTORY LISTING ===');
      _addOutputMessage('Directories found: ${result.directories.length}');
      _addOutputMessage('Files found: ${result.files.length}');
      _addOutputMessage('');
      
      _addOutputMessage('--- DIRECTORIES ---');
      for (var dir in result.directories) {
        _addOutputMessage('DIR: $dir');
      }
      
      _addOutputMessage('');
      _addOutputMessage('--- FILES ---');
      for (var file in result.files) {
        _addOutputMessage('FILE: $file');
      }
      
      setState(() {
        _connectionResult = 'Found ${result.directories.length} directories and ${result.files.length} files';
      });
    } catch (e) {
      _addOutputMessage('Error during recursive listing: ${e.toString()}');
      setState(() {
        _connectionResult = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  // LAYOUT OF THE HOME PAGE
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // Existing form in a scrollable container
          Expanded(
            flex: 2, // Take 2/3 of the available space
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // SSH Username
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'SSH Username',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _sshUsername = value;
                        });
                      },
                    ),
                  ),
                  // SSH Server
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'SSH Server',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _sshServer = value;
                        });
                      },
                    ),
                  ),
                  // SSH Password
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'SSH Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      onChanged: (value) {
                        setState(() {
                          _sshPassword = value;
                        });
                      },
                    ),
                  ),
                  // Local File Path
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Local File Path',
                        border: OutlineInputBorder(),
                        hintText: '/path/to/local/file',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _localFilePath = value;
                        });
                      },
                    ),
                  ),
                  
                  // Remote File Path
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Remote File Path',
                        border: OutlineInputBorder(),
                        hintText: '/path/to/remote/file',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _remoteFilePath = value;
                        });
                      },
                    ),
                  ),
                  
                  // Directory Path
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Directory Path',
                        border: OutlineInputBorder(),
                        hintText: '/path/to/directory',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _directoryPath = value;
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  // Display connection result
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _connectionResult,
                      style: TextStyle(
                        color: _connectionResult.startsWith('Error')
                            ? Colors.red
                            : Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // Add a row of buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Column(
                      children: [
                        // First row of buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isConnecting ? null : _testSshConnection,
                              icon: const Icon(Icons.link),
                              label: const Text('Test Connection'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isConnecting ? null : _uploadFile,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Upload'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isConnecting ? null : _downloadFile,
                              icon: const Icon(Icons.download),
                              label: const Text('Download'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Second row of buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isConnecting ? null : _listDirectory,
                              icon: const Icon(Icons.list),
                              label: const Text('List Directory'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isConnecting ? null : _listDirectoryRecursive,
                              icon: const Icon(Icons.account_tree),
                              label: const Text('List Recursive'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Divider between the form and output log
          const Divider(thickness: 2, height: 10),
          
          // Output ListView
          Expanded(
            flex: 1, // Take 1/3 of the available space
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Text(
                    'Output Log',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListView.builder(
                      reverse: true, // Show newest messages at the bottom
                      itemCount: _outputMessages.length,
                      itemBuilder: (context, index) {
                        // Display messages in reverse order (newest at the bottom)
                        final message = _outputMessages[_outputMessages.length - 1 - index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            message,
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

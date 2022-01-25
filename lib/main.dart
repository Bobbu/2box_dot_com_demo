import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:flutter_web_auth/flutter_web_auth.dart';
// import 'package:flutter/services.dart';
// import 'dart:convert' show jsonDecode;
// import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import './services/box_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Box.com Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Box.com Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _connectionState = 'Not authed yet at Box.com';
  bool _isAuthed = false;
  String _someTellTaleInfo = 'I have no idea what folders and files exist';

  BoxService boxService = BoxService();

  final _folderNameController = TextEditingController();

  void _authenticate() async {
    String accessToken = await boxService.init();

    debugPrint(accessToken);

    if (accessToken != '') {
      BoxUser bu = await boxService.getUser();

      setState(() {
        _connectionState = 'Connected (${bu.name})';
        _isAuthed = true;
      });
    } else {
      setState(() {
        _connectionState = 'Failed to connect (real)';
        _isAuthed = false;
      });
    }
  }

  void _getSomeTelltaleInfo() async {
    List<BoxFolderItem> rootItems = await boxService.fetchFolderItems('0');
    if (rootItems.isNotEmpty) {
      setState(() {
        final name = rootItems[0].name;
        final type = rootItems[0].type;
        _someTellTaleInfo = 'There is a $type named $name';
      });
    } else {
      setState(() {
        _someTellTaleInfo = 'Nothing found in the root folder. Get on it.';
      });
    }
  }

  void _createRandomlyNamedFolder() async {
    final DateFormat formatter = DateFormat('yyyy-MM-dd hh-mm-ss');
    final String randomEnoughName = 'rando' + formatter.format(DateTime.now());
    debugPrint(randomEnoughName);
    try {
      BoxFolderItem newFolder =
          await boxService.createFolder('0', randomEnoughName);
      final message =
          'Created folder named ${newFolder.name} with Id ${newFolder.id}';
      debugPrint(message);
      setState(() {
        _someTellTaleInfo = message;
      });
    } on Exception catch (e) {
      final errorMessage =
          'Yikes. Could not create folder named $randomEnoughName';
      debugPrint(errorMessage);
      debugPrint(e.toString());
      setState(() {
        _someTellTaleInfo = errorMessage;
      });
    }
  }

  void _createNewFolder() async {
    final String newFolderName = _folderNameController.text;
    const String rootFolderId = '0';

    bool itemAlreadyExists =
        await boxService.itemExists(newFolderName, rootFolderId);
    if (itemAlreadyExists) {
      setState(() {
        _someTellTaleInfo = '$newFolderName already exists in root folder!!!';
      });
      return;
    }

    try {
      BoxFolderItem newFolder =
          await boxService.createFolder(rootFolderId, newFolderName);
      final message =
          'Created folder named ${newFolder.name} with Id ${newFolder.id}';
      debugPrint(message);
      setState(() {
        _someTellTaleInfo = message;
      });
    } on Exception catch (e) {
      final errorMessage =
          'Yikes. Could not create folder named $newFolderName';
      debugPrint(errorMessage);
      debugPrint(e.toString());
      setState(() {
        _someTellTaleInfo = errorMessage;
      });
    }
  }

  void _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;
      debugPrint('Selected filename is ${file.name}');
      debugPrint('Selected path is ${file.path}');
      setState(() {
        _someTellTaleInfo = 'Going to upload ${file.name} at path ${file.path}';
      });
      try {
        BoxFolderItem uploadedFile =
            await boxService.uploadFile(file.path!, file.name, '0');
        setState(() {
          _someTellTaleInfo =
              'Uploaded file ${uploadedFile.name} in the root folder';
        });
      } on Exception catch (e) {
        final errorMessage =
            'Yikes. Could not upload file ${file.path} to root folder';
        debugPrint(errorMessage);
        debugPrint(e.toString());
        setState(() {
          _someTellTaleInfo = errorMessage;
        });
      }
    } else {
      setState(() {
        _someTellTaleInfo = 'User cancelled file selection';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),
            Text(
              _connectionState,
              style: Theme.of(context).textTheme.headline5,
            ),
            const SizedBox(height: 20),
            Text(
              _someTellTaleInfo,
            ),
            const SizedBox(height: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: _authenticate,
                    child: const Text('Try to auth at Box.com')),
                const SizedBox(width: 10),
                ElevatedButton(
                    onPressed: _isAuthed ? _getSomeTelltaleInfo : null,
                    child: const Text('Grab some telltale info')),
                const SizedBox(width: 10),
                ElevatedButton(
                    onPressed: _isAuthed ? _createRandomlyNamedFolder : null,
                    child: const Text('Create randomly-named folder')),
                const SizedBox(width: 20),
                TextField(
                  decoration:
                      const InputDecoration(labelText: 'New Folder Name'),
                  controller: _folderNameController,
                ),
                ElevatedButton(
                    onPressed: _isAuthed ? _createNewFolder : null,
                    child: const Text('Create new folder')),
                const SizedBox(width: 10),
                ElevatedButton(
                    onPressed: _isAuthed ? _uploadFile : null,
                    child: const Text('Upload a file')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

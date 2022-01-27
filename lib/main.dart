// import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:flutter_web_auth/flutter_web_auth.dart';
// import 'package:flutter/services.dart';
// import 'dart:convert' show jsonDecode;
// import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import './services/box_service.dart';
import './utilities/random_in_range.dart';

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
        primarySwatch: Colors.deepOrange,
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
  String _someTellTaleInfo = 'I have no idea what folders and files exist';

  BoxService boxService = BoxService();

  final _folderNameController = TextEditingController();
  bool _enableCreateNewFolderButton = false;

  void _toggleCreateNewFolderButton() {
    // Only change state if we are going from having some text to no text or
    // vice versa. Ignore all cses where we are just changing text (already
    // enabled and text continues to not be empty).
    if (_enableCreateNewFolderButton && _folderNameController.text.isEmpty) {
      setState(() {
        _enableCreateNewFolderButton = false;
      });
    } else if (!_enableCreateNewFolderButton &&
        _folderNameController.text.isNotEmpty) {
      setState(() {
        _enableCreateNewFolderButton = true;
      });
    }
  }

  void _clearFolderNameText() {
    setState(() {
      _folderNameController.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    // Not waiting for it...
    boxService.getUser().then((resultingUser) {
      setState(() {
        _connectionState = 'Logged in at Box as ${resultingUser.name}';
      });
    });

    _folderNameController.addListener(_toggleCreateNewFolderButton);
  }

  void _authenticate() async {
    String accessToken = await boxService.authInit();

    debugPrint(accessToken);

    if (accessToken != '') {
      BoxUser bu = await boxService.getUser();

      setState(() {
        _connectionState = 'Connected (${bu.name})';
      });
    } else {
      setState(() {
        _connectionState = 'Failed to connect (real)';
      });
    }
  }

  void _getSomeTelltaleInfo() async {
    List<BoxFolderItem> rootItems = await boxService.fetchFolderItems('0');
    if (rootItems.isNotEmpty) {
      setState(() {
        int index = Randomizer.nextIntInRange(0, rootItems.length - 1);
        debugPrint(
            'There are ${rootItems.length} items in root folder and we randomly will show $index');
        final name = rootItems[index].name;
        final type = rootItems[index].type;
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
    ButtonStyle consistentSizeButtonStyle = ElevatedButton.styleFrom(
        minimumSize: const Size(250, 40), maximumSize: const Size(250, 40));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    Text(
                      _connectionState,
                      style: Theme.of(context).textTheme.headline5,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _someTellTaleInfo,
                      style: Theme.of(context).textTheme.headline6,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        style: consistentSizeButtonStyle,
                        onPressed: _authenticate,
                        child: const Text('Try to auth at Box.com')),
                    const SizedBox(width: 10),
                    ElevatedButton(
                        style: consistentSizeButtonStyle,
                        onPressed: _getSomeTelltaleInfo,
                        child: const Text('Grab some telltale info')),
                    const SizedBox(width: 10),
                    ElevatedButton(
                        style: consistentSizeButtonStyle,
                        onPressed: _createRandomlyNamedFolder,
                        child: const Text('Create randomly-named folder')),
                    const SizedBox(width: 20),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'New Folder Name',
                        suffixIcon: IconButton(
                          // Icon to
                          icon: const Icon(Icons.clear), // clear text
                          onPressed: _clearFolderNameText,
                        ),
                      ),
                      controller: _folderNameController,
                    ),
                    ElevatedButton(
                        style: consistentSizeButtonStyle,
                        onPressed: (_enableCreateNewFolderButton)
                            ? _createNewFolder
                            : null,
                        child: const Text('Create new folder')),
                    const SizedBox(width: 10),
                    ElevatedButton(
                        style: consistentSizeButtonStyle,
                        onPressed: _uploadFile,
                        child: const Text('Upload a file')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

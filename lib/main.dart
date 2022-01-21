import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:flutter/services.dart';

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

  void _authenticate() async {
    const authorizationEndpoint =
        'https://account.box.com/api/oauth2/authorize';
    const clientId = 'dbneallex3uliy7zo7xtkvj380v935ux';

    const callbackUrlScheme =
        'technology.catalyst.hrp'; // this also goes in some manifest stuff
    const redirectUri = '$callbackUrlScheme:/';
    const completeAuthUriString =
        '$authorizationEndpoint&response_type=code&client_id=$clientId&redirect_uri=$redirectUri';

    print('sending this to box.com: $completeAuthUriString');

    // Present the dialog to the user

    try {
      final result = await FlutterWebAuth.authenticate(
        url: completeAuthUriString,
        callbackUrlScheme: callbackUrlScheme,
      );

      // Extract token from resulting url
      final token = Uri.parse(result).queryParameters['token'];
      print('token is $token');
      print('TODO: Save token to secure local storage');
      setState(() {
        _connectionState = 'Connected (real)';
        _isAuthed = true;
      });
    } on PlatformException catch (pe) {
      print('Did not get desired auth. exceptiopn message is: ${pe.message}');
      setState(() {
        _connectionState = 'Failed to connect (real)';
        _isAuthed = false;
      });
    }
  }

  void _authAtBox() {
    setState(() {
      _connectionState = 'Connected (faked)';
      _isAuthed = true;
    });
  }

  void _getSomeTelltaleInfo() {
    setState(() {
      _someTellTaleInfo = 'Got a folder named \'Dirt on B & D\' (faked)';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _connectionState,
              style: Theme.of(context).textTheme.headline5,
            ),
            const SizedBox(height: 20),
            Text(
              _someTellTaleInfo,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: _authenticate,
                    child: const Text('Try to auth at Box.com')),
                const SizedBox(width: 10),
                ElevatedButton(
                    onPressed: _isAuthed ? _getSomeTelltaleInfo : null,
                    child: const Text('Grab some telltale info'))
              ],
            ),
          ],
        ),
      ),
    );
  }
}

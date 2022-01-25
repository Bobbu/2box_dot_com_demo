import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert' show jsonDecode, jsonEncode;
import 'package:http/http.dart' as http;

/////////////////////////////////////////////////////////////////////////

class BoxUser {
  final String id;
  final String name;
  final String login; // i.e., username
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String jobTitle;
  final String phone;
  final String address;
  final String avatarUrl;

  BoxUser(
      {required this.id,
      required this.name,
      required this.login,
      required this.createdAt,
      required this.modifiedAt,
      required this.jobTitle,
      required this.phone,
      required this.address,
      required this.avatarUrl});

  static _safelyParsedDateTime(final String dateTimeAsString) {
    // TODO: Until we run against some of the external systems we won't know what
    // their actual formatted date strings look like. for now let's be safe
    // and assume parsing may fail.
    DateTime result = DateTime.now();
    try {
      result = DateTime.parse(dateTimeAsString);
    } catch (formatException) {
      debugPrint(
          'Seem to have a date format ($dateTimeAsString) for which we need to tweak our parsing.');
      debugPrint(formatException.toString());
    }
    return result;
  }

  factory BoxUser.fromJson(Map<String, dynamic> json) {
    // Left these expanded for debugging ease
    var id = json['id'] as String;
    var name = json['name'] as String;
    var login = json['login'] as String;
    var createdAtAsString = json['created_at'] as String;
    var createdAt = _safelyParsedDateTime(createdAtAsString);
    var modifiedAtAsString = json['modified_at'] as String;
    var modifiedAt = _safelyParsedDateTime(modifiedAtAsString);
    var jobTitle = json['job_title'] as String;
    var phone = json['phone'] as String;
    var address = json['address'] as String;
    var avatarUrl = json['avatar_url'] as String;

    return BoxUser(
        id: id,
        name: name,
        login: login,
        createdAt: createdAt,
        modifiedAt: modifiedAt,
        jobTitle: jobTitle,
        phone: phone,
        address: address,
        avatarUrl: avatarUrl);
  }

  Map toJson() => {
        'id': id,
        'name': name,
        'login': login,
        'created_at': createdAt.toIso8601String(),
        'modified_at': modifiedAt.toIso8601String(),
        'job_title': jobTitle,
        'phone': phone,
        'address': address,
        'avatar_url': avatarUrl
      };
}

/////////////////////////////////////////////////////////////////////////

class BoxFolderItem {
  BoxFolderItem({
    required this.type,
    required this.id,
    required this.sequenceId,
    required this.etag,
    required this.name,
  });

  final String type;
  final String id;
  final String sequenceId;
  final String etag;
  final String name;

  factory BoxFolderItem.fromJson(Map<String, dynamic> json) => BoxFolderItem(
        type: json["type"],
        id: json["id"],
        sequenceId: json["sequence_id"],
        etag: json["etag"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "id": id,
        "sequence_id": sequenceId,
        "etag": etag,
        "name": name,
      };
}

//////////////////////////////////////////////////////////////////////////////
class BoxService {
  // Some constants
  //

  // Client App IDs (Should likely hide)
  static const clientId = 'dbneallex3uliy7zo7xtkvj380v935ux';
  static const clientSecret = 'NgwLcqY66W2TyrUHFjVl2J9ylm2N9WV0';

  // Oauth2
  static const oauth2Root = 'https://account.box.com/api/oauth2';
  static const authorizationEndpoint = '$oauth2Root/authorize';
  static const tokenEndpoint = '$oauth2Root/token';
  // this also goes in <approot>/android/app/src/AndroidManifest.xml
  static const callbackUrlScheme = 'hrp01';
  // The redirect URI must match what is defined at developer.box.com:
  //
  // Loomk for something like: redirectUri => hrp01://redirect
  //
  static const redirectUri = '$callbackUrlScheme://redirect';
  static const completeAuthUriString =
      '$authorizationEndpoint?response_type=code&client_id=$clientId&redirect_uri=$redirectUri';

  // Finally, for Box API
  static const boxApiRoot = 'https://api.box.com/2.0';

  // We'll manage these for clients. If they are blank we can assume an auth
  // must occur.
  String _accessToken = '';
  String _refreshToken = '';

  // Will first try to retrieve a refreshToken from secure local storage, but if
  // none or if expired, will attempt an authenticate. It will manage preserving
  // any updated tokens, but will also return it in the Future in case clilents
  // want to drop down a level and make their own calls to the API.
  Future<String> init() async {
    debugPrint('callbackUrlScheme is $callbackUrlScheme');
    debugPrint('redirectUri is $redirectUri');
    debugPrint('sending this to box.com: $completeAuthUriString');

    // Present the dialog to the user

    try {
      final result = await FlutterWebAuth.authenticate(
        url: completeAuthUriString,
        callbackUrlScheme: callbackUrlScheme,
      );

      // Extract code from resulting url
      debugPrint('result of authenticate was ${result.toString()}');
      final authCode = Uri.parse(result).queryParameters['code'];
      debugPrint('authCode is $authCode');

      // Use this code to get an access token
      final response = await http.post(Uri.parse(tokenEndpoint), headers: {
        'Content-type': 'application/x-www-form-urlencoded'
      }, body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': authCode,
        'grant_type': 'authorization_code',
      });

      dynamic responseBody = jsonDecode(response.body);
      debugPrint('response body is ${responseBody.toString()}');

      // Get the access token from the response
      final accessToken = responseBody['access_token'] as String;
      final expiresIn = responseBody['expires_in'] as int;
      final refreshToken = responseBody['refresh_token'] as String;
      final tokenType = responseBody['token_type'] as String;
      debugPrint('Access token is $accessToken');
      debugPrint('expires in $expiresIn');
      debugPrint('refresh token is $refreshToken');
      debugPrint('token type is $tokenType');

      debugPrint(
          'TODO: Save token to secure local storage and start (Finally) doing real stuff.');

      _accessToken = accessToken;
      _refreshToken = refreshToken;

      return _accessToken;
    } on PlatformException catch (pe) {
      debugPrint(
          'Did not get desired auth. exception message is: ${pe.message}');
      _accessToken = '';
      _refreshToken = '';
    }

    return _accessToken;
  }

  //////////////////////////////////////////////////////////////////////////////
  Future<BoxUser> getUser() async {
    const usersMe = '$boxApiRoot/users/me';

    // TODO Check that _accessToken is current first
    debugPrint('Need to check _accessToken is fresh first');

    http.Response res = await http.get(
      Uri.parse(usersMe),
      headers: {'authorization': 'Bearer $_accessToken'},
    );
    if (res.statusCode == 200) {
      BoxUser result = BoxUser.fromJson(jsonDecode(res.body));
      debugPrint('BoxUser\'s name is ${result.name}');
      return result;
    } else {
      throw 'Unable to retrieve Box user.';
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  Future<List<BoxFolderItem>> fetchFolderItems(String inFolderWithId) async {
    final folderItems = '$boxApiRoot/folders/$inFolderWithId/items';

    // TODO Check that _accessToken is current first
    debugPrint('Need to check _accessToken is fresh first');

    http.Response res = await http.get(
      Uri.parse(folderItems),
      headers: {'authorization': 'Bearer $_accessToken'},
    );
    if (res.statusCode == 200) {
      List<dynamic> body = jsonDecode(res.body)['entries'];
      List<BoxFolderItem> result = body
          .map(
            (dynamic item) => BoxFolderItem.fromJson(item),
          )
          .toList();

      debugPrint('Number of items is ${result.length}');
      return result;
    } else {
      throw 'Unable to retrieve items for folder with ID $inFolderWithId.';
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  Future<BoxFolderItem> createFolder(String parentFolderId, String name) async {
    const createFolder = '$boxApiRoot/folders';

    // TODO Check that _accessToken is current first
    debugPrint('Need to check _accessToken is fresh first');

    final body = jsonEncode({
      'name': name,
      'parent': {'id': parentFolderId}
    });

    http.Response res = await http.post(Uri.parse(createFolder),
        headers: <String, String>{
          'authorization': 'Bearer $_accessToken',
          'Content-type': 'application/json'
        },
        body: body);

    // Success is 201 in this case, not 200.
    if (res.statusCode == 201) {
      BoxFolderItem result = BoxFolderItem.fromJson(jsonDecode(res.body));
      debugPrint(
          'New folder created -- name is ${result.name} and id is ${result.id}');
      return result;
    } else {
      debugPrint('Error code is ${res.statusCode}');
      throw Exception(
          'Unable to create folder with parent $parentFolderId with name $name');
    }
  }

  //////////////////////////////////////////////////////////////////////////////

  Future<bool> itemExists(
      final String name, final String inFolderWithId) async {
    bool result = false;

    List<BoxFolderItem> items = await fetchFolderItems(inFolderWithId);

    // Likely a map/list function could be used to compare only name property
    // but did not see it at the time I wrote this.
    containsLoop:
    for (int index = 0; index < items.length; index++) {
      BoxFolderItem currentItem = items[index];
      if (currentItem.name == name) {
        result = true;
        break containsLoop;
      }
    }

    return result;
  }

  //////////////////////////////////////////////////////////////////////////////
  //
  // If a folder item named the same as name is found in the specified folder,
  // then the BoxFolderItem is returned for the match. It will return null if a
  // match is not found.
  //
  Future<BoxFolderItem?> itemWithName(
      final String name, final String inFolderWithId) async {
    BoxFolderItem? result;

    List<BoxFolderItem> items = await fetchFolderItems(inFolderWithId);

    // Likely a map/list function could be used to compare only name property
    // but did not see it at the time I wrote this.
    containsLoop:
    for (int index = 0; index < items.length; index++) {
      BoxFolderItem currentItem = items[index];
      if (currentItem.name == name) {
        result = currentItem;
        break containsLoop;
      }
    }

    return result;
  }
}

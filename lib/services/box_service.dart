import 'dart:convert' show jsonDecode, jsonEncode, JsonEncoder;
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../auth/secrets.dart';

///////////////////////////////////////////////////////////////////////////////
//
// In this package, we define several basic abstractions, including BoxUser and
// BoxFolderItem, as well as the base service, BoxService. Each of these
// abstractions are effectively a subset of those provided by the Box.com API
// that is available through developer.box.com. Note that BoxService is far from
// an exhaustive SDK.
//
// Rob. January 2022
///////////////////////////////////////////////////////////////////////////////

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
    // Just being safe in case their datetime values change to a format we can't
    // parse. Let's be safe and assume parsing may fail.
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
  BoxFolderItem(
      {required this.type,
      required this.id,
      required this.sequenceId,
      required this.etag,
      required this.name,
      required this.tags,
      required this.createdAt,
      required this.modifiedAt});

  final String type;
  final String id;
  final String sequenceId;
  final String etag;
  final String name;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime modifiedAt;

  factory BoxFolderItem.fromJson(Map<String, dynamic> json) => BoxFolderItem(
        type: json['type'],
        id: json['id'],
        sequenceId: json['sequence_id'],
        etag: json['etag'],
        name: json['name'],
        tags: List<String>.from(json['tags'].map((x) => x)),
        createdAt: DateTime.parse(json['created_at']),
        modifiedAt: DateTime.parse(json['modified_at']),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'sequence_id': sequenceId,
        'etag': etag,
        'name': name,
        'tags': List<dynamic>.from(tags.map((x) => x)),
        'created_at': createdAt.toIso8601String(),
        'modified_at': modifiedAt.toIso8601String(),
      };
}

//////////////////////////////////////////////////////////////////////////////
class BoxService {
  // We will store refreshToken and possibly more credentials here.
  // See https://pub.dev/packages/flutter_secure_storage
  //
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Some constants
  //

  // Client App IDs (getting from secrets.dart)
  static const _clientId = MyAppSecrets.boxClientId;
  static const _clientSecret = MyAppSecrets.boxClientSecret;

  // Oauth2
  static const oauth2Root = 'https://account.box.com/api/oauth2';
  static const authorizationEndpoint = '$oauth2Root/authorize';
  static const tokenEndpoint = '$oauth2Root/token';
  // callbackUrlScheme also goes in <approot>/android/app/src/AndroidManifest.xml
  static const callbackUrlScheme = 'hrp01';
  // The redirect URI must match what is defined at developer.box.com:
  //
  // Look for something like: redirectUri => hrp01://redirect
  //
  static const redirectUri = '$callbackUrlScheme://redirect';
  static const completeAuthUriString =
      '$authorizationEndpoint?response_type=code&client_id=$_clientId&redirect_uri=$redirectUri';

  // Finally, for Box API
  static const boxApiRoot = 'https://api.box.com/2.0';

  // We'll manage these for clients. If they are blank we can assume an auth
  // must occur.
  String _accessToken = '';
  String _refreshToken = '';
  DateTime _accessTokenExpiry = DateTime.now(); // We will set it

  /////////////////////////////////////////////////////////////////////////////
  Future<void> _readCredentials() async {
    // Read credentials from secure storage and set member variables
    String? atValue =
        await _secureStorage.read(key: 'box_dot_com_access_token');
    String? rtValue =
        await _secureStorage.read(key: 'box_dot_com_refresh_token');
    String? ateValue =
        await _secureStorage.read(key: 'box_dot_com_access_token_expiry');

    // If no credentials have ever been saved, we will start with empty/expired values.
    // Otherwise, we will set our properties according to what is found.
    _refreshToken = (rtValue == null || rtValue == '') ? '' : rtValue;
    _accessToken = (atValue == null || atValue == '') ? '' : atValue;
    _accessTokenExpiry = (ateValue == null || ateValue == '')
        ? DateTime.now()
        : DateTime.parse(ateValue);
  }

  /////////////////////////////////////////////////////////////////////////////
  Future<void> _writeCredentials() async {
    // Preserve our API credentials, regardless of their state.
    await _secureStorage.write(
        key: 'box_dot_com_refresh_token', value: _refreshToken);
    await _secureStorage.write(
        key: 'box_dot_com_access_token', value: _accessToken);
    await _secureStorage.write(
        key: 'box_dot_com_access_token_expiry',
        value: _accessTokenExpiry.toIso8601String());
  }

  /////////////////////////////////////////////////////////////////////////////
  // Will first try to retrieve a refreshToken from secure local storage, but if
  // none or if expired, will attempt an authenticate. It will manage preserving
  // any updated tokens, but will also return it in the Future in case clilents
  // want to drop down a level and make their own calls to the API.
  //
  // If successful, the String that is returned is the current access token.
  // Also, a refresh token is preserrved to the current secure local storage.
  /////////////////////////////////////////////////////////////////////////////
  Future<String> authInit() async {
    debugPrint('''callbackUrlScheme is $callbackUrlScheme
      redirectUri is $redirectUri
      sending this to box.com: $completeAuthUriString''');

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
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'code': authCode,
        'grant_type': 'authorization_code',
      });

      dynamic responseBody = jsonDecode(response.body);

      if (kDebugMode) {
        JsonEncoder encoder = const JsonEncoder.withIndent('  ');
        String prettyprintResp = encoder.convert(responseBody);
        debugPrint(prettyprintResp);
      }

      // Get the access token from the response
      _accessToken = responseBody['access_token'] as String;
      _refreshToken = responseBody['refresh_token'] as String;
      final expiresIn = responseBody['expires_in'] as int;
      _accessTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
    } on PlatformException catch (pe) {
      debugPrint(
          'Did not get desired auth. exception message is: ${pe.message}');
      // Clear all in-memory credentials.
      _accessToken = '';
      _refreshToken = '';
      _accessTokenExpiry = DateTime.now();
    } finally {
      // Preserve the credentials.
      await _writeCredentials();
    }

    return _accessToken;
  }

  //////////////////////////////////////////////////////////////////////////////
  //
  //////////////////////////////////////////////////////////////////////////////
  Future<String> refreshOrAuthForAccessTokenIfNeeded() async {
    try {
      await _readCredentials();

      // If we find we have no entry yet for refresh_token, or if the value
      // returned is an empty string, let's force an authInit.
      if (_refreshToken == '') {
        debugPrint('No preserved refresh_token so we will send to authInit()');
        _accessToken = await authInit();
        return _accessToken;
      }

      // If we find that the current access token is not yet expired, we will
      // short-circuit here, too, and just return the current access token.
      final rightNow = DateTime.now();
      if (_accessTokenExpiry.isAfter(rightNow)) {
        debugPrint(
            'The access token does not expire until ${_accessTokenExpiry.toString()}. Keep using it.');
        // Access token is not expired yet, keep using it.
        return _accessToken;
      }

      // If we are here we have a refreshToken in secure storage, but the
      // access token is or will soon be expired.
      debugPrint(
          'The access token has expired or will very soon. Trying a refresh.');

      // Use this code to get a new access token via the refresh token.
      final response = await http.post(Uri.parse(tokenEndpoint), headers: {
        'Content-type': 'application/x-www-form-urlencoded'
      }, body: {
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'refresh_token': _refreshToken,
        'grant_type': 'refresh_token',
      });

      dynamic responseBody = jsonDecode(response.body);

      if (kDebugMode) {
        JsonEncoder encoder = const JsonEncoder.withIndent('  ');
        String prettyprintResp = encoder.convert(responseBody);
        debugPrint(prettyprintResp);
      }

      // Get the access token from the response
      _accessToken = responseBody['access_token'] as String;
      _refreshToken = responseBody['refresh_token'] as String;
      final expiresIn = responseBody['expires_in'] as int;
      _accessTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
    } on PlatformException catch (pe) {
      debugPrint(
          'Did not get desired auth. exception message is: ${pe.message}');
      _accessToken = '';
      _refreshToken = '';
      _accessTokenExpiry = DateTime.now();
    } finally {
      await _writeCredentials();
    }

    return _accessToken;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Returns null if any errors or if auth is bailed.
  Future<BoxUser?> getUser() async {
    const usersMe = '$boxApiRoot/users/me';

    await refreshOrAuthForAccessTokenIfNeeded();

    http.Response response = await http.get(
      Uri.parse(usersMe),
      headers: {'authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode == 200) {
      BoxUser result = BoxUser.fromJson(jsonDecode(response.body));
      debugPrint('BoxUser\'s name is ${result.name}');
      return result;
    } else {
      debugPrint(
          'Unable to retrieve Box user. Response status code was ${response.statusCode}');
      return null;
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  Future<List<BoxFolderItem>> fetchFolderItems(
      {required final String inFolderWithId}) async {
    const fieldsPortion =
        '?fields=id,type,name,etag,sequence_id,tags,created_at,modified_at';

    final folderItems =
        '$boxApiRoot/folders/$inFolderWithId/items$fieldsPortion';

    await refreshOrAuthForAccessTokenIfNeeded();

    // final body = jsonEncode({
    //   'fields': [
    //     'id',
    //     'sequence_id',
    //     'name',
    //     'type',
    //     'etag',
    //     'tags',
    //     'created_at',
    //     'modified_at'
    //   ]
    // });

    http.Response response = await http.get(
      Uri.parse(folderItems),
      headers: {'authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode == 200) {
      List<dynamic> responseBody = jsonDecode(response.body)['entries'];

      if (kDebugMode) {
        JsonEncoder encoder = const JsonEncoder.withIndent('  ');
        String prettyprintResp = encoder.convert(responseBody);
        debugPrint(prettyprintResp);
      }

      List<BoxFolderItem> result = responseBody
          .map(
            (dynamic item) => BoxFolderItem.fromJson(item),
          )
          .toList();

      debugPrint('Number of items is ${result.length}');
      return result;
    } else {
      throw Exception(
          'Unable to retrieve items for folder with ID $inFolderWithId.');
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Returns null if creation fails.
  Future<BoxFolderItem?> createFolder(
      {required String name, required String parentFolderId}) async {
    const createFolder = '$boxApiRoot/folders';

    await refreshOrAuthForAccessTokenIfNeeded();

    final body = jsonEncode({
      'name': name,
      'parent': {'id': parentFolderId}
    });

    http.Response response = await http.post(Uri.parse(createFolder),
        headers: <String, String>{
          'authorization': 'Bearer $_accessToken',
          'Content-type': 'application/json'
        },
        body: body);

    // Success is 201 in this case, not 200.
    if (response.statusCode == 201) {
      BoxFolderItem result = BoxFolderItem.fromJson(jsonDecode(response.body));
      debugPrint(
          'New folder created -- name is ${result.name} and id is ${result.id}');

      return result;
    } else {
      debugPrint('''Error code is ${response.statusCode}
        Unable to create folder with parent $parentFolderId with name $name''');

      return null;
    }
  }

  //////////////////////////////////////////////////////////////////////////////

  Future<bool> itemExists(
      {required final String name,
      required final String inFolderWithId}) async {
    bool result = false;

    List<BoxFolderItem> items =
        await fetchFolderItems(inFolderWithId: inFolderWithId);

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
      {required final String name,
      required final String inFolderWithId}) async {
    BoxFolderItem? result;

    List<BoxFolderItem> items =
        await fetchFolderItems(inFolderWithId: inFolderWithId);

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

  //////////////////////////////////////////////////////////////////////////////
  Future<BoxFolderItem?> uploadFile(
      {required final String localPathname,
      required final String simpleFilename,
      required final String parentFolderId}) async {
    const uploadFileUriString = 'https://upload.box.com/api/2.0/files/content';

    await refreshOrAuthForAccessTokenIfNeeded();

    //create multipart request for POST or PATCH method
    var request = http.MultipartRequest('POST', Uri.parse(uploadFileUriString));

    final attributes = jsonEncode({
      'name': simpleFilename,
      'parent': {'id': parentFolderId}
    });

    debugPrint(attributes);

    request.headers['authorization'] = 'Bearer $_accessToken';
    request.headers['Content-type'] = 'multipart/form-data';
    request.fields['attributes'] = attributes;

    var fileToUpload =
        await http.MultipartFile.fromPath('file_field', localPathname);
    //add multipart to request
    request.files.add(fileToUpload);
    var response = await request.send();

    //Get the response from the server
    var responseData = await response.stream.toBytes();
    var responseString = String.fromCharCodes(responseData);

    debugPrint(responseString);
    final respBody = jsonDecode(responseString);

    // Success is 201 in this case, not 200.
    if (response.statusCode == 201) {
      List<dynamic> listOfOne = respBody['entries'];
      List<BoxFolderItem> resultList = listOfOne
          .map(
            (dynamic item) => BoxFolderItem.fromJson(item),
          )
          .toList();

      BoxFolderItem result = resultList.first;

      return result;
    } else {
      debugPrint('''Error code is ${response.statusCode}
        Error reasonPhrase is ${response.reasonPhrase}
        Unable to upload $localPathname to $simpleFilename in parent folder $parentFolderId''');

      return null;
    }
  }
}

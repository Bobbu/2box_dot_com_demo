import './box_service.dart';

class HrpBoxService extends BoxService {
  static const hrpRootFolderIdForProduction = '139465605542';
  static const hrpRootFolderIdForDevelopment = '154663638392';

  static const hrpRootFolderId = hrpRootFolderIdForDevelopment;
  // from Box.com's documentation:
  //
  // The ID for any folder can be determined by visiting this folder in the web
  // application and copying the ID from the URL. For example, for the URL
  // https://*.app.box.com/folder/123 the folder_id is 123

  Future<List<BoxFolderItem>> fetchFoldersAtHrpRoot() async {
    List<BoxFolderItem> result = await fetchFolderItems(hrpRootFolderId);
    return result;
  }
} //


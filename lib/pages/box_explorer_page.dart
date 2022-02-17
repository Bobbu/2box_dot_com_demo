import 'package:flutter/material.dart';
import 'package:flutter_breadcrumb/flutter_breadcrumb.dart';
import 'package:provider/provider.dart';
import '../providers/box_service.dart';
import '../utilities/date_time_extension.dart';

class BoxExplorerPage extends StatefulWidget {
  static const routeName = '/explore-box';

  const BoxExplorerPage({Key? key}) : super(key: key);

  @override
  _BoxExplorerPageState createState() => _BoxExplorerPageState();
}

class _BoxExplorerPageState extends State<BoxExplorerPage> {
  // final boxService = BoxService();

  bool _isInit = true;

  // _folderId and _folderName will be passed to use by those who navigate to us.
  String _folderId = '0';
  String _folderName = 'All Files';

  static final BreadCrumb _breadCrumb = BreadCrumb(
      items: [
        BreadCrumbItem(
            content: const Text(
          'All Files',
          style: TextStyle(color: Colors.white),
        ))
      ],
      divider: const Icon(Icons.chevron_right, color: Colors.white),
      overflow: ScrollableOverflow(
        keepLastDivider: false,
        reverse: false,
        direction: Axis.horizontal,
      ));

  void _tappedOn(BuildContext ctx, BoxFolderItem item) {
    debugPrint('tapped on ${item.name}');
    if (item.type == 'folder') {
      _breadCrumb.items.add(BreadCrumbItem(
          content: Text(
        item.name,
        style: const TextStyle(color: Colors.white),
      )));

      Navigator.pushNamed(context, BoxExplorerPage.routeName,
          arguments: {'folderId': item.id, 'folderName': item.name});
    }
  }

  String _tagsDisplayFor(BoxFolderItem item) {
    String result = '';
    debugPrint(item.name);
    if (item.tags.isNotEmpty) {
      for (int index = 0; index < item.tags.length; index++) {
        result = result + item.tags[index];
        if (index < item.tags.length - 1) {
          result = result + ', ';
        }
        debugPrint('$index and result is =>$result<=');
      }
    }
    return result;
  }

  Icon _iconFor(BoxFolderItem item) {
    String fileExtension = '';
    if (item.name.length > 4) {
      fileExtension = item.name.substring(item.name.length - 4);
    }

    debugPrint(fileExtension);

    const iconSize = 35.0;

    switch (item.type) {
      case 'folder':
        return const Icon(Icons.folder, size: iconSize, color: Colors.amber);
      case 'file':
        switch (fileExtension) {
          case '.jpg':
          case '.png':
          case '.bmp':
          case '.gif':
            return const Icon(Icons.image, size: iconSize, color: Colors.blue);
          case '.pdf':
            return const Icon(Icons.picture_as_pdf,
                size: iconSize, color: Colors.purple);
          default:
            return const Icon(Icons.file_present,
                size: iconSize, color: Colors.red);
        }
      default:
        return const Icon(Icons.question_mark);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInit) {
      final routeArgsRaw = ModalRoute.of(context)?.settings.arguments;
      if (routeArgsRaw == null) {
        // Not passed any arguments. Let's just situate at the top
        _folderId = '0';
        _folderName = 'All Files';
      } else {
        final routeArgs =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
        _folderId = routeArgs['folderId'] as String;
        _folderName = routeArgs['folderName'] as String;
      }
      _isInit = false;
    }

    debugPrint(_folderId);

    return WillPopScope(
      onWillPop: () async {
        if (_breadCrumb.items.length > 1) {
          _breadCrumb.items.removeLast();
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_folderName)),
        body: FutureBuilder(
          future: Provider.of<BoxService>(context, listen: false)
              .fetchFolderItems(inFolderWithId: _folderId),
          builder: (BuildContext context,
              AsyncSnapshot<List<BoxFolderItem>> snapshot) {
            if (snapshot.hasData) {
              List<BoxFolderItem>? folderItems = snapshot.data;
              return Column(
                children: <Widget>[
                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                      color: Colors.indigoAccent,
                      child: _breadCrumb),
                  Expanded(
                    child: ListView(
                      children: folderItems!
                          .map(
                            (BoxFolderItem item) => ListTile(
                                title: Text(item.name),
                                leading: _iconFor(item),
                                subtitle:
                                    Text('${item.id} ${_tagsDisplayFor(item)}'),
                                trailing: Text(
                                    item.modifiedAt.asShortDisplayString()),
                                onTap: () {
                                  _tappedOn(context, item);
                                }),
                          )
                          .toList(),
                    ),
                  ),
                ],
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }
}

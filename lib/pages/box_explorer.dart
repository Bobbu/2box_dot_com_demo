import 'package:flutter/material.dart';
import 'package:flutter_breadcrumb/flutter_breadcrumb.dart';
import '../services/box_service.dart';

class BoxExplorer extends StatefulWidget {
  static const routeName = '/explore-box';

  const BoxExplorer({Key? key}) : super(key: key);

  @override
  _BoxExplorerState createState() => _BoxExplorerState();
}

class _BoxExplorerState extends State<BoxExplorer> {
  final boxService = BoxService();

  bool _isInit = true;

  // _folderId and _breadCrumb will be passed to use by those who navigate to us.
  String _folderId = '0';
  static final BreadCrumb _breadCrumb = BreadCrumb(
      items: [BreadCrumbItem(content: const Text('All Files'))],
      divider: const Icon(Icons.chevron_right),
      overflow: ScrollableOverflow(
        keepLastDivider: false,
        reverse: false,
        direction: Axis.horizontal,
      ));

  void _tappedOn(BuildContext ctx, BoxFolderItem item) {
    debugPrint('tapped on ${item.name}');
    if (item.type == 'folder') {
      _breadCrumb.items.add(BreadCrumbItem(content: Text(item.name)));

      Navigator.pushNamed(context, BoxExplorer.routeName,
          arguments: {'folderId': item.id});
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

    switch (item.type) {
      case 'folder':
        return const Icon(Icons.folder_open);
      case 'file':
        switch (fileExtension) {
          case '.jpg':
          case '.png':
          case '.bmp':
          case '.gif':
            return const Icon(Icons.image);
          case '.pdf':
            return const Icon(Icons.picture_as_pdf);
          default:
            return const Icon(Icons.file_present);
        }
      default:
        return const Icon(Icons.question_mark);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInit) {
      final routeArgs =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
      _folderId = routeArgs['folderId'] as String;
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
        appBar: AppBar(title: const Text('Box Explorer')),
        body: FutureBuilder(
          future: boxService.fetchFolderItems(inFolderWithId: _folderId),
          builder: (BuildContext context,
              AsyncSnapshot<List<BoxFolderItem>> snapshot) {
            if (snapshot.hasData) {
              List<BoxFolderItem>? folderItems = snapshot.data;
              return Column(
                children: <Widget>[
                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      color: Colors.deepOrangeAccent,
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
                                // trailing:
                                //     _iconFor(_aggregateStateFor(pa.patient)),
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

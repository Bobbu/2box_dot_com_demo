import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './pages/box_explorer_page.dart';
import './pages/home_page.dart';
import './providers/box_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BoxService()),
        ],
        child: MaterialApp(
            title: 'Box.com Demo',
            theme: ThemeData(
              primarySwatch: Colors.deepOrange,
            ),
            routes: {
              HomePage.routeName: (ctx) => const HomePage(title: 'Box Driver'),
              BoxExplorerPage.routeName: (ctx) => const BoxExplorerPage(),
            }));
  }
}

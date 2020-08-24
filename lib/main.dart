import 'package:flutter/material.dart';

import 'map-page.dart';
import 'tip-page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      //debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primarySwatch: Colors.lightGreen,
          primaryTextTheme: TextTheme(
              headline6: TextStyle(
            color: Colors.white,
          ))),
      darkTheme: ThemeData(
        accentColor: Colors.lightGreen,
        brightness: Brightness.dark,
        //chipTheme: ChipTheme.of(context).copyWith(shadowColor: Colors.lightGreen),
      ),
      home: MyHomePage(title: 'The Good Map'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Widget> _myPages = <Widget>[
    MapPage(
      key: PageStorageKey('MapPage'),
    ),
    TipPage(key: PageStorageKey('TipPage'))
  ];

  int _selectedIndex = 0;

  final PageStorageBucket _bucket = PageStorageBucket();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        brightness: Brightness.dark,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.map,
            ),
            title: Text('Map'),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.thumb_up,
            ),
            title: Text(
              'Tips',
            ),
          )
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      body: PageStorage(
        child: _myPages[_selectedIndex],
        bucket: _bucket,
      ),
    );
  }
}

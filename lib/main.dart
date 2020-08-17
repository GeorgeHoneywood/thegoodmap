import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong/latlong.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WasteMap',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'WasteMap'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _counter = 0;

  Future<Map> futurePoI;

  MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
  }

  Future<Map> fetchPoI() async {
    const api_url = "https://overpass-api.de/api/interpreter";

    final bounds = mapController.bounds;

    final queryString = """
[out:json][timeout:25][bbox:${bounds.south},${bounds.west},${bounds.north},${bounds.east}];
(nwr["zero_waste"~"(yes|only|limited)"];
 nwr[~"diet:(vegan|vegetarian)"~"(yes|limited|only)"];
 nwr["organic"~"(yes|limited|only)"];
 nwr["bulk_purchase"~"(yes|limited|only)"];
);
out tags qt center;
""";

    final response = await http.post(api_url, body: {"data": queryString});

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return json.decode(response.body);
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load PoI');
    }
  }

  void loadPoI() {
    futurePoI = fetchPoI();
    futurePoI
        .then((value) => handlePoI(value))
        .catchError((error) => handleError(error));
  }

  Marker createMarker(double lat, double lon, Map<String, dynamic> tags) {
    return Marker(
      point: new LatLng(lat, lon),
      anchorPos: AnchorPos.align(AnchorAlign.top),
      builder: (ctx) => new Container(
        child: GestureDetector(
          onTap: () {
            //_scaffoldKey.currentState.showSnackBar(SnackBar(
            //  content: Text(tags["name"]),
            //));
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailTable(tags: tags),
              ),
            );
          },
          child: new Icon(
            Icons.place,
            color: Colors.blue,
            size: 36.0,
          ),
        ),
      ),
    );
  }

  void handlePoI(PoIs) {
    PoIs = PoIs["elements"];

    PoIs = filterPoIs(PoIs);

    setState(() {
      PoIs.forEach((PoI) {
        if (PoI["type"] == "node") {
          _markers.add(createMarker(PoI["lat"], PoI["lon"], PoI["tags"]));
        } else {
          _markers.add(createMarker(
              PoI["center"]["lat"], PoI["center"]["lon"], PoI["tags"]));
        }
      });
      _markers = List.from(_markers);
    });
  }

  List filterPoIs(List PoIs) {
    List filteredPoIs = new List();

    PoIs.forEach((PoI) {
      if (PoI["tags"].containsKey("diet:vegan")) {
        filteredPoIs.add(PoI);
      }
    });

    return filteredPoIs;
  }

  void handleError(error) {
    print("pain");
  }

  List<Marker> _markers = <Marker>[
//    Marker(
//      point: new LatLng(51.5, -0.010),
//      builder: (ctx) => new Container(
//        child: new Icon(
//          Icons.place,
//          color: Colors.green,
//          size: 36.0,
//        ),
//      ),
//    ),
  ];

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Flexible(
              child: FlutterMap(
                mapController: mapController,
                options: new MapOptions(
                  center: new LatLng(51.5, -0.09),
                  zoom: 13.0,
                  maxZoom: 19,
                  minZoom: 0,
                  plugins: [
                    MarkerClusterPlugin(),
                  ],
                ),
                layers: [
                  new TileLayerOptions(
                      // tileProvider: NetworkTileProvider(), // needed to make map load on desktop
                      maxZoom: 19,
                      minZoom: 0,
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c']),
                  // new MarkerLayerOptions(markers: _markers), // before i used the cluster thingy
                  MarkerClusterLayerOptions(
                    maxClusterRadius: 120,
                    size: Size(40, 40),
                    fitBoundsOptions: FitBoundsOptions(
                      padding: EdgeInsets.all(50),
                    ),
                    markers: _markers,
                    polygonOptions: PolygonOptions(
                        borderColor: Colors.blueAccent,
                        color: Colors.black12,
                        borderStrokeWidth: 3),
                    builder: (context, markers) {
                      return FloatingActionButton(
                        child: Text(markers.length.toString()),
                        onPressed: null,
                        heroTag: null,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadPoI,
        tooltip: 'Load Points of Interest',
        child: Icon(Icons.search),
        heroTag: "loadPoI",
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class DetailTable extends StatelessWidget {
  final Map tags;

  DetailTable({Key key, @required this.tags}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<DataRow> _dataRows = [];

    tags.forEach((key, value) {
      _dataRows.add(new DataRow(cells: <DataCell>[
        new DataCell(Text(key)),
        new DataCell(Text(value)),
      ]));
    });

    return Scaffold(
        appBar: AppBar(
          title: Text(tags["name"]),
        ),
        body: SingleChildScrollView(
            padding: EdgeInsets.all(0),
            child: Container(
              child: Column(
                children: [
                  DataTable(
                    dataRowHeight: 35,
                    columns: const <DataColumn>[
                      DataColumn(
                        label: Text(
                          'Key',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Value',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                    rows: _dataRows,
                  ),
                ],
              ),
            )));
  }
}

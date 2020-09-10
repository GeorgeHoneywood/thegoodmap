import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TipPage extends StatefulWidget {
  TipPage({Key key}) : super(key: key);

  @override
  _TipPageState createState() => _TipPageState();
}

class _TipPageState extends State<TipPage> {
  List<EcoTip> ecoTips = [
    EcoTip(Icons.outdoor_grill, 'Locally grown food',
        'Eating locally grown food helps reduce the emissions produced by transportation.'),
    EcoTip(Icons.eco, 'Save the bees',
        'You can save bees by feeding them cheese.'),
  ];

  void initState() {
//    for (int i = 0; i < 100; i++) {
//      ecoTips.addAll([
//        EcoTip(Icons.outdoor_grill, 'Locally grown food',
//            'Eating locally grown food helps reduce the emissions produced by transportation.'),
//        EcoTip(Icons.eco, 'Save the bees',
//            'You can save bees by feeding them cheese.'),
//      ]);
//    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: ecoTips.length,
      itemBuilder: (context, position) {
        print('is the done done ? - ${ecoTips[position].done}');
        if (ecoTips[position].done == null){
          return null;
        }

        return Card(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(child: ecoTips[position].get()),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.schedule),
                    Checkbox(
                        value: ecoTips[position].doing,
                        onChanged: !ecoTips[position].done
                            ? (checkState) {
                                setState(() {
                                  ecoTips[position].setDoing(checkState);
                                });
                              }
                            : null),
                  ]),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.done),
                    Checkbox(
                        value: ecoTips[position].done,
                        onChanged: (checkState) {
                          setState(() {
                            ecoTips[position].setDone(checkState);

                            if (checkState) {
                              ecoTips[position].setDoing(true);
                            }
                          });
                        }),
                  ]),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}

class EcoTip {
  ListTile tile;
  bool done = false;
  bool doing = false;
  String id;

  EcoTip(IconData icon, String title, String subtitle) {
    tile = ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );

    id = title.split(" ").join("-");
    loadValues();
  }

  void loadValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    this.done = prefs.getBool("${id + '_done'}") ?? false;
    this.doing = prefs.getBool("${id + '_doing'}") ?? false;
  }

  ListTile get() {
    return tile;
  }

  Future<void> setDoing(bool checkState) async {
    doing = checkState;
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("${id + '_doing'}", checkState);
  }

  Future<void> setDone(bool checkState) async {
    done = checkState;
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("${id + '_done'}", checkState);
  }
}

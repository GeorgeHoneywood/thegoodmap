import 'package:flutter/material.dart';

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
    for (int i = 0; i < 100; i++) {
      ecoTips.addAll([
        EcoTip(Icons.outdoor_grill, 'Locally grown food',
            'Eating locally grown food helps reduce the emissions produced by transportation.'),
        EcoTip(Icons.eco, 'Save the bees',
            'You can save bees by feeding them cheese.'),
      ]);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: ecoTips.length,
      itemBuilder: (context, position) {
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
                        value: true,
                        onChanged: (checkState) {
                          ecoTips[position].doing = checkState;
                        }),
                  ]),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.done),
                    Checkbox(
                        value: false,
                        onChanged: (checkState) {
                          setState(() {
                            ecoTips[position].done = checkState;
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
  bool done;
  bool doing;

  EcoTip(IconData icon, String title, String subtitle) {
    tile = ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  ListTile get() {
    return tile;
  }
}

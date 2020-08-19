import 'package:flutter/material.dart';

class TipPage extends StatelessWidget {
  const TipPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Card(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Icon(
                    Icons.thumb_up,
                    size: 50.0,
                  ),
                  Text(
                    'Lorem tipsum',
                    style: TextStyle(fontSize: 50.0),
                  ),
                ],
              ),
            )
          ],
        ));
  }
}

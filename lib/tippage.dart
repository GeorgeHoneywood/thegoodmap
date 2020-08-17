import 'package:flutter/material.dart';

class PageTwo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
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
                'Tips Page',
                style: TextStyle(fontSize: 50.0),
              ),
            ],
          ),
        )
      ],
    );
  }
}
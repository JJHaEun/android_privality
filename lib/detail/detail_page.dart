import 'package:flutter/material.dart';

class DetailPage extends StatefulWidget {
  final String question;
  final String answer;

const DetailPage({super.key, required this.answer, required this.question});

  @override
  State<StatefulWidget> createState() {
    return _DetailPage();
  }
}

class _DetailPage extends State<DetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            Text(widget.question),
            Text(widget.answer),
            ElevatedButton(
                onPressed: (){
                    Navigator.of(context).pop();
                },
                child: const Text('뒤로가기'))
          ],
        ),
      ),
    );
  }
}
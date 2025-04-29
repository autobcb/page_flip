import 'package:example/page.dart';
import 'package:flutter/material.dart';
import 'package:page_flip/page_flip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = GlobalKey<PageFlipWidgetState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageFlipWidget(
        key: _controller,
        backgroundColor: Colors.yellow,
        initialIndex: 5,
        children: <Widget>[
          for (var i = 0; i < 10; i++) DemoPage(page: i),
        ],
        onPageFlipped: (pageNumber) {
          //debugPrint('onPageFlipped: (pageNumber) $pageNumber');
        },
        onFlipStart: (index) {
          return true;
         // debugPrint('onFlipStart');
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.looks_5_outlined),
        onPressed: () {
          _controller.currentState?.previousPage();
        },
      ),
    );
  }
}

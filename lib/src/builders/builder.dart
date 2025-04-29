import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../page_flip.dart';

Map<int, ui.Image?> imageData = {};
ValueNotifier<int> currentPage = ValueNotifier(-1);
ValueNotifier<Widget> currentWidget = ValueNotifier(Container());
ValueNotifier<int> currentPageIndex = ValueNotifier(0);

class PageFlipBuilder extends StatefulWidget {
  const PageFlipBuilder({
    Key? key,
    required this.amount,
    this.backgroundColor,
    required this.pages,
    required this.pageIndex,
    required this.isRightSwipe,
  }) : super(key: key);

  final Animation<double> amount;
  final int pageIndex;
  final Color? backgroundColor;
  final List<Widget> pages;
  final bool isRightSwipe;

  @override
  State<PageFlipBuilder> createState() => PageFlipBuilderState();
}

class PageFlipBuilderState extends State<PageFlipBuilder> {
  final _boundaryKey = GlobalKey();

  void _captureImage(Duration timeStamp, int index) async {
    if (_boundaryKey.currentContext == null) return;
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      if( _boundaryKey.currentContext == null) return;
      final boundary = _boundaryKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage();
      setState(() {
        imageData[index] = image.clone();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: currentPage,
      builder: (context, value, child) {
        //print("pageIndex:${widget.pageIndex}");
        //print("value:${value}");
        if(widget.pageIndex == -1){
          if(currentPageIndex.value != 0 ){
            if(imageData[currentPageIndex.value-1] == null){
              WidgetsBinding.instance.addPostFrameCallback(
                    (timeStamp) => _captureImage(timeStamp, currentPageIndex.value-1),
              );
            }
            return ColoredBox(
              color: widget.backgroundColor ?? Colors.black12,
              child: RepaintBoundary(
                key: _boundaryKey,
                child: widget.pages[currentPageIndex.value-1],
              ),
            );
          }
          print("pageIndex:${widget.pageIndex}");
          return Container();
        }
        if (imageData[widget.pageIndex] != null && value >= 0) {
          return CustomPaint(
            painter: PageFlipEffect(
              amount: widget.amount,
              image: imageData[widget.pageIndex]!,
              backgroundColor: widget.backgroundColor,
              isRightSwipe: widget.isRightSwipe,
            ),
            size: Size.infinite,
          );
        } else {
          if (widget.pageIndex == currentPageIndex.value ) {
            if(imageData[ widget.pageIndex] == null){
              WidgetsBinding.instance.addPostFrameCallback(
                    (timeStamp) => _captureImage(timeStamp, widget.pageIndex),
              );
            }
          }

          if (widget.pageIndex == currentPageIndex.value ||
              (widget.pageIndex == (currentPageIndex.value + 1))) {
            return ColoredBox(
              color: widget.backgroundColor ?? Colors.black12,
              child: RepaintBoundary(
                key: _boundaryKey,
                child: widget.pages[widget.pageIndex],
              ),
            );
          } else {
            return Container();
          }
        }
      },
    );
  }
}

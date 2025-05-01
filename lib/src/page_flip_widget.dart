import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../page_flip.dart';

class PageFlipWidget extends StatefulWidget {
  final PageFlipController? controller;
  const PageFlipWidget({
    Key? key,
    this.duration = const Duration(milliseconds: 450),
    this.cutoffForward = 0.8,
    this.cutoffPrevious = 0.1,
    this.backgroundColor = Colors.white,
    required this.children,
    this.initialIndex = 0,
    this.onPageFlipped,
    this.onFlipStart,
    this.controller,
  })  : assert(initialIndex < children.length,
            'initialIndex cannot be greater than children length'),
        super(key: key);

  final Color backgroundColor;
  final List<Widget> children;
  final Duration duration;
  final int initialIndex;
  final double cutoffForward;
  final double cutoffPrevious;
  final void Function(int pageNumber)? onPageFlipped;
  final bool Function(int pageNumber)? onFlipStart;

  @override
  PageFlipWidgetState createState() => PageFlipWidgetState();
}

class PageFlipWidgetState extends State<PageFlipWidget>
    with TickerProviderStateMixin {
  int pageNumber = 0;
  List<Widget> pages = [];
  final List<AnimationController> _controllers = [];
  late Offset downPos;
  int _type=0;
  bool isAnimation=false;

  @override
  void didUpdateWidget(PageFlipWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize global variables (defined in page_flip.dart)
    imageData = {};
    currentPage = ValueNotifier(-1);
    currentWidget = ValueNotifier(Container());
    currentPageIndex = ValueNotifier(0);
    // Associate the controller, if provided, with this state
    widget.controller?._state = this;
    _setUp();
  }

  Widget? prepage= null;

  void refresh({bool isRefresh = false}){
    _setUp(isRefresh:isRefresh);
  }

  void _setUp({bool isRefresh = false}) {
    _controllers.clear();
    imageData.clear();
    pages.clear();
    List<Widget> items =[];
    for (var i = 0; i < widget.children.length; i++) {
      items.add(widget.children[i]);
    }
    for (var i = 0; i < widget.children.length; i++) {
      final controller = AnimationController(
        value: i < widget.initialIndex ?0:1,
        duration: widget.duration,
        vsync: this,
      );
      _controllers.add(controller);
      final child = PageFlipBuilder(
        amount: controller,
        backgroundColor: widget.backgroundColor,
        isRightSwipe: false,
        pageIndex: i,
        key: Key('item$i'),
        pages: items,
      );
      pages.add(child);
    }
    pages = pages.reversed.toList();
    final controller = AnimationController(
      value:1,
      duration: widget.duration,
      vsync: this,
    );
    prepage = PageFlipBuilder(
      amount: controller,
      backgroundColor: widget.backgroundColor,
      isRightSwipe: false,
      pageIndex: -1,
      key: Key('item -1'),
      pages: items,
    );
    if (isRefresh) {
      goToPage(pageNumber);
    } else {
      pageNumber = widget.initialIndex;
      lastPageLoad = pages.length < 3 ? 0 : 3;
    }
    if (widget.initialIndex != 0) {
      currentPage = ValueNotifier(widget.initialIndex);
      currentWidget = ValueNotifier(pages[widget.initialIndex]);
      currentPageIndex = ValueNotifier(widget.initialIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        currentPage.value = -1;
      });
    }
    print("pageNumber:$pageNumber");
  }

  int lastPageLoad = 0;



  /// Triggers the animation to advance to the next page – via gesture or button.
  Future nextPage() async {
    if(pageNumber == pages.length -1) return;
    if(isAnimation) return;
    isAnimation=true;
    try{
      // Update currentPage to trigger the builder effect
      currentPage.value = pageNumber;
      await _controllers[pageNumber].reverse();
      if (mounted) {
        setState(() {
          pageNumber++;
        });
        if (pageNumber < pages.length) {
          currentPageIndex.value = pageNumber;
          currentWidget.value = pages[pageNumber];
        }
        widget.onPageFlipped?.call(pageNumber);
      }
      // Reset currentPage after the animation
      currentPage.value = -1;
    }finally{
      isAnimation=false;
    }
  }

  /// Triggers the animation to go back to the previous page – via gesture or button.
  Future previousPage() async {
    if(pageNumber == 0) return;
    if(isAnimation) return;
    isAnimation=true;
    try{
      currentPage.value = pageNumber - 1;
      await _controllers[pageNumber - 1].forward();
      if (mounted) {
        setState(() {
          pageNumber--;
        });
        currentPageIndex.value = pageNumber;
        currentWidget.value = pages[pageNumber];
        imageData[pageNumber] = null;
        widget.onPageFlipped?.call(pageNumber);
      }
      currentPage.value = -1;
    }finally{
      isAnimation=false;
    }
  }

  Future goToPage(int index) async {
    //imageData.clear();
    if (mounted) {
      setState(() {
        pageNumber = index;
      });
    }
    for (var i = 0; i < _controllers.length; i++) {
      if (i < index) {
        _controllers[i].value = 0;
      } else {
        _controllers[i].value = 1;
      }
    }
    
    currentPageIndex.value = pageNumber;
    currentWidget.value = pages[pageNumber];
    currentPage.value = pageNumber;
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      currentPage.value = -1;
    });
  }

  bool _canturn(int index){
    if(widget.onFlipStart == null){
      return true;
    }
    return widget.onFlipStart!(index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, dimens) {
        return GestureDetector(
          onPanDown: (d) {
            downPos = d.localPosition;
          },
          onPanUpdate: (d) {
            if (isAnimation) {
              return;
            }
            if(_type == 0){
              var yd=downPos.dx - d.localPosition.dx;
              if(yd > 20 || yd < -20){
                if(downPos.dx > d.localPosition.dx){
                  _type=1;
                }else{
                  _type=2;
                }
              }
            }

           // print( d.delta.dx );

            //print(_type);
            final pageLength = pages.length;
            final pageSize =pageLength - 1;
            if(_type == 1){
              if(pageNumber == pageSize){
                return;
              }
              if(!_canturn(pageNumber +1)){
                return;
              }
              currentPage.value = pageNumber;
              currentWidget.value = Container();
              final ratio = (downPos.dx -d.localPosition.dx ) / dimens.maxWidth;
              for(var i =0 ; i< _controllers.length ;i++){
                if(i < pageNumber){
                  _controllers[i].value = 0;
                }else if(i  == pageNumber){
                  _controllers[i].value = 1-ratio;
                }else{
                  _controllers[i].value = 1;
                }
              }
            }
            if(_type == 2){
              if(pageNumber == 0){
                return;
              }
              if(!_canturn(pageNumber -1)){
                return;
              }
              currentPage.value = pageNumber-1;
              currentWidget.value = Container();
              final ratio = ( dimens.maxWidth -d.localPosition.dx ) / dimens.maxWidth;
              for(var i =0 ; i< _controllers.length ;i++){
                if(i < pageNumber-1){
                  _controllers[i].value = 0;
                }else if(i  == pageNumber-1){
                  _controllers[i].value = 1-ratio;
                }else{
                  _controllers[i].value = 1;
                }
              }
            }
          },
          onPanEnd: (d) {
            if (isAnimation) {
              return;
            }
            try{
              final pageLength = pages.length;
              final pageSize =pageLength - 1;
              if(_type == 1){
                if(pageNumber == pageSize){
                  return;
                }
                if(!_canturn(pageNumber +1)){
                  return;
                }
                if( _controllers[pageNumber].value > 0.95){
                  _controllers[pageNumber].value = 1;
                  currentPageIndex.value = pageNumber;
                  currentWidget.value = pages[pageNumber];
                  currentPage.value = -1;
                  return;
                }
                nextPage();
              }
              if(_type == 2){
                if(pageNumber == 0){
                  return;
                }
                if(!_canturn(pageNumber -1)){
                  return;
                }
                if(_controllers[pageNumber-1].value < 0.5){
                  _controllers[pageNumber-1].value = 0;
                  currentPageIndex.value = pageNumber;
                  currentWidget.value = pages[pageNumber];
                  currentPage.value = -1;
                  return;
                }
                previousPage();
              }
            }finally{
              _type=0;
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if(prepage != null)...[
                prepage!,
              ],
              if (pages.isNotEmpty) ...pages else const SizedBox.shrink(),
            ],
          ),
        );
      },
    );
  }
}

class PageFlipController {
  PageFlipWidgetState? _state;

  void nextPage() {
    _state?.nextPage();
  }

  void previousPage() {
    _state?.previousPage();
  }

  void goToPage(int index) {
    _state?.goToPage(index);
  }
}

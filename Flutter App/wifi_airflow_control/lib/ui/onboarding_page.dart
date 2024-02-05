import 'package:flutter/material.dart';

class OnBoard extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _OnBoardState createState() => _OnBoardState();
}

class _OnBoardState extends State<OnBoard> {
  final controller = PageController();

  @override
  void dispose(){
    controller.dispose();

    super.dispose();
  }


  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          padding: const EdgeInsets.only(bottom: 80),
          child: PageView(
            controller: controller,
            children: [
        Container(
          color: Colors.white,
          child: const  Center(child: Text('Page 1'),
          ),
        ),
        Container(
          color: const Color.fromARGB(255, 71, 151, 215),
          child: const Center(child: Text('Page 2'),
          ) ,
        ),
        Container(
          color: Colors.grey,
          child: const Center(child: Text('Page 3'),
          ),
        )
      ],
    ),
  ),
  bottomSheet: Container(
    padding: const EdgeInsets.symmetric(horizontal:80),
    height: 80,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: (() {}), 
          child: const Text('SKIP')),
        TextButton(
          onPressed: () {}, 
          child: const Text('NEXT'))
      ],
    ),
  ),

    
    
  );
 
}
import 'package:flutter/material.dart';


class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController(initialPage: 0);
  int _currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            children: <Widget>[
              OnboardingPage(
                title: 'Welcome to IFlow',
                description: 'An app designed to change the flow of air within any given room. ',
              ),
              OnboardingPage(
                title: 'Discover Amazing Features',
                description: 'Login in and scan your qr code to start adding and controlling your air damper. ', 
              ),
              OnboardingPage(
                title: '',
                description: ' ',
              ),
              OnboardingPage(
                title: '',
                description: '',
              ),
              OnboardingPage(
                title: 'Get Started Now',
                description: 'description.',
                isLast: true,
              ),
            ],
          ),
          Positioned(
            bottom: 30.0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => buildDot(index),
              ),
            ),
          ),
          Positioned(
            bottom: 10.0,
            left: 0,
            right: 0,
            child: _currentPageIndex == 2
                ? ElevatedButton(
                    onPressed: () {
                      // Navigate to the main app
                    },
                    child: Text('Get Started'),
                  )
                : SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 5.0),
      height: 8.0,
      width: _currentPageIndex == index ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: _currentPageIndex == index ? Colors.blue : Colors.grey,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final bool isLast;

  const OnboardingPage({
    Key? key,
    required this.title,
    required this.description,
    this.isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          
          SizedBox(height: 30.0),
          Text(
            title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10.0),
          Text(
            description,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30.0),
          isLast
              ? SizedBox()
              : ElevatedButton(
                  onPressed: () {
                    // Navigate to the next onboarding screen
                    final _OnboardingScreenState state =
                        context.findAncestorStateOfType<_OnboardingScreenState>()!;
                    state._controller.nextPage(
                      duration: Duration(milliseconds: 500),
                      curve: Curves.ease,
                    );
                  },
                  child: Text('Next'),
                ),
        ],
      ),
    );
  }
}

 






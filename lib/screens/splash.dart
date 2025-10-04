import 'package:flutter/material.dart';
import 'package:seat_sync_v2/screens/auth/login.dart';
import 'package:seat_sync_v2/screens/tabs.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/splash_screen_image.png"),
            fit: BoxFit.cover, // pura screen cover karega
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // yeh Expanded text ko center ke thoda neeche rakhega
            Expanded(
              child: Align(
                alignment: Alignment(0, 0.5), // 0 = center, 0.3 = thoda neeche
                child: Text(
                  'Seat Sync',
                  style: TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsGeometry.all(10),
              child: Row(
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: LinearBorder(
                        side: BorderSide(
                          color: const Color.fromARGB(255, 255, 115, 0),
                          width: 2,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 42,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => TabsScreen()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: Text(
                      'Guest User',
                      style: TextStyle(
                        fontSize: 20,
                        color: const Color.fromARGB(255, 255, 115, 0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: LinearBorder(
                        side: BorderSide(
                          color: const Color.fromARGB(255, 255, 115, 0),
                          width: 2,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 67,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 20,
                        color: const Color.fromARGB(255, 255, 115, 0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

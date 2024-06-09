import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:localstorage/localstorage.dart';
import 'room_page.dart';

class MuseumMapPage extends StatelessWidget {
  final String username;
  final String museum;
  final String role;

  MuseumMapPage({
    required this.username,
    required this.museum,
    required this.role});

  void _logout(BuildContext context) async {
    localStorage.clear();


    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _onMapAreaTap(BuildContext context, String area) {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomDetailPage(
          roomName: "Room "+area,
          username: username,
          museum: museum,
          role: role,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Museum Map'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PopupMenuButton<String>(
                  icon: Icon(Icons.person),
                  onSelected: (value) {
                    if (value == 'logout') {
                      _logout(context);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Text('Logout'),
                      ),
                    ];
                  },
                ),
                SizedBox(width: 8),
                Text(
                  username,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: Stack(
          children: [
            Image.network(
              'https://i.postimg.cc/bwTg0Sj9/Captura-de-ecr-2024-06-02-150429.png',
              fit: BoxFit.cover,
            ),

            Positioned(
              top: 135,
              left: 220,
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () => _onMapAreaTap(context, '1'),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),

            Positioned(
              top: 60,
              left: 180,
              width: 120,
              height: 80,
              child: GestureDetector(
                onTap: () => _onMapAreaTap(context, '2'),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

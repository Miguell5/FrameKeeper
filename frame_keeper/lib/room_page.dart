import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:localstorage/localstorage.dart';
import 'login_page.dart';
import 'history_page.dart';

class RoomDetailPage extends StatefulWidget {
  final String roomName;
  final String museum;
  final String username;
  final String role;

  RoomDetailPage({
    required this.roomName,
    required this.username,
    required this.museum,
    required this.role,
  });

  @override
  _RoomDetailPageState createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  Map<String, dynamic> roomData = {};
  final TextEditingController _maxHumidityController = TextEditingController();
  double maxHumidity = 0;
  String insertedBy = "";
  String insertedRole = "";
  double currentHumidity = 0;
  bool movementDetected = false;
  bool fanState = false;

  @override
  void initState() {
    super.initState();
    _fetchRoomData();
    _listenToMovementChanges();
  }

  void _logout(BuildContext context) async {
    localStorage.clear();


    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> _fetchRoomData() async {
    try {
      Query roomRef = FirebaseDatabase.instance
          .ref()
          .child('rooms')
          .orderByChild('name')
          .equalTo(widget.roomName);

      DataSnapshot snapshot = await roomRef.once().then((event) => event.snapshot);
      Map<dynamic, dynamic> roomsMap = snapshot.value as Map<dynamic, dynamic>;
      Map<dynamic, dynamic> room = roomsMap.values.first as Map<dynamic, dynamic>;

      setState(() {
        roomData = Map<String, dynamic>.from(room);
        maxHumidity = roomData['maxHumidity'];
        insertedBy = roomData['insertedBy'];
        currentHumidity = roomData['currentHumidity'];
        insertedRole = roomData['role'];
        movementDetected = roomData['movement'];
        fanState = roomData['fan'];
      });
    } catch (e) {
      print('Error fetching room data: $e');
    }
  }

  void _listenToMovementChanges() async {
    Query roomRef = FirebaseDatabase.instance
        .ref()
        .child('rooms')
        .orderByChild('name')
        .equalTo(widget.roomName);
    roomRef.onChildChanged.listen((event) {
      var room = event.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        movementDetected = room["movement"];
        currentHumidity = room['currentHumidity'];
        fanState = room['fan'];
      });
    });
  }

  bool _canUpdateMaxHumidity() {
    const roleHierarchy = {'Novice': 1, 'Worker': 2, 'Administrator': 3};
    return roleHierarchy[widget.role]! >= roleHierarchy[insertedRole]!;
  }

  void _toggleFanState() async {
    try {
      DatabaseReference roomRef = FirebaseDatabase.instance.ref().child('rooms').child(roomData['roomId']);


      DataSnapshot snapshot = await roomRef.child('fan').get();
      bool currentFanState = snapshot.value as bool;


      await roomRef.update({
        'fan': !currentFanState
      });


      setState(() {
        fanState = !currentFanState;
      });


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(fanState ? 'Fan turned on.' : 'Fan turned off.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update fan state. Please try again later.'),
          duration: Duration(seconds: 2),
        ),
      );
      print('Error updating fan state: $e');
    }
  }

  Future<void> _deleteRoom() async {
    if (roomData['roomId'] == "Room1 - Louvre Museum") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This room cannot be deleted.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      DatabaseReference roomRef = FirebaseDatabase.instance.ref().child('rooms').child(roomData['roomId']);
      await roomRef.remove();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Room deleted successfully.'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete room. Please try again later.'),
          duration: Duration(seconds: 2),
        ),
      );
      print('Error deleting room: $e');
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this room?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm) {
      _deleteRoom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        centerTitle: true,
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
                  widget.username,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Humidity'),
            _buildInfoCard('Current Humidity in ${widget.roomName}: ${currentHumidity ?? 'N/A'}%'),
            _buildInfoCard('Max Humidity: $maxHumidity %'),
            Text(
              'Value inserted by: $insertedBy ($insertedRole)',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _maxHumidityController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Set new Max Humidity for ${widget.roomName}',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if (!_canUpdateMaxHumidity()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('You do not have permission to update the Max Humidity.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  String newValue = _maxHumidityController.text;
                  if (newValue.isNotEmpty) {
                    double? newMaxHumidity = double.tryParse(newValue);
                    if (newMaxHumidity != null && newMaxHumidity >= 0 && newMaxHumidity <= 100) {
                      await _updateMaxHumidity(newMaxHumidity);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a valid number for Max Humidity between 0 and 100.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please enter a value for Max Humidity.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: Text(
                  'Apply New Value',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildSectionTitle('Security'),
            _buildInfoCard(movementDetected
                ? 'Movement detected in ${widget.roomName}'
                : 'No movement detected in ${widget.roomName}'),
            _buildInfoCard('Last Security Breach: ${roomData['lastSecurityBreach'] ?? 'N/A'}'),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryPage(
                        username: widget.username,
                        roomName: widget.roomName,
                        museum: widget.museum,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: Text(
                  'History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _toggleFanState,
                style: ElevatedButton.styleFrom(
                  backgroundColor: fanState ? Colors.red : Colors.green,
                ),
                child: Text(
                  fanState ? 'Turn Off' : 'Turn On',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _showDeleteConfirmationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text(
                  'Delete Room',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard(String text) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          text,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _updateMaxHumidity(double newMaxHumidity) async {
    try {
      DatabaseReference roomRef = FirebaseDatabase.instance.ref().child('rooms').child(roomData['roomId']);
      await roomRef.update({
        'maxHumidity': newMaxHumidity,
        'insertedBy': widget.username,
        'role': widget.role,
      });

      setState(() {
        maxHumidity = newMaxHumidity;
        insertedBy = widget.username;
        insertedRole = widget.role;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Max Humidity updated successfully.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update Max Humidity. Please try again later.'),
          duration: Duration(seconds: 2),
        ),
      );
      print('Error updating Max Humidity: $e');
    }
  }
}

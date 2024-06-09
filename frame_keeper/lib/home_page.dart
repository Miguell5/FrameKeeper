import 'package:flutter/material.dart';
import 'room_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'museumMap_page.dart';
import 'login_page.dart';
import 'package:localstorage/localstorage.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String museum;
  final String role;

  HomePage({required this.username, required this.museum, required this.role});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, String>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchRooms();
    _listenToRoomChanges();
  }

  Future<void> _fetchRooms() async {
    Query roomsQuery = FirebaseDatabase.instance
        .ref()
        .child('rooms')
        .orderByChild('museum')
        .equalTo(widget.museum);

    DatabaseEvent event = await roomsQuery.once();

    List<Map<String, dynamic>> rooms = [];
    if (event.snapshot.value != null) {
      Map<dynamic, dynamic> roomsMap = event.snapshot.value as Map<dynamic, dynamic>;
      roomsMap.forEach((key, value) {
        rooms.add(Map<String, dynamic>.from(value));
      });
    }

    setState(() {
      _rooms = rooms;
    });
    _checkInitialHumidity();
  }

  void _listenToRoomChanges() {
    Query roomsQuery = FirebaseDatabase.instance
        .ref()
        .child('rooms')
        .orderByChild('museum')
        .equalTo(widget.museum);

    roomsQuery.onChildChanged.listen((event) {
      var room = event.snapshot.value as Map<dynamic, dynamic>;
      if (room['currentHumidity'] > room['maxHumidity']) {
        _addNotification('Humidity exceeded in ${room['name']}');
      }
      if(room['movement']){
        _addNotification('Movement in ${room['name']}');
      }
    });

    roomsQuery.onChildRemoved.listen((event) {
      var room = event.snapshot.value as Map<dynamic, dynamic>;
      _removeRoom(room);
    });
  }

  void _checkInitialHumidity() async {
    for (var room in _rooms) {
      if (room['currentHumidity'] > room['maxHumidity']) {
        _addNotification('Humidity exceeded in ${room['name']}');
      }
      if (room['movement']) {
        _addNotification('Movement in ${room['name']}');
      }
    }
  }

  void _addNotification(String message) {
    setState(() {
      _notifications.insert(0, {
        'message': message,
        'dateTime': DateTime.now().toString(),
      });
      if (_notifications.length > 3) {
        _notifications.removeLast();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _removeRoom(Map<dynamic, dynamic> room) {
    setState(() {
      _rooms.removeWhere((r) => r['name'] == room['name']);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room ${room['name']} has been removed'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _logout(BuildContext context) async {
    localStorage.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _showCreateRoomModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: CreateRoomForm(
            username: widget.username,
            museum: widget.museum,
            role: widget.role,
            onRoomCreated: (newRoom) {
              setState(() {
                _rooms.add(newRoom);
              });
            },
            existingRoomNames: _rooms.map((room) => room['name'].toString()).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FrameKeeper'),
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
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
      drawer: Drawer(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rooms',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              ..._rooms.map((room) {
                String roomName = room['name'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomDetailPage(
                            roomName: roomName,
                            username: widget.username,
                            museum: widget.museum,
                            role: widget.role,
                          ),
                        ),
                      );
                    },
                    child: Text(roomName),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                );
              }).toList(),
              Spacer(),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MuseumMapPage(
                              username: widget.username,
                              museum: widget.museum,
                              role: widget.role,),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: Text(
                    'View Museum Map',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    _showCreateRoomModal(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text(
                    'Create New Room',
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Image(
                      image: NetworkImage(
                          'https://i.ibb.co/crWgb2V/Captura-de-ecr-2024-05-10-121307-removebg-preview.png'),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Welcome Back\n${widget.username}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Last Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              ..._notifications.map((notification) {
                return NotificationTile(
                  message: notification['message']!,
                  dateTime: notification['dateTime']!,
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final String message;
  final String dateTime;

  NotificationTile({required this.message, required this.dateTime});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(message),
        subtitle: Text(dateTime),
        trailing: Icon(Icons.notifications),
      ),
    );
  }
}

class CreateRoomForm extends StatefulWidget {
  final String username;
  final String museum;
  final String role;
  final Function(Map<String, dynamic>) onRoomCreated;
  final List<String> existingRoomNames;
  CreateRoomForm({
    required this.username,
    required this.museum,
    required this.role,
    required this.existingRoomNames,
    required this.onRoomCreated,
  });

  @override
  _CreateRoomFormState createState() => _CreateRoomFormState();
}

class _CreateRoomFormState extends State<CreateRoomForm> {
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _maxHumidityController = TextEditingController();

  void _createRoom() async {
    String roomName = _roomNameController.text;
    String maxHumidityStr = _maxHumidityController.text;

    if (roomName.isNotEmpty && maxHumidityStr.isNotEmpty) {
      if (widget.existingRoomNames.contains(roomName)) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room name already exists. Please choose a different name.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      double? maxHumidity = double.tryParse(maxHumidityStr);
      if (maxHumidity != null) {
        String roomId = roomName + " - " + widget.museum;
        DatabaseReference roomRef = FirebaseDatabase.instance.ref().child('rooms').child(roomId);
        await roomRef.set({
          'name': roomName,
          'museum': widget.museum,
          'role': widget.role,
          'currentHumidity': 0,
          'maxHumidity': maxHumidity,
          'movement': false,
          'breachHistory': {},
          'humidityHistory': {},
          'insertedBy': widget.username,
          'lastSecurityBreach': 'Never',
          'roomId': roomId,
          'fan': true
        });

        widget.onRoomCreated({
          'name': roomName,
          'museum': widget.museum,
          'role': widget.role,
          'currentHumidity': 0,
          'maxHumidity': maxHumidity,
          'movement': false,
          'breachHistory': {},
          'humidityHistory': {},
          'insertedBy': widget.username,
          'lastSecurityBreach': 'Never',
          'roomId': roomId,
          'fan': true
        });

        Navigator.pop(context);
      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a valid max humidity value.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _roomNameController,
            decoration: InputDecoration(labelText: 'Room Name'),
          ),
          TextField(
            controller: _maxHumidityController,
            decoration: InputDecoration(labelText: 'Max Humidity'),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _createRoom,
            child: Text('Create Room'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:localstorage/localstorage.dart';
import 'login_page.dart';
import 'package:intl/intl.dart';
import 'history_graph.dart';

class HistoryPage extends StatefulWidget {
  final String username;
  final String roomName;
  final String museum;

  HistoryPage({required this.username, required this.roomName, required this.museum});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _selectedTab = 'Humidity';
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _breachHistory = [];
  bool _hasBreachHistory = false;

  void _logout(BuildContext context) async {
    localStorage.clear();


    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initialDate = isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now();
    final DateTime firstDate = isStartDate ? DateTime(2000) : (_startDate ?? DateTime(2000));
    final DateTime lastDate = isStartDate ? DateTime(2101) : DateTime(2101);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _fetchBreachHistory() async {
    Query roomRef = FirebaseDatabase.instance
        .ref()
        .child('rooms')
        .orderByChild('name')
        .equalTo(widget.roomName);

    DataSnapshot snapshot = await roomRef.once().then((event) => event.snapshot);
    if (snapshot.exists) {
      Map<dynamic, dynamic> roomsMap = snapshot.value as Map<dynamic, dynamic>;
      Map<dynamic, dynamic> room = roomsMap.values.first as Map<dynamic, dynamic>;

      Map<dynamic, dynamic>? rawHistoryMap = room['breachHistory'] as Map<dynamic, dynamic>?;
      List<String> breachHistory = rawHistoryMap != null ? rawHistoryMap.values.map((entry) => entry.toString()).toList() : [];

      setState(() {
        _breachHistory = breachHistory;
        _hasBreachHistory = breachHistory.isNotEmpty;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchBreachHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Choose what you want to see:',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 10.0),
            ToggleButtons(
              isSelected: [_selectedTab == 'Humidity', _selectedTab == 'Security'],
              onPressed: (int index) {
                if (index == 1 && !_hasBreachHistory) {

                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Alert'),
                        content: Text('No security breach history available for this room.'),
                        actions: [
                          TextButton(
                            child: Text('OK'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                  return;
                }
                setState(() {
                  _selectedTab = index == 0 ? 'Humidity' : 'Security';
                  if (_selectedTab == 'Security' && _hasBreachHistory) {
                    _fetchBreachHistory();
                  }
                });
              },
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Humidity'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Security'),
                ),
              ],
            ),
            if (_selectedTab == 'Humidity') ...[
              SizedBox(height: 20.0),
              Text(
                'Choose start Date:',
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(height: 10.0),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: _startDate == null
                            ? 'dd-mm-yyyy'
                            : DateFormat('dd-MM-yyyy').format(_startDate!),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () {
                            _selectDate(context, true);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Text(
                'Choose end Date:',
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(height: 10.0),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: _endDate == null
                            ? 'dd-mm-yyyy'
                            : DateFormat('dd-MM-yyyy').format(_endDate!),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () {
                            _selectDate(context, false);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(),
              ElevatedButton(
                onPressed: (_startDate != null && _endDate != null)
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HumidityGraphPage(
                        username: widget.username,
                        roomName: widget.roomName,
                        museum: widget.museum,
                        startDate: _startDate,
                        endDate: _endDate,
                      ),
                    ),
                  );
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_startDate != null && _endDate != null) ? Colors.blue : Colors.grey,
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(20),
                ),
                child: Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ],
            if (_selectedTab == 'Security') ...[
              if (_breachHistory.isNotEmpty) ...[
                SizedBox(height: 20.0),
                Text(
                  'Security Breach History:',
                  style: TextStyle(fontSize: 16.0),
                ),
                SizedBox(height: 10.0),
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('Date')),
                      ],
                      rows: _breachHistory.map<DataRow>((breach) {
                        return DataRow(cells: [
                          DataCell(Text(breach)),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(height: 20.0),
                Text(
                  'No security breaches recorded.',
                  style: TextStyle(fontSize: 16.0),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

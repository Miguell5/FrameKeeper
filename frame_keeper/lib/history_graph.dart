import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class HumidityGraphPage extends StatefulWidget {
  final String username;
  final String roomName;
  final String museum;
  final DateTime? startDate;
  final DateTime? endDate;

  HumidityGraphPage({
    required this.username,
    required this.roomName,
    required this.museum,
    required this.startDate,
    required this.endDate,
  });

  @override
  _HumidityGraphPageState createState() => _HumidityGraphPageState();
}

class _HumidityGraphPageState extends State<HumidityGraphPage> {
  List<Map<String, dynamic>> _humidityHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchHumidityHistory();
  }

  Future<void> _fetchHumidityHistory() async {
    Query roomRef = FirebaseDatabase.instance
        .ref()
        .child('rooms')
        .orderByChild('name')
        .equalTo(widget.roomName);

    DatabaseEvent event = await roomRef.once();
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.exists) {
      Map<dynamic, dynamic> roomsMap = snapshot.value as Map<dynamic, dynamic>;
      Map<dynamic, dynamic> room = roomsMap.values.first as Map<dynamic, dynamic>;

      Map<dynamic, dynamic> rawHistoryMap = room['humidityHistory'] as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> parsedHistory = rawHistoryMap.values.map((entry) {
        List<String> parts = entry.split(' ');
        String dateStr = parts[0];
        String timeStr = parts[1];
        double humidity = double.parse(parts[2]);

        DateTime dateTime = DateFormat('dd-MM-yyyy HH:mm').parse('$dateStr $timeStr');
        return {
          'dateTime': dateTime,
          'humidity': humidity,
        };
      }).toList();

      List<Map<String, dynamic>> filteredHistory = parsedHistory.where((entry) {
        final DateTime dateTime = entry['dateTime'];
        final bool afterStartDate = widget.startDate == null || dateTime.isAfter(widget.startDate!) || dateTime.isAtSameMomentAs(widget.startDate!);
        final bool beforeEndDate = widget.endDate == null || dateTime.isBefore(widget.endDate!) || dateTime.isAtSameMomentAs(widget.endDate!);
        return afterStartDate && beforeEndDate;
      }).toList();

      setState(() {
        _humidityHistory = filteredHistory;
      });
    }
  }


  void _showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Humidity Graph'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _humidityHistory.isEmpty
            ? Center(child: CircularProgressIndicator())
            : LineChart(
          LineChartData(
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 10,
                  getTitlesWidget: (value, meta) {
                    return Text('${value.toInt()}%');
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: true),
            minY: 0,
            maxY: 100,
            lineBarsData: [
              LineChartBarData(
                spots: _humidityHistory.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value['humidity']);
                }).toList(),
                isCurved: true,
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                barWidth: 4,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(show: false),
                dotData: FlDotData(show: true),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((touchedSpot) {
                    final dataPoint = _humidityHistory[touchedSpot.x.toInt()];
                    final dateTime = dataPoint['dateTime'];
                    final formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
                    final humidity = dataPoint['humidity'];
                    return LineTooltipItem(
                      '$formattedDate\nHumidity: $humidity%',
                      const TextStyle(color: Colors.white),
                    );
                  }).toList();
                },
              ),
              handleBuiltInTouches: true,
            ),
          ),
        ),
      ),
    );
  }
}

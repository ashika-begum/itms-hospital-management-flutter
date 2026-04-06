import 'package:flutter/material.dart';

class TransportRequest {
  final String id;
  final String patientName;
  final String fromLocation;
  final String toLocation;
  final String priority; // 'High', 'Medium', 'Low'
  final DateTime requestTime;

  TransportRequest({
    required this.id,
    required this.patientName,
    required this.fromLocation,
    required this.toLocation,
    required this.priority,
    required this.requestTime,
  });
}

class TransportRequestHandler {
  final List<TransportRequest> requests = [];

  void addRequest(TransportRequest request) {
    requests.add(request);
    _sortByPriority();
  }

  void _sortByPriority() {
    const priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};
    requests.sort((a, b) => (priorityOrder[a.priority] ?? 99)
        .compareTo(priorityOrder[b.priority] ?? 99));
  }

  void acceptRequest(String requestId) {
    requests.removeWhere((r) => r.id == requestId);
  }

  void rejectRequest(String requestId) {
    requests.removeWhere((r) => r.id == requestId);
  }

  List<TransportRequest> getRequests() => requests;
}

class PorterDashboardStatic extends StatefulWidget {
  @override
  State<PorterDashboardStatic> createState() => _PorterDashboardStaticState();
}

class _PorterDashboardStaticState extends State<PorterDashboardStatic> {
  final TransportRequestHandler handler = TransportRequestHandler();

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transport Requests')),
      body: ListView.builder(
        itemCount: handler.getRequests().length,
        itemBuilder: (context, index) {
          final request = handler.getRequests()[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text(request.patientName),
              subtitle: Text('${request.fromLocation} → ${request.toLocation}'),
              leading: CircleAvatar(
                backgroundColor: _getPriorityColor(request.priority),
                child: Text(request.priority[0]),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      handler.acceptRequest(request.id);
                      setState(() {});
                    },
                    child: Text('Accept'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      handler.rejectRequest(request.id);
                      setState(() {});
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text('Reject'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

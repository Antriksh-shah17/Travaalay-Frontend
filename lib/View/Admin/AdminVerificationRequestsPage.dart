import 'package:flutter/material.dart';

class AdminVerificationRequestsPage extends StatelessWidget {
  const AdminVerificationRequestsPage({super.key});

  final List<Map<String, dynamic>> requests = const [
    {
      "id": 1,
      "translatorName": "Translator Shah",
      "documents": [
        {"type": "ID Proof", "status": "pending"},
        {"type": "Certificate", "status": "pending"}
      ],
      "status": "pending"
    }
  ];

  Color getStatusColor(String status) {
    switch (status) {
      case "approved": return Colors.green;
      case "rejected": return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request['translatorName'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...request['documents'].map<Widget>((doc) => Text("${doc['type']}: ${doc['status']}")),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text("Approve"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text("Reject"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

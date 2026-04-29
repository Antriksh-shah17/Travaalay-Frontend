import 'package:flutter/material.dart';

class AdminTranslatorsPage extends StatelessWidget {
  const AdminTranslatorsPage({super.key});

  final List<Map<String, dynamic>> translators = const [
    {
      "id": 3,
      "name": "Gauri KKshirsagar",
      "email": "translator@gmail.com",
      "city": "Ahmedabad",
      "languages": ["English", "Hindi"],
      "verified": true,
      "profileImage": "Gauri.jpeg"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: translators.length,
      itemBuilder: (context, index) {
        final translator = translators[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(translator['profileImage']),
            ),
            title: Text(translator['name']),
            subtitle: Text("${translator['email']} | ${translator['city']}"),
            trailing: translator['verified']
                ? const Icon(Icons.verified, color: Colors.green)
                : const Icon(Icons.pending, color: Colors.orange),
          ),
        );
      },
    );
  }
}

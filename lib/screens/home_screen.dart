import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/new_read_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido'),
        actions: [
          DropdownButton(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).primaryIconTheme.color,
            ),
            items: [
              DropdownMenuItem(
                child: Container(
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app),
                      SizedBox(width: 8),
                      Text('Cerrar sesión'),
                    ],
                  ),
                ),
                value: 'logout',
              ),
            ],
            onChanged: (itemIdentifier) {
              if (itemIdentifier == 'logout') {
                FirebaseAuth.instance.signOut();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Card(
              color: Theme.of(context).primaryColor,
              child: Container(
                width: double.infinity,
                height: 100,
                child: Column(
                  children: [
                    Text(
                      'Consumo Actual',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize:
                            Theme.of(context).textTheme.headline4.fontSize,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '300',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize:
                            Theme.of(context).textTheme.headline4.fontSize,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: Firestore.instance
                    .collection('reads')
                    .orderBy('readDate', descending: true)
                    .snapshots(),
                builder: (context, chatSnapshot) {
                  if (chatSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final readsDocs = chatSnapshot.data.documents;

                  return ListView.builder(
                    itemCount: readsDocs.length,
                    itemBuilder: (ctx, index) => ListTile(
                      title: Text(readsDocs[index]['read']),
                      subtitle: Text(
                        DateTime.parse(readsDocs[index]['readDate'].toString())
                            .toString(),
                      ),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          NewReadScreen.routeName,
                          arguments: {
                            'read': readsDocs[index]['read'],
                            'readDate': readsDocs[index]['readDate'],
                            'readDocumentId': readsDocs[index].documentID,
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          Navigator.of(context).pushNamed(NewReadScreen.routeName);
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

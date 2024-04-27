import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_artwork_screen.dart';
import 'profile_screen.dart';
import 'artwork_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> filteredArtworks = [];
  Key _refreshKey = UniqueKey();

  void _handleLocaleChanged() => setState(() {
        _refreshKey = UniqueKey();
      });

  @override
  void initState() {
    super.initState();
    getAllArts();
  }

  Future<List<Object?>> getAllArts() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('arts').get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _refreshKey,
      appBar: AppBar(
        title: const PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Text("Home"),
        ),
      ),
      body: FutureBuilder(
        future: getAllArts(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
              ),
              itemCount: snapshot.data?.length,
              itemBuilder: (context, index) {
                final artwork = snapshot.data?[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ArtworkDetailScreen(artwork: artwork),
                      ),
                    );
                  },
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: Image.network(
                          (artwork as Map)['imageUrl']!,
                          fit: BoxFit.cover,
                        )),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                artwork['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              padding: const EdgeInsets.only(bottom: 70.0),
            );
          }
          return const CircularProgressIndicator();
        },
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 25)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home page'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SettingsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Profile'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const ProfileScreen()));
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddArtworkScreen()),
          ).then((value) => _handleLocaleChanged());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

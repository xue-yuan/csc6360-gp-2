import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ArtworkDetailScreen extends StatefulWidget {
  final Object? artwork;

  const ArtworkDetailScreen({super.key, required this.artwork});

  @override
  State<ArtworkDetailScreen> createState() => _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends State<ArtworkDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Widget _buildArtworkImage() {
    return Image.network(
      (widget.artwork as Map)['imageUrl'],
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text((widget.artwork as Map)['title']),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildArtworkImage(),
            const SizedBox(height: 16),
            Text(
              'Artist: ${(widget.artwork as Map)['artist']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${(widget.artwork as Map)['email'] ?? 'Not Provided'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Title: ${(widget.artwork as Map)['title'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Description: ${(widget.artwork as Map)['description'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder(
                stream: _firestore
                    .collection('comments')
                    .where('artworkId',
                        isEqualTo: (widget.artwork as Map)['id'])
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final comments = snapshot.data?.docs ?? [];

                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final timestamp = comment['timestamp'] as Timestamp;
                      final dateTime = timestamp.toDate();

                      return ListTile(
                        title: Text(comment['content']),
                        subtitle: Text(
                            'By: ${comment['username']} • ${DateFormat('yyyy-MM-dd HH:mm').format(dateTime)}'),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Add a comment',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _addComment();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();

    if (content.isEmpty) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? 'Anonymous';

    final commentData = {
      'artworkId': (widget.artwork as Map)['id'],
      'username': username,
      'content': content,
      'timestamp': Timestamp.now(),
    };

    try {
      await _firestore.collection('comments').add(commentData);
      _commentController.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add comment')),
        );
      }
    }
  }
}

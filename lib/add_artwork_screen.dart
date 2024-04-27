import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddArtworkScreen extends StatefulWidget {
  const AddArtworkScreen({super.key});

  @override
  State<AddArtworkScreen> createState() => _AddArtworkScreenState();
}

class _AddArtworkScreenState extends State<AddArtworkScreen> {
  File? _imageFile;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _addArtwork(BuildContext context) async {
    String title = _titleController.text;
    String description = _descriptionController.text;
    String username = '';

    final User user = _auth.currentUser!;
    final storageReference = FirebaseStorage.instance
        .ref()
        .child('images/${DateTime.now().toString()}');

    Uint8List imageData = File(_imageFile!.path).readAsBytesSync();
    UploadTask uploadTask = storageReference.putData(imageData);

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        setState(() {
          username = snapshot.data()!['name'];
        });
      }
    });

    try {
      await uploadTask.whenComplete(() async {
        String imageUrl = await storageReference.getDownloadURL();

        await FirebaseFirestore.instance.collection('arts').add({
          'title': title,
          'description': description,
          'imageUrl': imageUrl,
          'uid': user.uid,
          'likes': 0,
          'artist': username,
          'email': user.email,
        }).then((value) {
          _titleController.clear();
          _descriptionController.clear();
          setState(() {
            _imageFile = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data uploaded successfully!'),
            ),
          );
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload data: $error'),
            ),
          );
        });
      });
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload data: $e'),
          ),
        );
      }
    }
  }

  Future<void> _getImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Artwork'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _getImage,
              child: const Text('Select Image'),
            ),
            const SizedBox(height: 16.0),
            _imageFile == null
                ? const Text('No image selected.')
                : Image.file(
                    _imageFile!,
                    height: 150,
                  ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: null,
            ),
            const SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: () {
                _addArtwork(context);
              },
              child: const Text('Add Artwork'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

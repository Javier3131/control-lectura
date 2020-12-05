import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// import '../widgets/pickers/read_image_picker.dart';
import 'package:image_picker/image_picker.dart';

class NewReadScreen extends StatefulWidget {
  static const routeName = '/new-read';
  @override
  _NewReadScreenState createState() => _NewReadScreenState();
}

class _NewReadScreenState extends State<NewReadScreen> {
  File _pickedImage;
  DateTime _selectedDate = DateTime.now();
  String _read;
  bool _isLoading = false;
  String _documentId;
  TextEditingController _textEditingController = TextEditingController();

  // void _pickedImage(File image) {
  //   _readImageFile = image;
  // }

  void _pickImage(ImageSource imageSource) async {
    final picker = ImagePicker();
    final pickedImage = await picker.getImage(source: imageSource);
    final pickedImageFile = File(pickedImage.path);

    setState(() {
      _pickedImage = pickedImageFile;
    });
    // widget.imagePickFn(_pickedImage);
  }

  void _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
      });
  }

  void _saveRead() async {
    try {
      setState(() {
        _isLoading = true;
      });

      FocusScope.of(context).unfocus();
      final userId = await FirebaseAuth.instance.currentUser();
      await Firestore.instance.collection('reads').add({
        'read': _read,
        'readDate': _selectedDate.toIso8601String(),
        'createdAt': Timestamp.now(),
        'userId': userId.uid,
      });

      setState(() {
        _isLoading = false;
      });

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text('Sucedio un error al guardar la lectura.'),
        backgroundColor: Theme.of(context).errorColor,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Object> arg = ModalRoute.of(context).settings.arguments;

    setState(() {
      if (arg != null) {
        _read = arg['read'];
        _textEditingController.text = arg['read'];
        _selectedDate = DateTime.parse(arg['readDate'].toString());
        _documentId = arg['documentId'];
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Nueva Lectura'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveRead,
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _textEditingController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Lectura'),
                      onChanged: (value) {
                        setState(() {
                          _read = value;
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      title: Text(_selectedDate.toString()),
                      onTap: () {
                        _selectDate(context);
                      },
                      trailing: Icon(Icons.date_range),
                    ),
                    SizedBox(height: 10),
                    if (_pickedImage != null)
                      Container(
                        width: double.infinity,
                        child: Image.file(_pickedImage),
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          showDialog(
              context: context,
              child: SimpleDialog(
                children: [
                  SimpleDialogOption(
                    child: ListTile(
                      leading: Icon(Icons.camera_alt),
                      title: Text('Usar la Camara'),
                      onTap: () {
                        _pickImage(ImageSource.camera);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  SimpleDialogOption(
                    child: ListTile(
                      leading: Icon(Icons.photo),
                      title: Text('Seleccionar de Galeria'),
                      onTap: () {
                        _pickImage(ImageSource.gallery);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ));
        },
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}

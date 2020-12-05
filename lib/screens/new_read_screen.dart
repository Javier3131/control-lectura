import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  String _imageUrl = '';
  TextEditingController _textEditingController = TextEditingController();

  // void _pickedImage(File image) {
  //   _readImageFile = image;
  // }

  void _pickImage(ImageSource imageSource) async {
    final picker = ImagePicker();
    final pickedImage = await picker.getImage(source: imageSource);
    if (pickedImage == null) {
      return;
    }
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

  _saveImage(String documentId, File image) async {
    StorageReference storageReference =
        FirebaseStorage.instance.ref().child('reads/$documentId');
    StorageUploadTask uploadTask = storageReference.putFile(image);

    final StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);
    final String url = (await downloadUrl.ref.getDownloadURL());

    return url;
  }

  void _updateReadImage(String documentId, String imageUrl) async {
    await Firestore.instance.collection('reads').document(documentId).setData(
      {'imageUrl': imageUrl},
      merge: true,
    );
  }

  void _updateRead() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await Firestore.instance
          .collection('reads')
          .document(_documentId)
          .setData(
        {
          'read': _read,
          'readDate': _selectedDate.toIso8601String(),
          'imageUrl': _imageUrl,
        },
        merge: true,
      );

      if (_pickedImage != null) {
        String imageUrl = await _saveImage(_documentId, _pickedImage);
        _updateReadImage(_documentId, imageUrl);
      }

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

  void _saveRead() async {
    try {
      setState(() {
        _isLoading = true;
      });

      FocusScope.of(context).unfocus();
      final userId = await FirebaseAuth.instance.currentUser();
      DocumentReference documentReference =
          await Firestore.instance.collection('reads').add({
        'read': _read,
        'readDate': _selectedDate.toIso8601String(),
        'createdAt': Timestamp.now(),
        'userId': userId.uid,
      });

      String documentId = documentReference.documentID;
      if (_pickedImage != null) {
        String imageUrl = await _saveImage(documentId, _pickedImage);
        _updateReadImage(documentId, imageUrl);
      }

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

  void _deleteImage() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (_documentId != null && _imageUrl.isNotEmpty) {
        setState(() {
          _imageUrl = '';
        });
        await FirebaseStorage.instance
            .ref()
            .child('reads/$_documentId')
            .delete();

        await Firestore.instance
            .collection('reads')
            .document(_documentId)
            .setData(
          {
            'imageUrl': '',
          },
          merge: true,
        );
      }

      if (_pickedImage != null) {
        setState(() {
          _pickedImage = null;
        });
      }

      setState(() {
        _isLoading = false;
      });
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
  void didChangeDependencies() {
    final Map<String, Object> arg = ModalRoute.of(context).settings.arguments;
    if (arg != null) {
      _read = arg['read'];
      _textEditingController.text = arg['read'];
      _selectedDate = DateTime.parse(arg['readDate'].toString());
      _documentId = arg['documentId'];
      _imageUrl = arg['imageUrl'];
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nueva Lectura'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _documentId == null ? _saveRead : _updateRead,
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
                    if (_pickedImage != null && _imageUrl.isEmpty)
                      Container(
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Image.file(_pickedImage),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: _deleteImage,
                                  color: Theme.of(context).errorColor,
                                  iconSize: 64.0,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (_imageUrl.isNotEmpty)
                      Container(
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Image.network(_imageUrl),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: _deleteImage,
                                  color: Theme.of(context).errorColor,
                                  iconSize: 64.0,
                                ),
                              ],
                            ),
                          ],
                        ),
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

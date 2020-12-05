import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReadImagePicker extends StatefulWidget {
  ReadImagePicker(this.imagePickFn);

  final void Function(File pickedImage) imagePickFn;

  @override
  _ReadImagePickerState createState() => _ReadImagePickerState();
}

class _ReadImagePickerState extends State<ReadImagePicker> {
  File _pickedImage;

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.getImage(source: ImageSource.camera);
    final pickedImageFile = File(pickedImage.path);

    setState(() {
      _pickedImage = pickedImageFile;
    });
    widget.imagePickFn(_pickedImage);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // CircleAvatar(
        //   radius: 50,
        //   backgroundColor: Colors.grey,
        //   backgroundImage:
        //       _pickedImage != null ? FileImage(_pickedImage) : null,
        // ),
        if (_pickedImage != null)
          Container(
            width: double.infinity,
            height: 200.0,
            decoration: BoxDecoration(
              color: Colors.grey,
            ),
            child: Image(
              image: _pickedImage != null ? FileImage(_pickedImage) : null,
            ),
          ),
        FlatButton.icon(
          textColor: Theme.of(context).primaryColor,
          onPressed: _pickImage,
          icon: Icon(Icons.image),
          label: Text('Add Image'),
        ),
      ],
    );
  }
}

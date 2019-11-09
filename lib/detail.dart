import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:io';

Firestore db = Firestore.instance;

class Detail extends StatefulWidget {
  Detail({ this.filePath });
  final String filePath;

  @override
  _DetailState createState() => _DetailState(filePath: filePath);
}

class _DetailState extends State<Detail> {

  _DetailState({ this.filePath });
  final String filePath;

  List<String> labelResults = List();

  void _labelImage() async {
    File imageFile = File(filePath);
    final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(imageFile);
    final ImageLabeler labeler = FirebaseVision.instance.imageLabeler();
    final List<ImageLabel> labels = await labeler.processImage(visionImage);

    List<String> currentLabelResults = List();
    String labelResult = '';
  
    for (ImageLabel label in labels) {
      final String text = label.text;
      final double confidence = label.confidence;
      labelResult += text + ', ';
      currentLabelResults.add(text + ',' + confidence.toString());
    }

    // upload image /storage/fadfadf.png
    String fileName = filePath.split('/')[filePath.split('/').length - 1];
    final StorageReference storageReference = FirebaseStorage().ref().child('new_image/$fileName');
    final StorageUploadTask uploadTask = storageReference.putFile(imageFile);
    await uploadTask.onComplete;

    String fileURL = await storageReference.getDownloadURL();
    String bucketName = await storageReference.getBucket();
    String storageFilePath = await storageReference.getPath();
    String gsPath = 'gs://$bucketName/$storageFilePath';

    db.collection('results').add({
      'fileURL': fileURL,
      'gsPath': gsPath,
      'labelResult': labelResult.trim()
    });
  
    setState(() {
      labelResults = currentLabelResults;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _labelImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MLKIT Image Detail')
      ),
      body: Column(
        children: <Widget>[
          Container(
            child: Image.file(File(filePath))
          ),
          Expanded(
            child: ListView.builder(
              itemCount: labelResults.length,
              itemBuilder: (context, index) {
                String name = labelResults[index].split(',')[0];
                double value = double.parse(labelResults[index].split(',')[1]);
                return Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(name),
                      LinearProgressIndicator(
                        value: value
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
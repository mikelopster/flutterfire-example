import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'detail.dart';

Firestore db = Firestore.instance;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home()
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  GoogleMapController _mapController;
  Map<String, Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FlutterFire Example')
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(0, 0),
                zoom: 11
              ),
              markers: _markers.values.toSet(),
            )
          ),
          Expanded(
            child: Container(
              child: StreamBuilder(
                stream: db.collection('results').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Text('Loading...');
                  }

                  final snapshotData = snapshot.data.documents;

                  return ListView.builder(
                    itemCount: snapshotData.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          if (snapshotData[index]['haveLandmark']) {
                            setState(() {
                              _markers['location'] = Marker(
                                markerId: MarkerId('location'),
                                position: LatLng(snapshotData[index]['lat'], snapshotData[index]['lng'])
                              );
                            });
                            
                            _mapController.animateCamera(CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(snapshotData[index]['lat'], snapshotData[index]['lng']),
                                zoom: 10
                              )
                            ));
                          }
                        },
                        child: Card(
                          child: Row(
                            children: <Widget>[
                              Icon(snapshotData[index]['haveLandmark'] ? Icons.pin_drop : null),
                              Image.network(
                                snapshotData[index]['fileURL'],
                                width: 100
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(snapshotData[index]['labelResult']),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              )
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.image),
        onPressed: () async {
          final image = await ImagePicker.pickImage(source: ImageSource.gallery);
          print(image.path);
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => Detail(filePath: image.path)
          ));
        },
      ),
    );
  }
}
import 'dart:io';
import 'package:acharya_capstone/Recommendation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'detect.dart';

class MyCam extends StatefulWidget {
  MyCam({Key? key, required this.cameras, required this.model}) : super(key: key);
  late String model;
  late List<CameraDescription> cameras;


  @override
  State<MyCam> createState() => _MyCamState();
}

class _MyCamState extends State<MyCam> {
  late CameraController _cameraController;
  bool _isRearCameraSelected = true;
  late Detection detection;
  late String prediction;
  List<String> items = [];

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    detection = Detection(widget.model);
    initCamera(widget.cameras![0]);
  }

  Future takePicture() async {
    if (!_cameraController.value.isInitialized) {
      return null;
    }
    if (_cameraController.value.isTakingPicture) {
      return null;
    }
    try {
      await _cameraController.setFlashMode(FlashMode.off);
      XFile picture = await _cameraController.takePicture();
      print("Picture path: "+picture.path);
      prediction = await detection.detect(picture);
      _showPopupDialog(context);
      /*Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  PreviewPage(
                    picture: picture,
                  )));*/
    } on CameraException catch (e) {
      debugPrint('Error occured while taking picture: $e');
      return null;
    }
  }

  void done(){
    items.add(prediction);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                PreviewPage(
                  items: items,
                )));
  }

  void addMore(){
    items.add(prediction);
  }

  void _showPopupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Vegetable detected'),
          content: Text(prediction),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Retry'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop;
                done();
              },
              child: Text('Done'),
            ),
            ElevatedButton(
              onPressed: () {
                addMore();
                Navigator.of(context).pop();
              },
              child: Text('Add More'),
            ),
          ],
        );
      },
    );
  }

  Future initCamera(CameraDescription cameraDescription) async {
    _cameraController =
        CameraController(cameraDescription, ResolutionPreset.high);
    try {
      await _cameraController.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      });
    } on CameraException catch (e) {
      debugPrint("camera error $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: Stack(children: [
            (_cameraController.value.isInitialized)
                ? CameraPreview(_cameraController)
                : Container(
                color: Colors.black,
                child: const Center(child: CircularProgressIndicator())),
            Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: MediaQuery
                      .of(context)
                      .size
                      .height * 0.20,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24)),
                      color: Colors.black),
                  child:
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 30,
                          icon: Icon(
                              _isRearCameraSelected
                                  ? CupertinoIcons.switch_camera
                                  : CupertinoIcons.switch_camera_solid,
                              color: Colors.white),
                          onPressed: () {
                            setState(
                                    () =>
                                _isRearCameraSelected = !_isRearCameraSelected);
                            initCamera(widget.cameras![_isRearCameraSelected
                                ? 0
                                : 1]);
                          },
                        )),
                    Expanded(
                        child: IconButton(
                          onPressed: takePicture,
                          iconSize: 50,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.circle, color: Colors.white),
                        )),
                    const Spacer(),
                  ]),
                )),
          ]),
        ));
  }
}

class PreviewPage extends StatefulWidget {
  PreviewPage({Key? key, required this.items}) : super(key: key);
  final List<String> items;

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}
class _PreviewPageState extends State<PreviewPage>{
  late List<String> items;
  @override
  void initState() {
    super.initState();
    items = widget.items;
  }
  TextEditingController newItemController = TextEditingController();

  void addNewItem() {
    String newItem = newItemController.text;
    if (newItem.isNotEmpty) {
      setState(() {
        items.add(newItem);
      });
      newItemController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(data: ThemeData.dark(),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: <Widget>[
              Image.asset(
                'assets/ic_launcher.png',
                width: 40,
                height: 40,
              ),
              SizedBox(width: 8),
              Text('CARROT', selectionColor: Colors.deepPurpleAccent,),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent, // Make the AppBar transparent
          elevation: 0, // Remove the AppBar shadow
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: CardListView(items),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: newItemController,
                      decoration: InputDecoration(labelText: 'Enter Item'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: addNewItem,
                    child: Text('Add Item'),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if(items.length<2){
                  Fluttertoast.showToast(
                      msg: "Please add atleast 2 items",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      fontSize: 16.0
                  );
                }
                else{
                Navigator.push(context, MaterialPageRoute(builder: (context) => Recommendation(items: items,)));
                print('Submitted items: $items');}
              },
              child: Text('Recommend'),
            ),
          ],
        ),
      )
    );
  }
}

class CardListView extends StatelessWidget {
  final List<String> itemList;

  CardListView(this.itemList);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemList.length,
      itemBuilder: (context, index) {
        return CardItem(itemList[index]);
      },
    );
  }
}

class CardItem extends StatelessWidget {
  final String text;

  CardItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(text),
      ),
    );
  }
}
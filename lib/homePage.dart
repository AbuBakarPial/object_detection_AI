import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';

import 'main.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CameraController cameraController;
  CameraImage cameraImage;
  bool isWorking = false;
  double imgHeight;
  double imgWidth;
  List recognitionList;

  initCamera() {
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    cameraController.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        cameraController.startImageStream((image) => {
              if (!isWorking)
                {
                  isWorking = true,
                  cameraImage = image,
                  runModel(),
                }
            });
      });
    });
  }

  runModel() async {
    imgHeight = cameraImage.height + 0.0;
    imgWidth = cameraImage.width + 0.0;
    recognitionList = await Tflite.detectObjectOnFrame(
        model: "SSDMobileNet",
        bytesList: cameraImage.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        imageMean: 127.0,
        imageStd: 127.0,
        numResultsPerClass: 1,
        threshold: 0.4);
    isWorking = false;
    setState(() {
      cameraImage;
    });
  }

  Future loadModel() async {
    Tflite.close();
    try {
      String response;
      response = await Tflite.loadModel(
          model: "assets/ssd_mobilenet.tflite",
          labels: "assets/ssd_mobilenet.txt");
      print(response);
    } on PlatformException {
      print("unable to load model");
    }
  }

  @override
  void dispose() {
    super.dispose();
    cameraController.stopImageStream();
    Tflite.close();
  }

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  List<Widget> displayBoxes(Size screen) {
    if (recognitionList == null) return [];
    if (imgHeight == null || imgWidth == null) return [];

    double factorX = screen.width;
    double factorY = screen.height;
    Color color = Colors.amberAccent;
    return recognitionList.map((result) {
      return Positioned(
        left: result["rect"]["x"] * factorX,
        top: result["rect"]["y"] * factorY,
        width: result["rect"]["w"] * factorX,
        height: result["rect"]["h"] * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.amberAccent, width: 2.0),
          ),
          child: Text(
            "${result['detected class']} ${(result['confidence in class'] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = color,
              color: color,
              fontSize: 16.0,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> stackChildren = [];
    stackChildren.add(Positioned(
      top: 0.0,
      left: 0.0,
      width: size.width,
      height: size.height - 100,
      child: Container(
        height: size.height - 100,
        child: (!cameraController.value.isInitialized)
            ? new Container()
            : AspectRatio(
                aspectRatio: cameraController.value.aspectRatio,
                child: CameraPreview(cameraController),
              ),
      ),
    ));
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          margin: EdgeInsets.only(top: 50.0),
          color: Colors.black,
          child: Stack(
            children: stackChildren,
          ),
        ),
      ),
    );
  }
}

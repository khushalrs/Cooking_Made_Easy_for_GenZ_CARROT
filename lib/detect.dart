import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:cross_file_image/cross_file_image.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class Detection {
  String modelPath = '';
  late Interpreter interpreter;
  InterpreterOptions _interpreterOptions = InterpreterOptions();
  late File path;

  final labels = ['beetroot', 'bell pepper', 'cabbage', 'capsicum', 'carrot', 'cauliflower', 'chilli pepper',
    'corn', 'cucumber', 'garlic', 'ginger', 'lemon', 'lettuce', 'onion', 'peas', 'potato', 'spinach', 'tomato', 'turnip'];

  late List<int> _inputShape;
  late List<int> _outputShape;

  late TensorBuffer _outputBuffer;

  @override
  NormalizeOp get preProcessNormalizeOp => NormalizeOp(127.5, 127.5);

  @override
  NormalizeOp get postProcessNormalizeOp => NormalizeOp(0, 1);

  late TfLiteType _inputType;
  late TfLiteType _outputType;

  late var _probabilityProcessor;

  Detection(this.modelPath){
    print("Model Name: $modelPath");
    loadModel();
  }

  loadModel() async {
    //String modelPath = 'assets/mobilenet.tflite'; // Update with your model path
    FirebaseCustomModel model = await FirebaseModelDownloader.instance.getModel('vegetable_mobilenetv2', FirebaseModelDownloadType.latestModel);
    print("MODEL: "+model.toString());
    interpreter = await Interpreter.fromFile(model.file);
    /*FirebaseModelDownloader.instance
        .getModel(
        "vegetable_mobilenet",
        FirebaseModelDownloadType.localModel,
        FirebaseModelDownloadConditions(
          iosAllowsCellularAccess: true,
          iosAllowsBackgroundDownloading: false,
          androidChargingRequired: false,
          androidWifiRequired: false,
          androidDeviceIdleRequired: false,
        )
    )
        .then((customModel){
      path = customModel.file;
      interpreter = Interpreter.fromFile(path,options: _interpreterOptions);
      print("Interpreter: "+interpreter.toString());
    });
    //interpreter = await Interpreter.fromFile(path,options: _interpreterOptions);*/
    _inputShape = interpreter.getInputTensor(0).shape;
    _outputShape = interpreter.getOutputTensor(0).shape;
    print('Input Shape:');
    for (int dim in _outputShape) {
      print(dim);
    }
    _inputType = interpreter.getInputTensor(0).type;
    _outputType = interpreter.getOutputTensor(0).type;
    _outputBuffer = TensorBuffer.createFixedSize(_outputShape, _outputType);
  }

  Future<TensorImage> createTensorImage(XFile imageFile) async {
    final bytes = await File(imageFile.path).readAsBytes();
    final img.Image? image = img.decodeImage(bytes);
    TensorImage _inputImage = TensorImage(_inputType);
    _inputImage.loadImage(image!);
    int padSize = max(_inputImage.height, _inputImage.width);
    ImageProcessor imageProcessor = ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(padSize, padSize))
        .add(ResizeOp(224, 224, ResizeMethod.BILINEAR))
        .build();
    _inputImage = imageProcessor.process(_inputImage);
    return _inputImage;
  }

  Future<String> detect(XFile immage) async {
    TensorImage inputImage = TensorImage(_inputType);
    print("INPUT TYPE: "+_inputType.toString());
    inputImage = await createTensorImage(immage);
    int cropSize = min(inputImage.height, inputImage.width);
    TensorImage _inputImage = ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(cropSize, cropSize))
        .add(ResizeOp(224, 224, ResizeMethod.BILINEAR))
        .add(preProcessNormalizeOp)
        .build()
        .process(inputImage);

    print("TENSOR IMAGE: "+inputImage.getBuffer().toString());
    // Run inference
    //_outputBuffer = TensorBuffer.createFixedSize(_outputShape, _outputType);
    //print("OUTPUT SHAPE: "+_outputShape.toString());
    print("OUTPUT TYPE: "+_outputType.toString());
    interpreter.run(_inputImage.buffer, _outputBuffer.getBuffer());

    List<double> outputData = _outputBuffer.getDoubleList();
    print("LIST DATA: "+outputData.toString());
    int maxIndex = outputData.indexOf(outputData.reduce(max));
    String predictedLabel = labels[maxIndex];
    double confidence = outputData[maxIndex];

    print('Predicted Label: $predictedLabel, Confidence: $confidence');
    return predictedLabel;
  }

}
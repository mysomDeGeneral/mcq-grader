import 'package:camera/camera.dart';

class CameraService {
  CameraController? controller;
  List<CameraDescription> cameras = [];

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.high);
    await controller!.initialize();
  }

  void dispose() {
    controller?.dispose();
  }
}
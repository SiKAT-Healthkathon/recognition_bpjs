import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:bpjs_recognition/models/response_model.dart';
import 'package:bpjs_recognition/models/user_model.dart';
import 'package:bpjs_recognition/services/user_services.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:image/image.dart' as img;

import 'shared/theme.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['YOUR_SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['YOUR_SUPABASE_ANON_KEY'] ?? '',
  );
  _cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  late WebSocketChannel channel;
  ResponseModel _response = const ResponseModel(
      status: DetectionStatus.noFace, message: '', data: null);
  UserModel? _user =
      const UserModel(nik: '', name: '', photo: '', checkInAt: null);

  @override
  void initState() {
    super.initState();
    initializeCamera();
    initializeWebSocket();
  }

  Future<void> initializeCamera() async {
    final firstCamera = _cameras[1]; // back 0th index & front 1st index

    controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller!.initialize();
    setState(() {});

    Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final image = await controller!.takePicture();
        final compressedImageBytes = compressImage(image.path);
        channel.sink.add(compressedImageBytes);
      } catch (_) {}
    });
  }

  void initializeWebSocket() {
    // 0.0.0.0 -> 10.0.2.2 (emulator)
    channel = IOWebSocketChannel.connect('ws://192.168.100.9:8765');
    channel.stream.listen((dynamic data) async {
      try {
        debugPrint(data);
        final jsonData = jsonDecode(data);
        setState(() {
          _response = ResponseModel.fromJson(jsonData);
        });

        if (_response.status == DetectionStatus.success) {
          _user = await UserServices.getUserData(nik: _response.data!);
          setState(() {});
        }
      } catch (e) {
        debugPrint('Error processing WebSocket data: $e');
      }
    }, onError: (dynamic error) {
      debugPrint('Error: $error');
    }, onDone: () {
      debugPrint('WebSocket connection closed');
    });
  }

  Uint8List compressImage(String imagePath, {int quality = 85}) {
    final image =
        img.decodeImage(Uint8List.fromList(File(imagePath).readAsBytesSync()))!;
    final compressedImage =
        img.encodeJpg(image, quality: quality); // lossless compression
    return compressedImage;
  }

  Widget popUp(
      {required bool isSuccess,
      required String message,
      required String title}) {
    return Row(
      children: [
        Image.asset(
          isSuccess ? 'assets/images/success.png' : 'assets/images/fail.png',
          width: 80,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: blackText.copyWith(
                fontWeight: bold,
                fontSize: 20,
              ),
            ),
            SizedBox(
              width: 240,
              child: Text(
                message,
                style: greyText.copyWith(
                  fontWeight: medium,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!(controller?.value.isInitialized ?? false)) {
      return const SizedBox();
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: FittedBox(
                fit: BoxFit.cover, // Ensures the preview fills the screen
                child: SizedBox(
                  width: controller!.value.previewSize!.height,
                  height: controller!.value.previewSize!.width,
                  child: CameraPreview(controller!),
                ),
              ),
            ),
            _response.status == DetectionStatus.noFace
                ? const SizedBox()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: _response.status == DetectionStatus.success
                            ? popUp(
                                isSuccess: true,
                                message: _response.data ?? '',
                                title: _user?.name ?? '')
                            : _response.status == DetectionStatus.fail
                                ? popUp(
                                    isSuccess: false,
                                    message:
                                        'Pastikan Anda Sudah Mendaftar Mobile JKN',
                                    title: 'Wajah tidak dikenali')
                                : const SizedBox(),
                      ),
                    ],
                  )
          ],
        ),
      ),
    );
  }
}

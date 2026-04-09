import 'dart:isolate';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:pose_detection/pose_detection.dart';

import 'pushup_state.dart';

// =====================================================================
//  Worker isolate — runs PoseDetector entirely off the main thread.
// =====================================================================

/// Entry point receives [SendPort, RootIsolateToken] so the worker can
/// initialize Flutter's ServicesBinding (needed for rootBundle / TFLite).
void _poseWorkerEntry(List<dynamic> args) {
  final SendPort mainPort = args[0] as SendPort;
  final token = args[1] as RootIsolateToken;

  // Enable platform channels + plugin registry in this background isolate
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  DartPluginRegistrant.ensureInitialized();

  final workerPort = ReceivePort();
  mainPort.send(workerPort.sendPort);

  PoseDetector? detector;

  workerPort.listen((msg) async {
    if (msg == 'init') {
      try {
        detector = PoseDetector(
          mode: PoseMode.boxesAndLandmarks,
          landmarkModel: PoseLandmarkModel.lite,
          detectorConf: 0.5,
          minLandmarkScore: 0.6,
          maxDetections: 1,
          performanceConfig: const PerformanceConfig.xnnpack(),
        );
        await detector!.initialize();
        mainPort.send('ready');
      } catch (e) {
        mainPort.send('error:$e');
      }
    } else if (msg is List && msg.length == 6) {
      if (detector == null) {
        mainPort.send(null);
        return;
      }
      try {
        final result = await _detectInWorker(detector!, msg);
        mainPort.send(result);
      } catch (_) {
        mainPort.send(null);
      }
    } else if (msg == 'stop') {
      await detector?.dispose();
      detector = null;
      workerPort.close();
      Isolate.exit();
    }
  });
}

/// [msg] = [Uint8List buffer, int w, int h, int colorCode, int matH, int channels]
/// Returns [imgW, imgH, [[typeIndex, x, y, vis], ...]] or null.
Future<List<dynamic>?> _detectInWorker(
    PoseDetector detector, List<dynamic> msg) async {
  final Uint8List buffer = msg[0] as Uint8List;
  final int w = msg[1] as int;
  // msg[2] = original image height (not needed here; matH is used instead)
  final int colorCode = msg[3] as int;
  final int matH = msg[4] as int;
  final int channels = msg[5] as int;

  final matType = channels == 4 ? cv.MatType.CV_8UC4 : cv.MatType.CV_8UC1;
  final rawMat = cv.Mat.fromList(matH, w, matType, buffer);
  cv.Mat mat = cv.cvtColor(rawMat, colorCode);
  rawMat.dispose();

  const int maxDim = 320;
  if (mat.cols > maxDim || mat.rows > maxDim) {
    final double scale = maxDim / (mat.cols > mat.rows ? mat.cols : mat.rows);
    final resized = cv.resize(
      mat,
      ((mat.cols * scale).toInt(), (mat.rows * scale).toInt()),
      interpolation: cv.INTER_LINEAR,
    );
    mat.dispose();
    mat = resized;
  }

  final int imgW = mat.cols;
  final int imgH = mat.rows;

  final poses =
      await detector.detectFromMat(mat, imageWidth: imgW, imageHeight: imgH);
  mat.dispose();

  if (poses.isEmpty) {
    return [imgW, imgH, <List<double>>[]];
  }

  final pose = poses.first;
  final landmarks = pose.landmarks
      .map((l) => [l.type.index.toDouble(), l.x, l.y, l.visibility])
      .toList();

  return [imgW, imgH, landmarks];
}

// =====================================================================
//  Cubit — main thread only: camera, counting, state emissions.
// =====================================================================

enum _Phase { calibrating, up, down }

class PushUpCubit extends Cubit<PushUpState> {
  PushUpCubit() : super(const PushUpInitial());

  CameraController? _camera;
  SendPort? _workerPort;
  ReceivePort? _mainPort;
  bool _workerBusy = false;

  int _lastSentMs = 0;
  static const int _minIntervalMs = 100;

  // Counting
  _Phase _phase = _Phase.calibrating;
  int _repCount = 0;
  double _baselineY = -1;
  int _calibrationFrames = 0;
  double _calibrationSum = 0;
  static const int _calibrationTarget = 30;
  static const double _downDelta = 0.12;
  static const double _upDelta = 0.04;

  Future<void> startSession() async {
    emit(const CameraLoading());
    try {
      // Ensure binding is ready before grabbing the token
      WidgetsFlutterBinding.ensureInitialized();

      final token = RootIsolateToken.instance;
      if (token == null) {
        throw Exception('Failed to get RootIsolateToken — binding not ready');
      }

      _mainPort = ReceivePort();
      await Isolate.spawn(_poseWorkerEntry, [_mainPort!.sendPort, token]);

      // Listen for all messages from the worker
      _mainPort!.listen(_onWorkerMessage);

      // The first message will be the worker's SendPort (handshake).
      // After that, we'll get 'ready', then detection results.
    } catch (e, st) {
      debugPrint('[PushUpCubit] startSession error: $e\n$st');
      emit(const PushUpInitial());
    }
  }

  void _onWorkerMessage(dynamic msg) {
    if (msg is SendPort) {
      // Handshake — save worker port and tell it to init the detector
      _workerPort = msg;
      _workerPort!.send('init');
    } else if (msg == 'ready') {
      // Detector initialized — start camera
      _initCamera();
    } else if (msg is String && msg.startsWith('error:')) {
      debugPrint('[PushUpCubit] worker init failed: $msg');
      emit(const PushUpInitial());
    } else if (msg is List) {
      // Detection result
      _workerBusy = false;
      _onDetectionResult(msg);
    } else {
      // null = no result / error during detection
      _workerBusy = false;
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _camera = CameraController(
        front,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _camera!.initialize();

      _phase = _Phase.calibrating;
      _repCount = 0;
      _baselineY = -1;
      _calibrationFrames = 0;
      _calibrationSum = 0;

      emit(SessionActive(
        camera: _camera!,
        repCount: 0,
        poses: const [],
        imageWidth: _camera!.value.previewSize?.height.toInt() ?? 480,
        imageHeight: _camera!.value.previewSize?.width.toInt() ?? 640,
      ));

      await _camera!.startImageStream(_onCameraImage);
    } catch (e, st) {
      debugPrint('[PushUpCubit] _initCamera error: $e\n$st');
      emit(const PushUpInitial());
    }
  }

  /// Called on every camera frame (main thread).
  /// Assembles a raw NV12/I420 buffer (fast memcpy) and sends it to the worker.
  void _onCameraImage(CameraImage image) {
    if (_workerBusy || _workerPort == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSentMs < _minIntervalMs) return;
    _lastSentMs = now;

    final packet = _assembleBuffer(image);
    if (packet == null) return;

    _workerBusy = true;
    _workerPort!.send(packet);
  }

  /// Copies raw camera plane bytes into a flat buffer + metadata.
  /// Returns [Uint8List buffer, int w, int h, int colorCode, int matH]
  /// All work here is memcpy — no per-pixel math.
  List<dynamic>? _assembleBuffer(CameraImage image) {
    final int w = image.width;
    final int h = image.height;

    // 1-plane BGRA
    if (image.planes.length == 1 &&
        (image.planes[0].bytesPerPixel ?? 1) >= 4) {
      final bytes = image.planes[0].bytes;
      final stride = image.planes[0].bytesPerRow;
      Uint8List buf;
      if (stride == w * 4) {
        buf = Uint8List.fromList(bytes); // copy (frame data is recycled)
      } else {
        buf = Uint8List(w * h * 4);
        for (int row = 0; row < h; row++) {
          buf.setRange(row * w * 4, (row + 1) * w * 4, bytes, row * stride);
        }
      }
      return [buf, w, h, cv.COLOR_BGRA2BGR, h, 4];
    }

    // 2-plane NV12 (iOS)
    if (image.planes.length == 2) {
      final yPlane = image.planes[0].bytes;
      final uvPlane = image.planes[1].bytes;
      final yStride = image.planes[0].bytesPerRow;
      final uvStride = image.planes[1].bytesPerRow;
      final int nv12Size = w * h + w * (h ~/ 2);
      final buf = Uint8List(nv12Size);

      // Fast path: no stride padding
      if (yStride == w && uvStride == w) {
        buf.setRange(0, w * h, yPlane);
        buf.setRange(w * h, nv12Size, uvPlane);
      } else {
        for (int row = 0; row < h; row++) {
          buf.setRange(row * w, (row + 1) * w, yPlane, row * yStride);
        }
        final uvStart = w * h;
        for (int row = 0; row < h ~/ 2; row++) {
          buf.setRange(
              uvStart + row * w, uvStart + (row + 1) * w, uvPlane, row * uvStride);
        }
      }
      return [buf, w, h, cv.COLOR_YUV2BGR_NV12, h * 3 ~/ 2, 1];
    }

    // 3-plane I420 (Android)
    if (image.planes.length >= 3) {
      final yPlane = image.planes[0].bytes;
      final uPlane = image.planes[1].bytes;
      final vPlane = image.planes[2].bytes;
      final yStride = image.planes[0].bytesPerRow;
      final uStride = image.planes[1].bytesPerRow;
      final int uvH = h ~/ 2;
      final int uvW = w ~/ 2;
      final int i420Size = w * h + uvW * uvH * 2;
      final buf = Uint8List(i420Size);

      for (int row = 0; row < h; row++) {
        buf.setRange(row * w, (row + 1) * w, yPlane, row * yStride);
      }
      final uStart = w * h;
      final vStart = uStart + uvW * uvH;
      for (int row = 0; row < uvH; row++) {
        buf.setRange(
            uStart + row * uvW, uStart + (row + 1) * uvW, uPlane, row * uStride);
        buf.setRange(
            vStart + row * uvW, vStart + (row + 1) * uvW, vPlane, row * uStride);
      }
      return [buf, w, h, cv.COLOR_YUV2BGR_I420, h * 3 ~/ 2, 1];
    }

    return null;
  }

  /// Handles a detection result from the worker.
  /// [msg] = [imgW, imgH, [[typeIdx, x, y, vis], ...]]
  void _onDetectionResult(List<dynamic> msg) {
    if (state is! SessionActive) return;
    final current = state as SessionActive;

    final int imgW = msg[0] as int;
    final int imgH = msg[1] as int;
    final List<dynamic> rawLandmarks = msg[2] as List<dynamic>;

    String? feedback;
    List<DetectedPose> poses;

    if (rawLandmarks.isEmpty) {
      feedback = 'Move into frame';
      poses = const [];
    } else {
      final landmarks = rawLandmarks.map((l) {
        final d = l as List<dynamic>;
        return DetectedLandmark(
          PoseLandmarkType.values[(d[0] as double).toInt()],
          d[1] as double,
          d[2] as double,
          d[3] as double,
        );
      }).toList();

      poses = [DetectedPose(landmarks)];

      // Counting logic (very cheap — stays on main thread)
      final nose = poses.first.getLandmark(PoseLandmarkType.nose);
      if (nose == null || nose.visibility < 0.5) {
        feedback = 'Move into frame';
      } else {
        final noseY = nose.y / imgH;

        if (_phase == _Phase.calibrating) {
          _calibrationSum += noseY;
          _calibrationFrames++;
          feedback = 'Hold still to calibrate…';
          if (_calibrationFrames >= _calibrationTarget) {
            _baselineY = _calibrationSum / _calibrationFrames;
            _phase = _Phase.up;
            feedback = null;
          }
        } else {
          if (_phase == _Phase.up && noseY > _baselineY + _downDelta) {
            _phase = _Phase.down;
          } else if (_phase == _Phase.down && noseY < _baselineY + _upDelta) {
            _phase = _Phase.up;
            _repCount++;
          }
        }
      }
    }

    emit(current.copyWith(
      repCount: _repCount,
      feedback: feedback,
      clearFeedback: feedback == null,
      poses: poses,
      imageWidth: imgW,
      imageHeight: imgH,
    ));
  }

  Future<void> stopSession() async {
    final count = _repCount;
    await _camera?.stopImageStream();
    await _camera?.dispose();
    _camera = null;
    _workerPort?.send('stop');
    _workerPort = null;
    _mainPort?.close();
    _mainPort = null;

    _workerBusy = false;
    emit(SessionComplete(repCount: count));
  }

  @override
  Future<void> close() async {
    await _camera?.stopImageStream();
    await _camera?.dispose();
    _workerPort?.send('stop');
    _mainPort?.close();

    return super.close();
  }
}

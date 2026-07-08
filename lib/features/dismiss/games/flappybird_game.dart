import 'dart:async';
import 'dart:math';

import 'package:flame/cache.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Flappy Bird mini-game used by the alarm-dismiss mission. Ported from the
/// open-source Flame sample (BuildMyGame/FlutterFlameGames) and wired to the
/// mission-completion contract: passing a pipe scores a point, and reaching
/// [targetScore] fires [onWin]. Crashing resets the score to zero.
class FlappyBirdGame extends FlameGame with HasCollisionDetection {
  FlappyBirdGame({
    required this.targetScore,
    required this.scoreNotifier,
    required this.onPoint,
    required this.onWin,
  });

  /// Score the player must reach to complete the mission.
  final int targetScore;

  /// Live score, mirrored so the Flutter overlay can display `score / target`.
  final ValueNotifier<int> scoreNotifier;

  /// Called each time the bird passes a pipe (drives mission progress).
  final VoidCallback onPoint;

  /// Called once when [targetScore] is reached.
  final VoidCallback onWin;

  final _images = Images(prefix: 'assets/flappybird/sprites/');
  final _gameSpeed = 90.0;
  final _pipeFullSize = Vector2(52.0, 520.0);
  late PositionComponent _pipeLayer;
  bool _won = false;
  int _score = 0;

  @override
  FutureOr<void> onLoad() async {
    FlameAudio.updatePrefix('assets/flappybird/audios/');
    await _setupBg();
    await _setupBird();
    _resetGame();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_won) return;
    _updateBird(dt);
    _updatePipes(dt);
    if (_bird.isDead) {
      _gameOver();
    }
  }

  /// Sends the bird upward. Called from the hosting screen's tap handler.
  void flap() {
    if (_won) return;
    _playSafe('wing.wav');
    _birdYVelocity = -120;
  }

  // Background: static day sky + scrolling base platform.
  Future<void> _setupBg() async {
    final bgComponent = await loadParallaxComponent(
      [ParallaxImageData('background-day.png')],
      baseVelocity: Vector2(5, 0),
      images: _images,
    );
    add(bgComponent);

    _pipeLayer = PositionComponent();
    add(_pipeLayer);

    final baseComponent = await loadParallaxComponent(
      [ParallaxImageData('base.png')],
      baseVelocity: Vector2(_gameSpeed, 0),
      images: _images,
      alignment: Alignment.bottomLeft,
      repeat: ImageRepeat.repeatX,
      fill: LayerFill.none,
    );
    add(baseComponent);
  }

  // Bird.
  var _birdYVelocity = 0.0;
  final _gravity = 250.0;
  late _Bird _bird;

  Future<void> _setupBird() async {
    final sprites = [
      await Sprite.load('yellowbird-downflap.png', images: _images),
      await Sprite.load('yellowbird-midflap.png', images: _images),
      await Sprite.load('yellowbird-upflap.png', images: _images),
    ];
    final anim = SpriteAnimation.spriteList(sprites, stepTime: 0.2);
    _bird = _Bird(animation: anim, size: Vector2(34, 24));
    add(_bird);
  }

  void _updateBird(double dt) {
    _birdYVelocity += dt * _gravity;
    final newY = _bird.position.y + _birdYVelocity * dt;
    _bird.position = Vector2(_bird.position.x, newY);
    _bird.anchor = Anchor.center;
    _bird.angle = clampDouble(_birdYVelocity / 180, -pi * 0.25, pi * 0.25);

    if (newY > size.y) {
      _gameOver();
    }
  }

  // Pipes.
  final _pipes = <_Pipe>[];
  final _bonusZones = <_BonusZone>[];

  void _createPipe() {
    const pipeSpace = 220.0; // horizontal gap between pipe groups
    const minPipeHeight = 120.0; // minimum pipe height
    const gapHeight = 90.0; // vertical gap the bird flies through
    const baseHeight = 112.0; // bottom platform height
    const gapMaxRandomRange = 300.0; // gap position random range

    var lastPipePos = (_pipes.isEmpty ? size.x - pipeSpace : _pipes.last.position.x);
    lastPipePos += pipeSpace;

    final gapCenter = min(
              gapMaxRandomRange,
              size.y - minPipeHeight * 2 - baseHeight - gapHeight,
            ) *
            Random().nextDouble() +
        minPipeHeight +
        gapHeight * 0.5;

    final topPipe = _Pipe(images: _images, isUpsideDown: true, size: _pipeFullSize)
      ..position = Vector2(lastPipePos, (gapCenter - gapHeight * 0.5) - _pipeFullSize.y);
    _pipeLayer.add(topPipe);
    _pipes.add(topPipe);

    final bottomPipe = _Pipe(images: _images, size: _pipeFullSize)
      ..position = Vector2(lastPipePos, gapCenter + gapHeight * 0.5);
    _pipeLayer.add(bottomPipe);
    _pipes.add(bottomPipe);

    final bonusZone = _BonusZone(onPass: _onPass, size: Vector2(_pipeFullSize.x, gapHeight))
      ..position = Vector2(lastPipePos, gapCenter - gapHeight * 0.5);
    add(bonusZone);
    _bonusZones.add(bonusZone);
  }

  void _updatePipes(double dt) {
    for (final pipe in _pipes) {
      pipe.position = Vector2(pipe.position.x - dt * _gameSpeed, pipe.position.y);
    }
    for (final zone in _bonusZones) {
      zone.position = Vector2(zone.position.x - dt * _gameSpeed, zone.position.y);
    }
    _pipes.removeWhere((p) {
      final remove = p.position.x < -100;
      if (remove) p.removeFromParent();
      return remove;
    });
    _bonusZones.removeWhere((z) {
      final remove = z.position.x < -100;
      if (remove) z.removeFromParent();
      return remove;
    });

    if ((_pipes.isEmpty ? 0.0 : _pipes.last.position.x) < size.x) {
      _createPipe();
    }
  }

  // Scoring.
  void _onPass() {
    _score++;
    scoreNotifier.value = _score;
    _playSafe('point.wav');
    onPoint();
    if (_score >= targetScore && !_won) {
      _won = true;
      pauseEngine();
      onWin();
    }
  }

  void _gameOver() {
    _playSafe('die.wav');
    _resetGame();
  }

  void _resetGame() {
    _bird.isDead = false;
    _score = 0;
    scoreNotifier.value = 0;
    _bird.position = Vector2(size.x * 0.3, size.y * 0.5);
    _birdYVelocity = 0.0;
    for (final p in _pipes) {
      p.removeFromParent();
    }
    _pipes.clear();
    for (final z in _bonusZones) {
      z.removeFromParent();
    }
    _bonusZones.clear();
  }

  // Guards against a missing/failed audio asset crashing the game loop.
  void _playSafe(String file) {
    FlameAudio.play(file).then((_) {}, onError: (_) {});
  }
}

/// The player bird. Dies on pipe contact.
class _Bird extends SpriteAnimationComponent with CollisionCallbacks {
  bool isDead = false;

  _Bird({super.animation, super.size});

  @override
  FutureOr<void> onLoad() {
    add(RectangleHitbox(size: size));
    return super.onLoad();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is _Pipe) {
      isDead = true;
    }
  }
}

/// A single green pipe (top or bottom), stretched with a nine-tile box so the
/// cap stays crisp.
class _Pipe extends PositionComponent with CollisionCallbacks {
  final bool isUpsideDown;
  final Images images;

  _Pipe({required this.images, this.isUpsideDown = false, super.size});

  @override
  FutureOr<void> onLoad() async {
    final sprite = await Sprite.load('pipe-green.png', images: images);
    final nineBox = NineTileBox(sprite)
      ..setGrid(leftWidth: 10, rightWidth: 10, topHeight: 60, bottomHeight: 60);
    final box = NineTileBoxComponent(nineTileBox: nineBox, size: size);
    if (isUpsideDown) {
      box.flipVerticallyAroundCenter();
    }
    box.anchor = Anchor.topLeft;
    add(box);
    add(RectangleHitbox(size: size));
    return super.onLoad();
  }
}

/// Invisible hitbox in each pipe gap; scores a point when the bird passes it.
class _BonusZone extends PositionComponent with CollisionCallbacks {
  final VoidCallback onPass;

  _BonusZone({required this.onPass, super.size});

  @override
  FutureOr<void> onLoad() {
    add(RectangleHitbox(size: size));
    return super.onLoad();
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is _Bird) {
      onPass();
      removeFromParent();
    }
  }
}

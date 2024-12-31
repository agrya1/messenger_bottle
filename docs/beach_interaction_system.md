# 沙滩交互系统

## 1. 系统概述
沙滩交互系统负责处理漂流瓶在沙滩上的拾取、放置和相关动画效果。

## 2. 核心功能

### 2.1 沙滩交互管理
```dart
class BeachInteractionSystem {
  final BottlePhysics physics;
  final BottleModel model;
  final BeachSystem beach;
  
  // 检测瓶子是否在沙滩上
  bool isBottleOnBeach() {
    final bottlePosition = physics.position;
    return beach.isPointOnBeach(bottlePosition);
  }
  
  // 处理沙滩上的瓶子拾取
  Future<void> handleBeachPickup(Vector2 touchPosition) async {
    if (!isBottleOnBeach()) return;
    
    final ray = camera.screenPointToRay(touchPosition);
    final hit = physics.raycast(ray);
    
    if (hit != null && hit.object == model.model) {
      // 播放拾取动画
      await _playBeachPickupAnimation();
      
      // 显示瓶子内容
      await model.contentSystem.showContent(context);
      
      // 播放放回动画
      await _playReturnToBeachAnimation();
    }
  }
}
```

### 2.2 沙滩动画效果
```dart
class BeachAnimations {
  // 沙滩拾取动画
  Future<void> _playBeachPickupAnimation() async {
    final controller = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // 创建位置动画
    final positionAnimation = Tween<Vector3>(
      begin: physics.position,
      end: physics.position + Vector3(0, 1.5, 0),
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ),
    );
    
    // 创建旋转动画
    final rotationAnimation = Tween<Vector3>(
      begin: Vector3.zero(),
      end: Vector3(0, pi * 2, 0),
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
    
    // 播放动画
    controller.addListener(() {
      model.position = positionAnimation.value;
      model.rotation = rotationAnimation.value;
    });
    
    await controller.forward();
  }
  
  // 放回沙滩动画
  Future<void> _playReturnToBeachAnimation() async {
    final controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    // 创建位置动画
    final positionAnimation = Tween<Vector3>(
      begin: model.position,
      end: physics.position,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
    
    // 播放动画
    controller.addListener(() {
      model.position = positionAnimation.value;
    });
    
    await controller.forward();
  }
}
```

### 2.3 沙滩效果
```dart
class BeachEffects {
  late ParticleSystem sandParticles;
  
  // 初始化沙滩效果
  void initialize() {
    sandParticles = ParticleSystem(
      maxParticles: 50,
      particleLife: Range(0.5, 1.0),
      startSize: Range(0.05, 0.1),
      endSize: Range(0.0, 0.05),
      startColor: Colors.sandyBrown.withOpacity(0.6),
      endColor: Colors.sandyBrown.withOpacity(0),
      gravity: Vector3(0, -0.5, 0),
    );
  }
  
  // 播放沙子效果
  void playSandEffect(Vector3 position) {
    sandParticles.emitBurst(
      position: position,
      count: 20,
      spread: 0.3,
    );
  }
  
  // 更新效果
  void update(double deltaTime) {
    sandParticles.update(deltaTime);
  }
}
```

### 2.4 交互区域管理
```dart
class BeachInteractionZone {
  final Vector2 position;
  final double radius;
  bool isActive = false;
  
  // 检查点是否在交互区域内
  bool containsPoint(Vector2 point) {
    return (point - position).length <= radius;
  }
  
  // 更新交互区域状态
  void update(Vector3 bottlePosition) {
    final point = Vector2(bottlePosition.x, bottlePosition.z);
    isActive = containsPoint(point);
  }
  
  // 绘制交互提示
  void drawHint(Canvas canvas) {
    if (!isActive) return;
    
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(
      Offset(position.x, position.y),
      radius,
      paint,
    );
  }
}
```

## 3. 使用示例

```dart
// 初始化沙滩交互系统
final beachSystem = BeachInteractionSystem(
  physics: bottlePhysics,
  model: bottleModel,
  beach: beachSystem,
);

// 处理触摸事件
void onTapDown(TapDownDetails details) async {
  final touchPosition = details.localPosition;
  await beachSystem.handleBeachPickup(touchPosition);
}

// 更新系统
void update(double deltaTime) {
  beachSystem.update(deltaTime);
}
```

## 4. 注意事项

1. **性能优化**
   - 优化碰撞检测
   - 合理管理粒子效果
   - 控制动画资源使用

2. **用户体验**
   - 提供清晰的交互提示
   - 确保动画流畅自然
   - 添加适当的触觉反馈

3. **交互设计**
   - 设计直观的拾取机制
   - 提供合适的交互反馈
   - 处理边界情况 
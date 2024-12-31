# 漂流瓶系统

## 1. 系统概述
漂流瓶系统负责管理漂流瓶的3D模型、物理行为、交互效果和动画效果。

## 2. 核心功能

### 2.1 漂流瓶模型
```dart
class BottleModel {
  late Object3D model;
  late Material glassMaterial;
  late Material waterMaterial;
  Vector3 position;
  Vector3 rotation;
  double scale;
  
  BottleModel({
    this.position = const Vector3(0, 0, 0),
    this.rotation = const Vector3(0, 0, 0),
    this.scale = 1.0,
  });
  
  // 初始化模型
  Future<void> initialize() async {
    // 加载瓶子模型
    model = await Object3D.load('assets/models/bottle.obj');
    
    // 设置玻璃材质
    glassMaterial = Material(
      type: MaterialType.physical,
      color: Colors.white.withOpacity(0.8),
      metalness: 0.0,
      roughness: 0.1,
      transmission: 0.9,
      thickness: 0.5,
    );
    
    // 设置水材质
    waterMaterial = Material(
      type: MaterialType.physical,
      color: Colors.blue.withOpacity(0.6),
      metalness: 0.0,
      roughness: 0.2,
      transmission: 0.8,
    );
    
    // 应用材质
    _applyMaterials();
  }
  
  // 应用材质
  void _applyMaterials() {
    model.traverse((child) {
      if (child is Mesh) {
        if (child.name.contains('glass')) {
          child.material = glassMaterial;
        } else if (child.name.contains('water')) {
          child.material = waterMaterial;
        }
      }
    });
  }
  
  // 更新模型状态
  void update(double deltaTime) {
    model.position = position;
    model.rotation = rotation;
    model.scale = Vector3.all(scale);
    
    // 更新材质
    _updateMaterials(deltaTime);
  }
  
  // 更新材质效果
  void _updateMaterials(double deltaTime) {
    // 更新水材质的波动效果
    final time = DateTime.now().millisecondsSinceEpoch / 1000;
    waterMaterial.uniforms['uTime'] = time;
  }
}
```

### 2.2 物理系统
```dart
class BottlePhysics {
  final BottleModel model;
  Vector3 velocity;
  Vector3 acceleration;
  double mass;
  double buoyancy;
  double dragCoefficient;
  
  BottlePhysics({
    required this.model,
    this.mass = 1.0,
    this.buoyancy = 1.2,
    this.dragCoefficient = 0.5,
  }) : 
    velocity = Vector3.zero(),
    acceleration = Vector3.zero();
  
  // 更新物理状态
  void update(double deltaTime) {
    // 应用重力
    applyForce(Vector3(0, -9.81 * mass, 0));
    
    // 应用浮力
    _applyBuoyancy();
    
    // 应用水阻力
    _applyDrag();
    
    // 更新速度和位置
    velocity += acceleration * deltaTime;
    model.position += velocity * deltaTime;
    
    // 重置加速度
    acceleration.setZero();
    
    // 更新旋转
    _updateRotation(deltaTime);
  }
  
  // 应用力
  void applyForce(Vector3 force) {
    acceleration += force / mass;
  }
  
  // 应用浮力
  void _applyBuoyancy() {
    final waterHeight = _getWaterHeight(model.position);
    final submergedDepth = max(0.0, waterHeight - model.position.y);
    final buoyancyForce = Vector3(0, buoyancy * submergedDepth, 0);
    applyForce(buoyancyForce);
  }
  
  // 应用水阻力
  void _applyDrag() {
    final speed = velocity.length;
    if (speed > 0) {
      final dragMagnitude = dragCoefficient * speed * speed;
      final drag = velocity.normalized() * -dragMagnitude;
      applyForce(drag);
    }
  }
  
  // 更新旋转
  void _updateRotation(double deltaTime) {
    // 根据速度方向计算倾斜角度
    if (velocity.length > 0.1) {
      final targetRotation = Vector3(
        atan2(velocity.y, velocity.length),
        atan2(velocity.x, velocity.z),
        0,
      );
      
      // 平滑插值旋转
      model.rotation = Vector3.lerp(
        model.rotation,
        targetRotation,
        deltaTime * 5.0,
      );
    }
  }
}
```

### 2.3 交互系统
```dart
class BottleInteraction {
  final BottleModel model;
  final BottlePhysics physics;
  bool isDragging = false;
  Vector3? dragOffset;
  
  // 处理点击
  void onTap() {
    // 显示瓶子内容
    model.contentSystem.showContent();
  }
  
  // 开始拖动
  void onDragStart(Vector3 position) {
    isDragging = true;
    dragOffset = model.position - position;
  }
  
  // 拖动中
  void onDragUpdate(Vector3 position) {
    if (isDragging && dragOffset != null) {
      // 更新瓶子位置
      model.position = position + dragOffset!;
      
      // 限制移动范围
      _constrainPosition();
    }
  }
  
  // 结束拖动
  void onDragEnd(Vector3 velocity) {
    isDragging = false;
    dragOffset = null;
    
    // 应用抛出速度
    physics.velocity = velocity * 0.5;
  }
  
  // 限制移动范围
  void _constrainPosition() {
    // 限制水平范围
    model.position.x = clamp(
      model.position.x,
      -10.0,
      10.0,
    );
    
    // 限制垂直范围
    model.position.y = max(
      model.position.y,
      _getWaterHeight(model.position) - 0.5,
    );
  }
}
```

### 2.4 动画系统
```dart
class BottleAnimations {
  final BottleModel model;
  late AnimationController floatController;
  late AnimationController bobController;
  
  // 初始化动画
  void initialize() {
    // 漂浮动画
    floatController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    // 起伏动画
    bobController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    // 添加动画效果
    _addFloatAnimation();
    _addBobAnimation();
  }
  
  // 添加漂浮动画
  void _addFloatAnimation() {
    final floatAnimation = Tween<double>(
      begin: -0.2,
      end: 0.2,
    ).animate(
      CurvedAnimation(
        parent: floatController,
        curve: Curves.easeInOut,
      ),
    );
    
    floatAnimation.addListener(() {
      model.position.x += floatAnimation.value;
    });
  }
  
  // 添加起伏动画
  void _addBobAnimation() {
    final bobAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(
      CurvedAnimation(
        parent: bobController,
        curve: Curves.easeInOut,
      ),
    );
    
    bobAnimation.addListener(() {
      model.position.y += bobAnimation.value;
    });
  }
  
  // 播放捡起动画
  Future<void> playPickupAnimation() async {
    final controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    final pickupAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ),
    );
    
    pickupAnimation.addListener(() {
      model.position.y = lerp(
        _getWaterHeight(model.position),
        _getWaterHeight(model.position) + 1.0,
        pickupAnimation.value,
      );
      
      model.rotation.y = pi * 2 * pickupAnimation.value;
    });
    
    await controller.forward();
  }
}
```

## 3. 使用示例

```dart
// 初始化漂流瓶系统
final bottleModel = BottleModel();
await bottleModel.initialize();

final bottlePhysics = BottlePhysics(model: bottleModel);
final bottleInteraction = BottleInteraction(
  model: bottleModel,
  physics: bottlePhysics,
);

// 更新系统
void update(double deltaTime) {
  bottlePhysics.update(deltaTime);
  bottleModel.update(deltaTime);
}

// 处理交互
void onTapDown(TapDownDetails details) {
  final position = _screenToWorld(details.localPosition);
  if (_hitTest(position, bottleModel)) {
    bottleInteraction.onTap();
  }
}
```

## 4. 注意事项

1. **性能优化**
   - 使用LOD（细节层次）系统
   - 优化物理计算
   - 合理管理动画资源

2. **视觉效果**
   - 优化玻璃材质效果
   - 添加水面反射和折射
   - 调整物理参数以获得自然的运动效果

3. **交互设计**
   - 提供直观的拾取和投掷机制
   - 添加适当的触觉反馈
   - 处理边界情况 
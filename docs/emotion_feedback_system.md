# 情感反馈系统

## 1. 系统概述
情感反馈系统负责处理漂流瓶的情感表达，包括情感图标、粒子效果和动画效果。

## 2. 核心功能

### 2.1 情感类型定义
```dart
enum EmotionType {
  happy,
  sad,
  love,
  angry,
  surprised,
  neutral
}

class EmotionData {
  final EmotionType type;
  final Color color;
  final String iconPath;
  final String particleTexture;
  
  const EmotionData({
    required this.type,
    required this.color,
    required this.iconPath,
    required this.particleTexture,
  });
  
  static const Map<EmotionType, EmotionData> emotions = {
    EmotionType.happy: EmotionData(
      type: EmotionType.happy,
      color: Colors.yellow,
      iconPath: 'assets/icons/happy.png',
      particleTexture: 'assets/textures/happy_particle.png',
    ),
    EmotionType.love: EmotionData(
      type: EmotionType.love,
      color: Colors.pink,
      iconPath: 'assets/icons/heart.png',
      particleTexture: 'assets/textures/heart_particle.png',
    ),
    // ... 其他情感类型
  };
}
```

### 2.2 情感反馈系统
```dart
class EmotionFeedbackSystem {
  final BottleModel model;
  late ParticleSystem emotionParticles;
  late List<EmotionIcon> floatingIcons;
  
  // 初始化情感反馈系统
  void initialize() {
    // 初始化粒子系统
    emotionParticles = ParticleSystem(
      maxParticles: 20,
      particleLife: Range(1.0, 2.0),
      startSize: Range(0.2, 0.4),
      endSize: Range(0.1, 0.2),
      startColor: Colors.pink.withOpacity(0.6),
      endColor: Colors.pink.withOpacity(0),
    );
    
    // 初始化浮动图标
    floatingIcons = [];
  }
  
  // 添加情感反馈
  void addEmotionFeedback(EmotionType type) {
    final emotionData = EmotionData.emotions[type]!;
    
    // 创建浮动图标
    final icon = EmotionIcon(
      type: type,
      position: model.position + Vector3(0, 1.0, 0),
      data: emotionData,
    );
    
    // 添加浮动动画
    _addFloatingAnimation(icon);
    
    // 播放粒子效果
    _playEmotionParticles(type);
    
    floatingIcons.add(icon);
  }
  
  // 添加浮动动画
  void _addFloatingAnimation(EmotionIcon icon) {
    final controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    // 位置动画
    final positionAnimation = Tween<Vector3>(
      begin: icon.position,
      end: icon.position + Vector3(0, 1.0, 0),
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
    
    // 透明度动画
    final opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
      ),
    );
    
    // 更新图标状态
    controller.addListener(() {
      icon.position = positionAnimation.value;
      icon.opacity = opacityAnimation.value;
    });
    
    // 动画结束后移除图标
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        floatingIcons.remove(icon);
      }
    });
    
    controller.forward();
  }
  
  // 播放情感粒子效果
  void _playEmotionParticles(EmotionType type) {
    final emotionData = EmotionData.emotions[type]!;
    emotionParticles.texture = AssetImage(emotionData.particleTexture);
    emotionParticles.startColor = emotionData.color.withOpacity(0.6);
    emotionParticles.endColor = emotionData.color.withOpacity(0);
    
    emotionParticles.emitBurst(
      position: model.position + Vector3(0, 1.0, 0),
      count: 10,
      spread: 0.5,
    );
  }
  
  // 更新系统
  void update(double deltaTime) {
    // 更新粒子系统
    emotionParticles.update(deltaTime);
    
    // 更新浮动图标
    for (var icon in floatingIcons) {
      icon.update(deltaTime);
    }
  }
}
```

### 2.3 情感图标
```dart
class EmotionIcon {
  final EmotionType type;
  final EmotionData data;
  Vector3 position;
  double opacity;
  double rotation;
  
  EmotionIcon({
    required this.type,
    required this.position,
    required this.data,
    this.opacity = 1.0,
    this.rotation = 0.0,
  });
  
  void update(double deltaTime) {
    // 添加轻微摆动
    rotation += sin(DateTime.now().millisecondsSinceEpoch / 1000.0) * 0.1;
  }
  
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = data.color.withOpacity(opacity);
    
    canvas.save();
    canvas.translate(position.x, position.y);
    canvas.rotate(rotation);
    
    // 绘制图标
    canvas.drawImage(
      data.icon,
      Offset(-data.icon.width / 2, -data.icon.height / 2),
      paint,
    );
    
    canvas.restore();
  }
}
```

### 2.4 情感粒子效果
```dart
class EmotionParticleEffect {
  final EmotionType type;
  final EmotionData data;
  late ParticleSystem particles;
  
  EmotionParticleEffect(this.type, this.data) {
    particles = ParticleSystem(
      maxParticles: 30,
      emissionRate: 10,
      particleLife: Range(0.5, 1.5),
      startSize: Range(0.1, 0.2),
      endSize: Range(0.0, 0.1),
      startColor: data.color.withOpacity(0.8),
      endColor: data.color.withOpacity(0),
      texture: AssetImage(data.particleTexture),
    );
  }
  
  void emit(Vector3 position) {
    particles.emitBurst(
      position: position,
      count: 15,
      spread: 0.4,
    );
  }
  
  void update(double deltaTime) {
    particles.update(deltaTime);
  }
}
```

## 3. 使用示例

```dart
// 初始化情感反馈系统
final emotionSystem = EmotionFeedbackSystem(
  model: bottleModel,
);

// 添加情感反馈
void onEmotionSelected(EmotionType type) {
  emotionSystem.addEmotionFeedback(type);
}

// 更新系统
void update(double deltaTime) {
  emotionSystem.update(deltaTime);
}
```

## 4. 注意事项

1. **性能优化**
   - 限制同时显示的情感图标数量
   - 优化粒子系统性能
   - 及时清理不需要的资源

2. **视觉效果**
   - 确保动画流畅自然
   - 调整粒子效果参数
   - 保持视觉效果的一致性

3. **交互设计**
   - 提供直观的情感选择界面
   - 添加适当的触觉反馈
   - 考虑不同情感的表现形式 
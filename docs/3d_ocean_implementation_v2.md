# Flutter 3D 海洋场景实现方案 V2.0

## 一、技术栈选择

### 1. 核心技术
1. **3D 渲染引擎**
   - `flutter_cube`：轻量级 3D 渲染库，适合简单场景
   - `three_dart`：功能完整的 3D 引擎，支持复杂效果
   - 选择建议：先用 `flutter_cube` 实现基础效果，需要更复杂效果时迁移到 `three_dart`

2. **物理引擎**
   ```yaml
   dependencies:
     flutter_physics: ^0.1.0  # 基础物理模拟
     box2d_flame: ^0.5.0     # 2D 物理引擎（可选）
   ```

3. **辅助库**
   ```yaml
   flutter_weather_bg: ^2.8.0  # 天气效果
   noise: ^3.0.0              # 噪声算法
   vector_math: ^2.1.4        # 向量数学
   ```

### 2. 开发工具
1. **3D 建模**
   - Blender：创建和编辑 3D 模型
   - 导出格式：.obj（模型）+ .mtl（材质）

2. **资源处理**
   - TexturePacker：纹理图集优化
   - ASTC Encoder：纹理压缩

3. **着色器开发**
   - ShaderToy：开发和测试着色器
   - VSCode + GLSL 插件：着色器编辑

## 二、核心功能实现

### 1. 海洋系统

#### 1.1 基础实现（轻量版）
```dart
class OceanSystem {
  // 基础参数
  final int width;
  final int height;
  final int segments;
  
  // 波浪参数
  final List<WaveParameter> waves = [
    WaveParameter(
      amplitude: 0.3,
      frequency: 0.2,
      phase: 0.0,
      direction: Vector2(1.0, 0.0),
    ),
    WaveParameter(
      amplitude: 0.2,
      frequency: 0.4,
      phase: math.pi / 4,
      direction: Vector2(0.8, 0.2),
    ),
  ];

  // 简单波浪实现
  double calculateBasicWave(double x, double z, double time) {
    double height = 0.0;
    
    // 使用多个正弦波叠加
    for (var wave in waves) {
      final direction = wave.direction.normalized();
      final position = x * direction.x + z * direction.y;
      height += wave.amplitude * 
                math.sin(position * wave.frequency + time + wave.phase);
    }
    
    return height;
  }
}

// 水面材质（轻量版）
class WaterMaterial {
  Material createBasicWaterMaterial() {
    return Material(
      color: Color(0xFF1E88E5),
      opacity: 0.8,
      transparent: true,
      uniforms: {
        'time': 0.0,
        'normalMap': normalTexture,
      },
    );
  }
}
```

#### 1.2 高级实现（完整版）
```dart
class AdvancedOceanSystem extends OceanSystem {
  // Gerstner 波浪参数
  final List<GerstnerWave> gerstnerWaves = [
    GerstnerWave(
      amplitude: 0.5,
      wavelength: 10.0,
      steepness: 0.5,
      direction: Vector2(1.0, 0.0),
    ),
    GerstnerWave(
      amplitude: 0.3,
      wavelength: 6.0,
      steepness: 0.3,
      direction: Vector2(0.7, 0.7),
    ),
  ];

  // Gerstner 波实现
  Vector3 calculateGerstnerWave(double x, double z, double time) {
    var displacement = Vector3(x, 0, z);
    
    for (var wave in gerstnerWaves) {
      final k = 2 * math.pi / wave.wavelength;
      final c = math.sqrt(9.81 / k); // 波速
      final d = wave.direction.normalized();
      final f = k * (d.x * x + d.y * z) - c * time;
      
      displacement.x += wave.steepness * wave.amplitude * d.x * math.cos(f);
      displacement.y += wave.amplitude * math.sin(f);
      displacement.z += wave.steepness * wave.amplitude * d.y * math.cos(f);
    }
    
    return displacement;
  }

  // 添加 Perlin 噪声
  Vector3 addNoiseDetail(Vector3 position, double time) {
    final noise = SimplexNoise();
    final noiseScale = 0.03;
    final noiseAmplitude = 0.1;
    
    position.y += noise.noise3D(
      position.x * noiseScale,
      position.z * noiseScale,
      time
    ) * noiseAmplitude;
    
    return position;
  }

  // 更新网格
  void updateOceanMesh(double time) {
    final vertices = mesh.geometry.vertices;
    final normals = <Vector3>[];
    
    // 更新顶点位置
    for (var i = 0; i < vertices.length; i++) {
      var pos = vertices[i];
      // 计算 Gerstner 波
      pos = calculateGerstnerWave(pos.x, pos.z, time);
      // 添加噪声细节
      pos = addNoiseDetail(pos, time);
      vertices[i] = pos;
      
      // 计算法线
      if (i > 0 && i < vertices.length - 1) {
        final normal = calculateNormal(vertices[i-1], pos, vertices[i+1]);
        normals.add(normal);
      }
    }
    
    mesh.geometry.updateVertices(vertices);
    mesh.geometry.updateNormals(normals);
  }
}

// 高级水面材质
class AdvancedWaterMaterial {
  Material createAdvancedWaterMaterial() {
    return Material(
      vertexShader: _advancedVertexShader,
      fragmentShader: _advancedFragmentShader,
      uniforms: {
        'time': 0.0,
        'waterColor': Color(0xFF1E88E5),
        'reflectionMap': reflectionTexture,
        'normalMap': normalTexture,
        'dudvMap': dudvTexture,
        'depthMap': depthTexture,
        'foamTexture': foamTexture,
        'envMap': environmentMap,
      },
    );
  }

  // 添加泡沫效果
  void addFoamEffect(Vector3 position, double intensity) {
    final foam = ParticleSystem(
      emissionRate: 50 * intensity,
      particleLife: 1.0,
      startSize: 0.1,
      endSize: 0.05,
      startColor: Colors.white.withOpacity(0.8),
      endColor: Colors.white.withOpacity(0),
    );
    
    foam.emit(position);
  }
}

// 波浪参数类
class GerstnerWave {
  final double amplitude;    // 波浪高度
  final double wavelength;   // 波长
  final double steepness;    // 陡度
  final Vector2 direction;   // 传播方向
  final double speed;        // 传播速度
  
  GerstnerWave({
    required this.amplitude,
    required this.wavelength,
    required this.steepness,
    required this.direction,
    this.speed = 1.0,
  });
}
```

#### 1.3 性能优化版本
```dart
class OptimizedOceanSystem extends AdvancedOceanSystem {
  // LOD 参数
  final List<int> lodLevels = [128, 64, 32, 16];
  int currentLOD = 0;

  // 更新 LOD
  void updateLOD(double distance) {
    final level = (distance / 100).floor().clamp(0, lodLevels.length - 1);
    if (level != currentLOD) {
      currentLOD = level;
      regenerateMesh(lodLevels[level]);
    }
  }

  // 优化的网格更新
  @override
  void updateOceanMesh(double time) {
    // 只更新可见区域的顶点
    final visibleVertices = getVisibleVertices();
    for (var vertex in visibleVertices) {
      updateVertex(vertex, time);
    }
    
    // 批量更新几何体
    mesh.geometry.updateVerticesBatch(visibleVertices);
  }

  // 视锥体剔除
  List<Vector3> getVisibleVertices() {
    return vertices.where((v) => 
      frustum.containsPoint(v)
    ).toList();
  }

  // 网格分块
  void createChunks() {
    final chunkSize = 16;
    final chunks = <OceanChunk>[];
    
    for (var x = 0; x < width; x += chunkSize) {
      for (var z = 0; z < height; z += chunkSize) {
        chunks.add(OceanChunk(
          position: Vector2(x, z),
          size: chunkSize,
        ));
      }
    }
  }
}

// 海洋分块
class OceanChunk {
  final Vector2 position;
  final int size;
  late Mesh mesh;
  bool isVisible = false;
  
  OceanChunk({
    required this.position,
    required this.size,
  }) {
    mesh = generateChunkMesh();
  }
  
  void update(double time) {
    if (isVisible) {
      updateMesh(time);
    }
  }
}
```

这个优化版本提供了三个层次的实现：
1. 基础实现：适用于低性能设备，使用简单的正弦波
2. 高级实现：使用 Gerstner 波和噪声，提供更真实的效果
3. 性能优化版本：添加了 LOD、视锥体剔除和网格分块

### 2. 漂流瓶系统

#### 2.1 基础模型与材质
```dart
class BottleModel {
  late Object3D model;
  late Material glassMaterial;
  late Material waterMaterial;
  
  // 加载模型和材质
  Future<void> loadModel() async {
    // 加载 Blender 导出的模型
    model = await Object3D.load('assets/models/bottle.obj');
    
    // 创建玻璃材质
    glassMaterial = Material(
      vertexShader: glassVertexShader,
      fragmentShader: glassFragmentShader,
      uniforms: {
        'refractionRatio': 0.98,
        'fresnelBias': 0.1,
        'fresnelScale': 2.0,
        'fresnelPower': 2.0,
        'tCube': environmentMap,
      },
      transparent: true,
      opacity: 0.8,
    );
    
    // 创建瓶中水材质
    waterMaterial = Material(
      color: Color(0xFF1E88E5),
      opacity: 0.6,
      transparent: true,
      refractionRatio: 0.98,
    );
    
    // 应用材质
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
}
```

#### 2.2 物理系统
```dart
class BottlePhysics {
  Vector3 position;
  Vector3 velocity;
  Vector3 acceleration;
  Quaternion rotation;
  Vector3 angularVelocity;
  
  final double mass;
  final double volume;
  final double dragCoefficient;
  final double rotationalDragCoefficient;
  
  BottlePhysics({
    required this.mass,
    required this.volume,
    this.dragCoefficient = 0.47,
    this.rotationalDragCoefficient = 0.1,
  });

  // 应用力
  void applyForce(Vector3 force, [Vector3? applicationPoint]) {
    acceleration += force / mass;
    
    if (applicationPoint != null) {
      // 计算力矩
      final torque = applicationPoint.cross(force);
      applyTorque(torque);
    }
  }
  
  // 应用力矩
  void applyTorque(Vector3 torque) {
    angularVelocity += torque / mass;
  }

  // 计算浮力
  void applyBuoyancy(double waterHeight) {
    final submergedVolume = calculateSubmergedVolume(waterHeight);
    if (submergedVolume > 0) {
      // 浮力大小 = 排开水的重量
      final buoyancyMagnitude = submergedVolume * 9.81 * WATER_DENSITY;
      final buoyancyForce = Vector3(0, buoyancyMagnitude, 0);
      
      // 浮力作用点（浮心）
      final buoyancyPoint = calculateBuoyancyPoint(waterHeight);
      applyForce(buoyancyForce, buoyancyPoint);
      
      // 水的阻力
      final dragForce = calculateDragForce(waterHeight);
      applyForce(dragForce);
      
      // 水的旋转阻力
      final rotationalDrag = -angularVelocity * rotationalDragCoefficient;
      applyTorque(rotationalDrag);
    }
  }
  
  // 计算水阻力
  Vector3 calculateDragForce(double waterHeight) {
    final relativeVelocity = velocity;
    final speed = relativeVelocity.length;
    if (speed > 0) {
      final dragDirection = -relativeVelocity.normalized();
      final dragMagnitude = 0.5 * WATER_DENSITY * speed * speed * 
                           dragCoefficient * calculateSubmergedArea(waterHeight);
      return dragDirection * dragMagnitude;
    }
    return Vector3.zero();
  }

  // 更新物理状态
  void update(double deltaTime) {
    // 更新线性运动
    velocity += acceleration * deltaTime;
    position += velocity * deltaTime;
    acceleration.setZero();
    
    // 更新旋转运动
    rotation = rotation + Quaternion.fromAxisAngle(
      angularVelocity.normalized(),
      angularVelocity.length * deltaTime
    );
    
    // 阻尼
    velocity *= 0.98;
    angularVelocity *= 0.98;
  }
}
```

#### 2.3 交互系统
```dart
class BottleInteraction {
  final BottlePhysics physics;
  final BottleModel model;
  final AnimationController animationController;
  
  // 投掷状态
  bool isDragging = false;
  Vector2 dragStartPosition = Vector2.zero();
  Vector2 dragCurrentPosition = Vector2.zero();
  
  // 投掷漂流瓶
  void throwBottle(Vector2 direction, double force) {
    final angle = math.atan2(direction.y, direction.x);
    final throwVelocity = Vector3(
      math.cos(angle) * force,
      force * 0.5, // 向上的分量
      math.sin(angle) * force
    );
    
    // 添加随机旋转
    final randomRotation = Vector3(
      math.Random().nextDouble() - 0.5,
      math.Random().nextDouble() - 0.5,
      math.Random().nextDouble() - 0.5,
    ) * force * 0.5;
    
    physics.velocity = throwVelocity;
    physics.angularVelocity = randomRotation;
    
    // 播放投掷动画
    _playThrowAnimation();
  }
  
  // 捡起漂流瓶
  Future<bool> pickupBottle(Vector2 touchPosition) async {
    final ray = camera.screenPointToRay(touchPosition);
    final hit = physics.raycast(ray);
    
    if (hit != null && hit.object == model.model) {
      // 播放捡起动画
      await _playPickupAnimation();
      
      // 显示瓶中内容
      _showBottleContent();
      return true;
    }
    return false;
  }
  
  // 处理拖动
  void onPanUpdate(DragUpdateDetails details) {
    if (!isDragging) return;
    
    dragCurrentPosition = details.localPosition;
    final delta = dragCurrentPosition - dragStartPosition;
    
    // 更新瓶子位置
    model.model.position = _screenToWorldPosition(dragCurrentPosition);
    
    // 添加拖尾效果
    _updateDragTrail(delta);
  }
  
  // 释放漂流瓶
  void onPanEnd(DragEndDetails details) {
    if (!isDragging) return;
    
    isDragging = false;
    final throwDirection = dragCurrentPosition - dragStartPosition;
    final force = throwDirection.length.clamp(0.0, 20.0);
    
    throwBottle(throwDirection.normalized(), force);
  }
  
  // 显示瓶中内容
  void _showBottleContent() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BottleContentView(
        content: bottleContent,
        onClose: () {
          Navigator.pop(context);
          _playReleaseAnimation();
        },
      ),
    );
  }
}
```

#### 2.4 视觉效果
```dart
class BottleEffects {
  late ParticleSystem waterSplash;
  late ParticleSystem waterTrail;
  late ParticleSystem emotionParticles;
  
  // 初始化特效系统
  void initializeEffects() {
    // 水花效果
    waterSplash = ParticleSystem(
      maxParticles: 100,
      particleLife: Range(0.5, 1.0),
      startSize: Range(0.1, 0.3),
      endSize: Range(0.0, 0.1),
      startColor: Colors.white.withOpacity(0.8),
      endColor: Colors.white.withOpacity(0),
      gravity: Vector3(0, -9.81, 0),
      texture: splashTexture,
    );
    
    // 水的拖尾
    waterTrail = ParticleSystem(
      maxParticles: 50,
      emissionRate: 20,
      particleLife: Range(0.3, 0.6),
      startSize: Range(0.05, 0.1),
      endSize: Range(0.0, 0.05),
      startColor: Colors.blue.withOpacity(0.4),
      endColor: Colors.blue.withOpacity(0),
    );
    
    // 情感粒子
    emotionParticles = ParticleSystem(
      maxParticles: 20,
      particleLife: Range(1.0, 2.0),
      startSize: Range(0.2, 0.4),
      endSize: Range(0.1, 0.2),
      startColor: Colors.pink.withOpacity(0.6),
      endColor: Colors.pink.withOpacity(0),
      texture: heartTexture,
    );
  }
  
  // 播放入水效果
  void playWaterSplash(Vector3 position) {
    waterSplash.emitBurst(
      position: position,
      count: 30,
      spread: 0.5,
    );
  }
  
  // 更新拖尾效果
  void updateTrail(Vector3 position, Vector3 velocity) {
    if (velocity.length > 0.1) {
      waterTrail.emitFromLine(
        start: position,
        end: position - velocity.normalized() * 0.5,
      );
    }
  }
  
  // 播放情感效果
  void playEmotionEffect(Vector3 position, EmotionType type) {
    emotionParticles.texture = getEmotionTexture(type);
    emotionParticles.emitBurst(
      position: position + Vector3(0, 1.0, 0),
      count: 5,
      spread: 0.3,
    );
  }
}
```

#### 2.5 漂流路径系统
```dart
class BottlePath {
  final List<Vector3> pathPoints = [];
  final List<double> timeStamps = [];
  late Path2D pathSpline;
  
  // 添加路径点
  void addPathPoint(Vector3 position, double time) {
    pathPoints.add(position);
    timeStamps.add(time);
    
    if (pathPoints.length >= 3) {
      // 使用样条曲线生成平滑路径
      pathSpline = _generateSplinePath();
    }
  }
  
  // 生成样条曲线路径
  Path2D _generateSplinePath() {
    final spline = Path2D();
    final points2D = pathPoints.map((p) => Offset(p.x, p.z)).toList();
    
    spline.moveTo(points2D[0].dx, points2D[0].dy);
    
    for (var i = 1; i < points2D.length - 2; i++) {
      final p0 = points2D[i - 1];
      final p1 = points2D[i];
      final p2 = points2D[i + 1];
      final p3 = points2D[i + 2];
      
      // 计算控制点
      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6
      );
      
      spline.cubicTo(
        cp1.dx, cp1.dy,
        cp2.dx, cp2.dy,
        p2.dx, p2.dy
      );
    }
    
    return spline;
  }
  
  // 获取路径上的点
  Vector3 getPointAtTime(double time) {
    if (pathPoints.isEmpty) return Vector3.zero();
    
    // 找到时间对应的路径段
    int i = 0;
    while (i < timeStamps.length - 1 && timeStamps[i + 1] < time) i++;
    
    if (i >= timeStamps.length - 1) return pathPoints.last;
    
    // 计算插值因子
    final t = (time - timeStamps[i]) / 
             (timeStamps[i + 1] - timeStamps[i]);
    
    // 在路径点之间进行插值
    return Vector3.lerp(pathPoints[i], pathPoints[i + 1], t);
  }
  
  // 绘制路径
  void drawPath(Canvas canvas, Paint paint) {
    if (pathSpline != null) {
      canvas.drawPath(pathSpline, paint);
    }
  }
}
```

这个完整版本的漂流瓶系统包括：

1. **基础模型与材质**
   - 支持玻璃材质的折射和反射
   - 瓶中水的渲染效果
   - 材质的动态更新

2. **完整的物理系统**
   - 6自由度物理模拟（位置和旋转）
   - 真实的浮力计算
   - 水的阻力和旋转阻力

3. **丰富的交互系统**
   - 拖拽和投掷机制
   - 触摸检测和拾取
   - 内容展示动画

4. **视觉特效系统**
   - 水花和水的拖尾效果
   - 情感粒子效果
   - 动态光影效果

5. **漂流路径系统**
   - 样条曲线路径生成
   - 路径可视化
   - 时间轴回放功能

### 3. 环境效果

#### 3.1 天气系统
```dart
// 天气类型枚举
enum WeatherType {
  sunny,    // 晴天
  cloudy,   // 阴天
  rainy,    // 雨天
  stormy,   // 暴风雨
  snowy     // 雪天
}

// 天气系统主类
class WeatherSystem {
  WeatherType currentWeather;
  double intensity;
  late LightingSystem lightingSystem;
  late ParticleManager particleManager;
  late Wind wind;
  
  WeatherSystem({
    this.currentWeather = WeatherType.sunny,
    this.intensity = 1.0,
  }) {
    lightingSystem = LightingSystem();
    particleManager = ParticleManager();
    wind = Wind();
  }

  // 更新天气状态
  void updateWeather(double timeOfDay) {
    // 更新光照
    lightingSystem.updateLighting(currentWeather, timeOfDay);
    
    // 更新粒子效果
    _updateParticleEffects();
    
    // 更新风力
    _updateWind();
    
    // 更新海洋效果
    _updateOceanEffects();
  }

  // 更新粒子效果
  void _updateParticleEffects() {
    // 停止所有粒子效果
    particleManager.stopAll();
    
    // 根据天气类型启动对应效果
    switch (currentWeather) {
      case WeatherType.rainy:
        particleManager.startRain(intensity);
        break;
      case WeatherType.stormy:
        particleManager.startStorm(intensity);
        break;
      case WeatherType.snowy:
        particleManager.startSnow(intensity);
        break;
      default:
        break;
    }
  }

  // 更新风力效果
  void _updateWind() {
    switch (currentWeather) {
      case WeatherType.stormy:
        wind.setStormWind(intensity);
        break;
      case WeatherType.rainy:
        wind.setRainWind(intensity);
        break;
      default:
        wind.setNormalWind(intensity);
        break;
    }
  }

  // 更新海洋效果
  void _updateOceanEffects() {
    // 根据天气和风力更新海浪
    oceanSystem.updateWaveParameters(
      wind.speed,
      wind.direction,
      currentWeather,
      intensity
    );
  }
}

// 光照系统
class LightingSystem {
  late DirectionalLight sunLight;
  late AmbientLight ambientLight;
  late List<PointLight> atmosphereLights;
  
  // 光照参数配置
  static const Map<WeatherType, LightingParams> lightingConfigs = {
    WeatherType.sunny: LightingParams(
      sunIntensity: 1.0,
      ambientIntensity: 0.3,
      color: Color(0xFFFFFFFF),
    ),
    WeatherType.cloudy: LightingParams(
      sunIntensity: 0.5,
      ambientIntensity: 0.4,
      color: Color(0xFFE0E0E0),
    ),
    WeatherType.rainy: LightingParams(
      sunIntensity: 0.2,
      ambientIntensity: 0.6,
      color: Color(0xFF808080),
    ),
    WeatherType.stormy: LightingParams(
      sunIntensity: 0.1,
      ambientIntensity: 0.7,
      color: Color(0xFF505050),
    ),
    WeatherType.snowy: LightingParams(
      sunIntensity: 0.4,
      ambientIntensity: 0.5,
      color: Color(0xFFF0F0FF),
    ),
  };

  void updateLighting(WeatherType weather, double timeOfDay) {
    final params = lightingConfigs[weather]!;
    
    // 更新太阳光
    _updateSunLight(params, timeOfDay);
    
    // 更新环境光
    _updateAmbientLight(params);
    
    // 更新氛围光
    _updateAtmosphereLights(params, weather);
  }

  void _updateSunLight(LightingParams params, double timeOfDay) {
    // 计算太阳位置
    final angle = timeOfDay * 2 * pi;
    final height = sin(angle);
    
    sunLight.intensity = params.sunIntensity * max(height, 0.0);
    sunLight.color = params.color;
    sunLight.position.setValues(
      cos(angle) * 100,
      height * 100,
      0,
    );
  }
}

// 粒子管理器
class ParticleManager {
  late RainParticleSystem rainSystem;
  late SnowParticleSystem snowSystem;
  late StormParticleSystem stormSystem;
  
  ParticleManager() {
    rainSystem = RainParticleSystem();
    snowSystem = SnowParticleSystem();
    stormSystem = StormParticleSystem();
  }

  void startRain(double intensity) {
    rainSystem.start(
      emissionRate: 1000 * intensity,
      speed: 10.0 * intensity,
    );
  }

  void startSnow(double intensity) {
    snowSystem.start(
      emissionRate: 500 * intensity,
      speed: 2.0 * intensity,
    );
  }

  void startStorm(double intensity) {
    stormSystem.start(
      emissionRate: 2000 * intensity,
      speed: 15.0 * intensity,
    );
  }

  void stopAll() {
    rainSystem.stop();
    snowSystem.stop();
    stormSystem.stop();
  }
}

// 风力系统
class Wind {
  Vector3 direction;
  double speed;
  double turbulence;
  
  void setStormWind(double intensity) {
    speed = 20.0 * intensity;
    turbulence = 0.8;
    _updateWindDirection();
  }
  
  void setRainWind(double intensity) {
    speed = 5.0 * intensity;
    turbulence = 0.3;
    _updateWindDirection();
  }
  
  void setNormalWind(double intensity) {
    speed = 2.0 * intensity;
    turbulence = 0.1;
    _updateWindDirection();
  }
  
  void _updateWindDirection() {
    // 添加随机扰动
    final noise = SimplexNoise();
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    direction = Vector3(
      cos(time * 0.1) + noise.noise2D(time * 0.5, 0.0) * turbulence,
      0,
      sin(time * 0.1) + noise.noise2D(0.0, time * 0.5) * turbulence,
    ).normalized();
  }
}

// 天气变化管理器
class WeatherManager {
  final WeatherSystem weatherSystem;
  Timer? _transitionTimer;
  WeatherType? _targetWeather;
  double _transitionProgress = 0.0;
  
  WeatherManager(this.weatherSystem);

  Future<void> changeWeather(WeatherType newWeather, {
    Duration duration = const Duration(seconds: 5),
  }) async {
    if (_transitionTimer?.isActive ?? false) {
      _transitionTimer!.cancel();
    }
    
    _targetWeather = newWeather;
    _transitionProgress = 0.0;
    
    final steps = duration.inMilliseconds ~/ 16; // 约60fps
    final stepSize = 1.0 / steps;
    
    _transitionTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (timer) {
        _transitionProgress += stepSize;
        
        if (_transitionProgress >= 1.0) {
          weatherSystem.currentWeather = newWeather;
          timer.cancel();
          _targetWeather = null;
        } else {
          _updateTransition();
        }
      },
    );
  }

  void _updateTransition() {
    if (_targetWeather == null) return;
    
    // 使用缓动函数使过渡更自然
    final t = Curves.easeInOut.transform(_transitionProgress);
    
    // 插值过渡参数
    weatherSystem.intensity = lerpDouble(
      weatherSystem.intensity,
      1.0,
      t,
    )!;
    
    // 更新天气效果
    weatherSystem.updateWeather(
      DateTime.now().hour / 24.0,
    );
  }
}
```

#### 3.2 环境音效系统
```dart
class EnvironmentSoundSystem {
  late AudioPlayer ambientPlayer;
  late AudioPlayer weatherPlayer;
  late AudioPlayer wavePlayer;
  
  // 音效配置
  static const Map<WeatherType, String> weatherSounds = {
    WeatherType.rainy: 'assets/sounds/rain.mp3',
    WeatherType.stormy: 'assets/sounds/storm.mp3',
    WeatherType.snowy: 'assets/sounds/snow.mp3',
  };

  Future<void> initialize() async {
    ambientPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
    weatherPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
    wavePlayer = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
    
    // 预加载音效
    await _preloadSounds();
  }

  Future<void> updateWeatherSound(WeatherType weather, double intensity) async {
    // 停止当前天气音效
    await weatherPlayer.stop();
    
    // 播放新的天气音效
    if (weatherSounds.containsKey(weather)) {
      await weatherPlayer.setAsset(weatherSounds[weather]!);
      await weatherPlayer.setVolume(intensity);
      await weatherPlayer.play();
    }
  }

  Future<void> updateWaveSound(double waveIntensity) async {
    await wavePlayer.setVolume(waveIntensity);
  }
}
```

这个环境效果系统包括：

1. **完整的天气系统**
   - 支持5种天气类型
   - 动态光照调整
   - 粒子效果系统
   - 风力影响

2. **平滑的天气转换**
   - 渐变式天气切换
   - 参数插值过渡
   - 缓动效果

3. **环境音效**
   - 天气相关音效
   - 海浪声音
   - 音量动态调整

4. **性能优化**
   - 粒子系统优化
   - 资源预加载
   - 动态LOD

## 四、实现步骤

1. **项目初始化**
   - 配置依赖
   - 创建基础项目结构
   - 设置资源目录

2. **基础场景搭建**
   - 初始化 3D 渲染器
   - 设置相机系统
   - 配置基础光照

3. **海洋系统实现**
   - 创建海洋网格
   - 实现波浪动画
   - 添加水面材质和效果

4. **漂流瓶系统**
   - 导入漂流瓶模型
   - 实现物理系统
   - 添加交互功能

5. **环境效果**
   - 实现天气系统
   - 添加粒子效果
   - 优化光照效果

6. **性能优化**
   - 实现 LOD 系统
   - 添加剔除优化
   - 优化资源管理

## 五、注意事项

1. **性能考虑**
   - 控制场景多边形数量
   - 优化着色器复杂度
   - 使用 LOD 系统
   - 实现视锥体剔除
   - 合理使用粒子效果

2. **内存管理**
   - 使用纹理压缩
   - 实现资源池
   - 及时释放未使用资源
   - 控制资源加载顺序

3. **兼容性**
   - 提供性能降级方案
   - 处理不同设备特性
   - 优化移动端表现

4. **开发建议**
   - 先实现基础功能，再添加特效
   - 持续进行性能检测
   - 保持代码模块化
   - 做好异常处理 
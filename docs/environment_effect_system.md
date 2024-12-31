# 环境效果系统

## 1. 系统概述
环境效果系统负责管理场景中的天气、光照、粒子效果和环境音效，以创造沉浸式的海洋场景体验。

## 2. 核心功能

### 2.1 天气系统
```dart
enum WeatherType {
  sunny,    // 晴天
  cloudy,   // 阴天
  rainy,    // 雨天
  stormy,   // 暴风雨
  snowy     // 雪天
}

class WeatherSystem {
  WeatherType currentWeather;
  double intensity;
  late LightingSystem lightingSystem;
  late ParticleSystem particleSystem;
  late AudioSystem audioSystem;
  late WindSystem windSystem;
  
  WeatherSystem({
    this.currentWeather = WeatherType.sunny,
    this.intensity = 1.0,
  }) {
    lightingSystem = LightingSystem();
    particleSystem = ParticleSystem();
    audioSystem = AudioSystem();
    windSystem = WindSystem();
  }
  
  // 更新天气状态
  void updateWeather(double timeOfDay) {
    // 更新光照
    lightingSystem.updateLighting(currentWeather, timeOfDay);
    
    // 更新粒子效果
    particleSystem.updateParticles(currentWeather, intensity);
    
    // 更新音效
    audioSystem.updateAudio(currentWeather, intensity);
    
    // 更新风力
    windSystem.updateWind(currentWeather, intensity);
  }
  
  // 平滑切换天气
  Future<void> transitionTo(WeatherType newWeather, {Duration duration = const Duration(seconds: 2)}) async {
    final oldWeather = currentWeather;
    currentWeather = newWeather;
    
    // 创建过渡动画
    final controller = AnimationController(
      duration: duration,
      vsync: this,
    );
    
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );
    
    // 执行过渡
    animation.addListener(() {
      final t = animation.value;
      intensity = lerpDouble(1.0, 0.0, t)!;
      
      // 更新各个系统
      updateWeather(timeOfDay);
    });
    
    await controller.forward();
  }
}
```

### 2.2 光照系统
```dart
class LightingSystem {
  late DirectionalLight sunLight;
  late AmbientLight ambientLight;
  late List<PointLight> sceneLights;
  
  // 初始化光照系统
  void initialize() {
    sunLight = DirectionalLight(
      color: Colors.white,
      intensity: 1.0,
      position: Vector3(0, 1, 0),
    );
    
    ambientLight = AmbientLight(
      color: Colors.white,
      intensity: 0.2,
    );
    
    sceneLights = [];
  }
  
  // 更新光照效果
  void updateLighting(WeatherType weather, double timeOfDay) {
    // 计算太阳位置
    final sunAngle = timeOfDay * 2 * pi;
    final sunHeight = sin(sunAngle);
    
    // 更新太阳光
    sunLight.position = Vector3(
      cos(sunAngle),
      sunHeight,
      sin(sunAngle),
    );
    
    // 根据天气调整光照强度
    switch (weather) {
      case WeatherType.sunny:
        _updateSunnyLighting();
        break;
      case WeatherType.cloudy:
        _updateCloudyLighting();
        break;
      case WeatherType.rainy:
        _updateRainyLighting();
        break;
      case WeatherType.stormy:
        _updateStormyLighting();
        break;
      case WeatherType.snowy:
        _updateSnowyLighting();
        break;
    }
  }
  
  // 更新晴天光照
  void _updateSunnyLighting() {
    sunLight.intensity = 1.0;
    ambientLight.intensity = 0.3;
    sunLight.color = Colors.white;
  }
  
  // 更新阴天光照
  void _updateCloudyLighting() {
    sunLight.intensity = 0.5;
    ambientLight.intensity = 0.4;
    sunLight.color = Colors.white70;
  }
  
  // 更新雨天光照
  void _updateRainyLighting() {
    sunLight.intensity = 0.3;
    ambientLight.intensity = 0.5;
    sunLight.color = Colors.white60;
  }
}
```

### 2.3 粒子系统
```dart
class WeatherParticleSystem {
  late ParticleSystem rainParticles;
  late ParticleSystem snowParticles;
  late ParticleSystem stormParticles;
  
  // 初始化粒子系统
  void initialize() {
    rainParticles = ParticleSystem(
      maxParticles: 1000,
      particleLife: Range(1.0, 2.0),
      startSize: Range(0.1, 0.2),
      endSize: Range(0.0, 0.1),
      startColor: Colors.white.withOpacity(0.6),
      endColor: Colors.white.withOpacity(0),
      gravity: Vector3(0, -9.8, 0),
    );
    
    snowParticles = ParticleSystem(
      maxParticles: 500,
      particleLife: Range(2.0, 4.0),
      startSize: Range(0.2, 0.4),
      endSize: Range(0.1, 0.2),
      startColor: Colors.white.withOpacity(0.8),
      endColor: Colors.white.withOpacity(0),
      gravity: Vector3(0, -1.0, 0),
    );
    
    stormParticles = ParticleSystem(
      maxParticles: 2000,
      particleLife: Range(0.5, 1.0),
      startSize: Range(0.1, 0.3),
      endSize: Range(0.0, 0.1),
      startColor: Colors.white.withOpacity(0.4),
      endColor: Colors.white.withOpacity(0),
      gravity: Vector3(-5.0, -9.8, 0),
    );
  }
  
  // 更新粒子效果
  void updateParticles(WeatherType weather, double intensity) {
    switch (weather) {
      case WeatherType.rainy:
        _updateRainParticles(intensity);
        break;
      case WeatherType.snowy:
        _updateSnowParticles(intensity);
        break;
      case WeatherType.stormy:
        _updateStormParticles(intensity);
        break;
      default:
        _stopAllParticles();
    }
  }
  
  // 更新雨天粒子
  void _updateRainParticles(double intensity) {
    rainParticles.emissionRate = 500 * intensity;
    rainParticles.start();
    snowParticles.stop();
    stormParticles.stop();
  }
}
```

### 2.4 风力系统
```dart
class WindSystem {
  Vector3 direction;
  double speed;
  double gustStrength;
  
  WindSystem({
    this.direction = const Vector3(1, 0, 0),
    this.speed = 0.0,
    this.gustStrength = 0.0,
  });
  
  // 更新风力
  void updateWind(WeatherType weather, double intensity) {
    switch (weather) {
      case WeatherType.stormy:
        _updateStormWind(intensity);
        break;
      case WeatherType.rainy:
        _updateRainWind(intensity);
        break;
      default:
        _updateNormalWind(intensity);
    }
  }
  
  // 更新暴风天气的风力
  void _updateStormWind(double intensity) {
    speed = 20.0 * intensity;
    gustStrength = 10.0 * intensity;
    
    // 随机改变风向
    direction = Vector3(
      cos(DateTime.now().millisecondsSinceEpoch / 1000),
      0,
      sin(DateTime.now().millisecondsSinceEpoch / 1000),
    );
  }
  
  // 应用风力效果
  void applyWindForce(PhysicsObject object) {
    final windForce = direction * speed;
    final gust = _calculateGust();
    object.applyForce(windForce + gust);
  }
  
  // 计算阵风效果
  Vector3 _calculateGust() {
    final time = DateTime.now().millisecondsSinceEpoch / 1000;
    final gustX = sin(time) * gustStrength;
    final gustZ = cos(time) * gustStrength;
    return Vector3(gustX, 0, gustZ);
  }
}
```

### 2.5 环境音效系统
```dart
class EnvironmentAudioSystem {
  late AudioPlayer ambientPlayer;
  late AudioPlayer weatherPlayer;
  late AudioPlayer windPlayer;
  
  // 初始化音效系统
  Future<void> initialize() async {
    ambientPlayer = AudioPlayer();
    weatherPlayer = AudioPlayer();
    windPlayer = AudioPlayer();
    
    // 预加载音效
    await _preloadAudio();
  }
  
  // 更新音效
  void updateAudio(WeatherType weather, double intensity) {
    switch (weather) {
      case WeatherType.sunny:
        _playSunnyAudio(intensity);
        break;
      case WeatherType.rainy:
        _playRainAudio(intensity);
        break;
      case WeatherType.stormy:
        _playStormAudio(intensity);
        break;
      default:
        _playDefaultAudio(intensity);
    }
  }
  
  // 播放雨天音效
  void _playRainAudio(double intensity) {
    weatherPlayer.setAsset('assets/audio/rain.mp3');
    weatherPlayer.setVolume(0.5 * intensity);
    weatherPlayer.setLoopMode(LoopMode.all);
    weatherPlayer.play();
  }
}
```

## 3. 使用示例

```dart
// 初始化环境系统
final environmentSystem = EnvironmentSystem();
await environmentSystem.initialize();

// 更新环境效果
void update(double deltaTime) {
  final timeOfDay = DateTime.now().hour / 24.0;
  environmentSystem.update(timeOfDay, deltaTime);
}

// 切换天气
void changeWeather(WeatherType newWeather) async {
  await environmentSystem.weatherSystem.transitionTo(newWeather);
}
```

## 4. 注意事项

1. **性能优化**
   - 根据设备性能调整粒子数量
   - 优化光照计算
   - 合理管理音频资源

2. **资源管理**
   - 预加载音效和纹理资源
   - 及时释放未使用的资源
   - 使用资源池管理内存

3. **用户体验**
   - 确保天气切换平滑自然
   - 优化音效过渡
   - 平衡视觉效果和性能 
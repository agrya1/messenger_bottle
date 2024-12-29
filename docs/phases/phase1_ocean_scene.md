# 第一阶段：基础场景实现

## 1. 海洋场景实现

### 1.1 海浪动画（Day 1-3）
#### Day 1: 基础波浪
- 创建 OceanPainter 类
- 实现基础 sin 波形
- 添加波浪渐变色

#### Day 2: 多层波浪
- 实现前景波浪
- 实现背景波浪
- 调整波浪叠加效果

#### Day 3: 波浪动画
- 添加波浪移动动画
- 实现波浪振幅变化
- 优化波浪真实感

### 1.2 天气效果（Day 4-5）
#### Day 4: 天气系统
- 创建天气状态枚举
- 实现天气切换系统
- 添加天气粒子效果

#### Day 5: 天气表现
- 实现雨滴效果
- 实现阳光效果
- 实现云层效果

### 1.3 音效系统（Day 6-7）
#### Day 6: 基础音效
- 集成音频播放库
- 实现海浪声效
- 实现环境音效

#### Day 7: 交互音效
- 添加投掷音效
- 添加捡拾音效
- 实现音量控制

### 1.4 优化阶段（Day 8-14）
#### Day 8-10: 调试优化
- 优化波浪性能
- 调整天气切换
- 完善音效系统

#### Day 11-14: 性能优化
- 使用 RepaintBoundary
- 优化动画性能
- 内存占用优化

## 2. 漂流瓶基础功能

### 2.1 瓶子模型（Day 1-2）
- 创建瓶子 Widget
- 实现瓶子外观
- 添加基础动画

### 2.2 投掷动画（Day 3-4）
- 实现投掷手势
- 创建抛物线动画
- 添加入水效果

### 2.3 捡拾交互（Day 5-7）
- 实现探索手势
- 添加发现动画
- 完善交互反馈

## 技术要点

### 核心类
```dart
class OceanScene extends StatefulWidget {
  @override
  State<OceanScene> createState() => _OceanSceneState();
}

class OceanPainter extends CustomPainter {
  final double waveHeight;
  final double wavePhase;
  
  @override
  void paint(Canvas canvas, Size size) {
    // 绘制海浪
  }
}

class WeatherSystem {
  final WeatherType type;
  final ParticleSystem particles;
  
  void updateWeather(WeatherType newType) {
    // 更新天气
  }
}

class SoundManager {
  static final instance = SoundManager._();
  
  void playOceanSound() {
    // 播放海浪声
  }
}
```

### 依赖配置
```yaml
dependencies:
  flutter:
    sdk: flutter
  audioplayers: ^5.0.0
  particle_field: ^1.0.0
```

## 注意事项
1. 性能优化优先级
2. 动画流畅度要求
3. 音效加载策略
4. 内存占用控制 
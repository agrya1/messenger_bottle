# 海洋系统

## 1. 系统概述
海洋系统负责生成和管理3D海洋场景，包括海面网格、波浪动画、水面材质和物理效果。

## 2. 核心功能

### 2.1 海洋网格系统
```dart
class OceanMesh {
  late Object3D mesh;
  late List<Vector3> vertices;
  late List<Vector2> uvs;
  late List<int> indices;
  final int width;
  final int height;
  final int segments;
  
  OceanMesh({
    this.width = 100,
    this.height = 100,
    this.segments = 128,
  });
  
  // 初始化网格
  void initialize() {
    // 生成顶点
    vertices = _generateVertices();
    uvs = _generateUVs();
    indices = _generateIndices();
    
    // 创建网格
    final geometry = Geometry(
      vertices: vertices,
      uvs: uvs,
      indices: indices,
    );
    
    // 应用海洋材质
    final material = OceanMaterial();
    mesh = Object3D(geometry: geometry, material: material);
  }
  
  // 生成顶点
  List<Vector3> _generateVertices() {
    final vertices = <Vector3>[];
    final segmentWidth = width / segments;
    final segmentHeight = height / segments;
    
    for (var z = 0; z <= segments; z++) {
      for (var x = 0; x <= segments; x++) {
        vertices.add(Vector3(
          x * segmentWidth - width / 2,
          0,
          z * segmentHeight - height / 2,
        ));
      }
    }
    
    return vertices;
  }
  
  // 生成UV坐标
  List<Vector2> _generateUVs() {
    final uvs = <Vector2>[];
    
    for (var z = 0; z <= segments; z++) {
      for (var x = 0; x <= segments; x++) {
        uvs.add(Vector2(
          x / segments,
          z / segments,
        ));
      }
    }
    
    return uvs;
  }
  
  // 生成索引
  List<int> _generateIndices() {
    final indices = <int>[];
    
    for (var z = 0; z < segments; z++) {
      for (var x = 0; x < segments; x++) {
        final a = x + z * (segments + 1);
        final b = x + 1 + z * (segments + 1);
        final c = x + (z + 1) * (segments + 1);
        final d = x + 1 + (z + 1) * (segments + 1);
        
        indices.addAll([a, b, c, b, d, c]);
      }
    }
    
    return indices;
  }
}
```

### 2.2 波浪系统
```dart
class WaveSystem {
  final List<WaveParams> waves;
  final OceanMesh oceanMesh;
  
  WaveSystem({
    required this.oceanMesh,
    this.waves = const [],
  });
  
  // 更新波浪
  void update(double deltaTime) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000;
    
    // 更新每个顶点的高度
    for (var i = 0; i < oceanMesh.vertices.length; i++) {
      final vertex = oceanMesh.vertices[i];
      var height = 0.0;
      
      // 计算所有波浪的叠加效果
      for (final wave in waves) {
        height += _calculateGerstnerWave(
          vertex.x,
          vertex.z,
          time,
          wave,
        );
      }
      
      vertex.y = height;
    }
    
    // 更新法线和切线
    _updateNormals();
    
    // 更新网格
    oceanMesh.mesh.updateGeometry();
  }
  
  // 计算Gerstner波浪
  double _calculateGerstnerWave(
    double x,
    double z,
    double time,
    WaveParams wave,
  ) {
    final direction = wave.direction.normalized();
    final frequency = 2 * pi / wave.wavelength;
    final phase = wave.speed * frequency;
    
    final dotProduct = direction.x * x + direction.z * z;
    final theta = frequency * dotProduct + phase * time;
    
    return wave.amplitude * sin(theta);
  }
  
  // 更新法线
  void _updateNormals() {
    // 计算每个面的法线
    final normals = List<Vector3>.filled(
      oceanMesh.vertices.length,
      Vector3.zero(),
    );
    
    for (var i = 0; i < oceanMesh.indices.length; i += 3) {
      final a = oceanMesh.vertices[oceanMesh.indices[i]];
      final b = oceanMesh.vertices[oceanMesh.indices[i + 1]];
      final c = oceanMesh.vertices[oceanMesh.indices[i + 2]];
      
      final normal = (b - a).cross(c - a).normalized();
      
      normals[oceanMesh.indices[i]] += normal;
      normals[oceanMesh.indices[i + 1]] += normal;
      normals[oceanMesh.indices[i + 2]] += normal;
    }
    
    // 归一化法线
    for (var i = 0; i < normals.length; i++) {
      normals[i].normalize();
    }
    
    oceanMesh.mesh.geometry.normals = normals;
  }
}

class WaveParams {
  final double amplitude;
  final double wavelength;
  final double speed;
  final Vector3 direction;
  final double steepness;
  
  const WaveParams({
    required this.amplitude,
    required this.wavelength,
    required this.speed,
    required this.direction,
    this.steepness = 0.5,
  });
}
```

### 2.3 海洋材质
```dart
class OceanMaterial extends Material {
  late Shader waterShader;
  late Texture normalMap;
  late Texture foamTexture;
  
  OceanMaterial() {
    // 加载着色器
    waterShader = Shader.fromAsset('assets/shaders/ocean.glsl');
    
    // 加载纹理
    normalMap = Texture.load('assets/textures/water_normal.png');
    foamTexture = Texture.load('assets/textures/foam.png');
    
    // 设置材质属性
    type = MaterialType.physical;
    color = Color(0xFF37474F);
    metalness = 0.0;
    roughness = 0.1;
    transmission = 0.9;
    
    // 设置自定义着色器
    onBeforeCompile = (shader) {
      shader.vertexShader = waterShader.vertexShader;
      shader.fragmentShader = waterShader.fragmentShader;
      
      shader.uniforms.addAll({
        'uTime': 0.0,
        'uNormalMap': normalMap,
        'uFoamTexture': foamTexture,
        'uWaveParams': WaveParams(
          amplitude: 1.0,
          wavelength: 4.0,
          speed: 2.0,
          direction: Vector3(1, 0, 1),
        ),
      });
    };
  }
  
  // 更新材质
  void update(double deltaTime) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000;
    uniforms['uTime'] = time;
  }
}
```

### 2.4 海洋物理系统
```dart
class OceanPhysics {
  final WaveSystem waveSystem;
  
  OceanPhysics({required this.waveSystem});
  
  // 获取指定位置的水面高度
  double getWaterHeight(Vector3 position) {
    // 找到最近的顶点
    final x = position.x + waveSystem.oceanMesh.width / 2;
    final z = position.z + waveSystem.oceanMesh.height / 2;
    
    final segmentWidth = waveSystem.oceanMesh.width / waveSystem.oceanMesh.segments;
    final segmentHeight = waveSystem.oceanMesh.height / waveSystem.oceanMesh.segments;
    
    final gridX = (x / segmentWidth).floor();
    final gridZ = (z / segmentHeight).floor();
    
    // 双线性插值计算高度
    return _bilinearInterpolation(
      gridX,
      gridZ,
      x % segmentWidth / segmentWidth,
      z % segmentHeight / segmentHeight,
    );
  }
  
  // 获取水面法线
  Vector3 getWaterNormal(Vector3 position) {
    // 采样周围四个点计算法线
    const delta = 0.1;
    final height = getWaterHeight(position);
    final heightX = getWaterHeight(position + Vector3(delta, 0, 0));
    final heightZ = getWaterHeight(position + Vector3(0, 0, delta));
    
    return Vector3(
      (height - heightX) / delta,
      1,
      (height - heightZ) / delta,
    ).normalized();
  }
  
  // 双线性插值
  double _bilinearInterpolation(
    int gridX,
    int gridZ,
    double fracX,
    double fracZ,
  ) {
    final vertices = waveSystem.oceanMesh.vertices;
    final segments = waveSystem.oceanMesh.segments;
    
    final i00 = gridX + gridZ * (segments + 1);
    final i10 = i00 + 1;
    final i01 = i00 + segments + 1;
    final i11 = i01 + 1;
    
    final h00 = vertices[i00].y;
    final h10 = vertices[i10].y;
    final h01 = vertices[i01].y;
    final h11 = vertices[i11].y;
    
    final x1 = lerp(h00, h10, fracX);
    final x2 = lerp(h01, h11, fracX);
    
    return lerp(x1, x2, fracZ);
  }
}
```

## 3. 使用示例

```dart
// 初始化海洋系统
final oceanMesh = OceanMesh(
  width: 100,
  height: 100,
  segments: 128,
);
oceanMesh.initialize();

final waveSystem = WaveSystem(
  oceanMesh: oceanMesh,
  waves: [
    WaveParams(
      amplitude: 1.0,
      wavelength: 4.0,
      speed: 2.0,
      direction: Vector3(1, 0, 1),
    ),
    WaveParams(
      amplitude: 0.5,
      wavelength: 8.0,
      speed: 1.5,
      direction: Vector3(-1, 0, 1),
    ),
  ],
);

final oceanPhysics = OceanPhysics(waveSystem: waveSystem);

// 更新系统
void update(double deltaTime) {
  waveSystem.update(deltaTime);
  oceanMesh.material.update(deltaTime);
}

// 获取水面信息
void getWaterInfo(Vector3 position) {
  final height = oceanPhysics.getWaterHeight(position);
  final normal = oceanPhysics.getWaterNormal(position);
}
```

## 4. 注意事项

1. **性能优化**
   - 使用LOD系统动态调整网格细节
   - 优化波浪计算
   - 使用GPU加速波浪模拟

2. **视觉效果**
   - 调整波浪参数以获得自然效果
   - 优化水面材质和反射
   - 添加泡沫和水花效果

3. **物理模拟**
   - 优化水面碰撞检测
   - 调整浮力计算
   - 处理边界情况 
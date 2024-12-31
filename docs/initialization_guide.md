# 项目初始化指南

## 1. 环境准备

### 1.1 开发环境配置
```bash
# 必需的开发工具
- Flutter SDK (最新稳定版)
- Firebase CLI
- Node.js (LTS版本)
- Git
- VS Code/Android Studio
```

### 1.2 Flutter环境配置
```bash
# 检查Flutter环境
flutter doctor

# 更新Flutter到最新稳定版
flutter upgrade

# 配置Flutter平台支持
flutter config --enable-web
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
```

## 2. 项目创建

### 2.1 创建Flutter项目
```bash
# 创建新项目
flutter create messenger_bottle

# 进入项目目录
cd messenger_bottle

# 初始化Git仓库
git init
```

### 2.2 项目结构设置
```
messenger_bottle/
├── lib/
│   ├── core/              # 核心功能
│   │   ├── config/        # 配置文件
│   │   ├── constants/     # 常量定义
│   │   ├── theme/         # 主题配置
│   │   └── utils/         # 工具类
│   ├── features/          # 功能模块
│   │   ├── auth/          # 认证模块
│   │   ├── ocean/         # 海洋场景
│   │   ├── bottle/        # 漂流瓶功能
│   │   └── user/          # 用户功能
│   ├── shared/            # 共享资源
│   │   ├── models/        # 数据模型
│   │   ├── widgets/       # 共享组件
│   │   └── services/      # 共享服务
│   └── main.dart          # 入口文件
├── test/                  # 测试目录
├── assets/               # 资源文件
└── pubspec.yaml         # 依赖配置
```

## 3. 依赖配置

### 3.1 基础依赖
```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  # 状态管理
  flutter_bloc: ^8.1.4
  provider: ^6.1.2
  
  # 路由管理
  go_router: ^13.2.0
  
  # 网络请求
  dio: ^5.4.1
  
  # 本地存储
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  
  # 工具库
  json_annotation: ^4.8.1
  freezed_annotation: ^2.4.1
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # 代码生成
  build_runner: ^2.4.8
  json_serializable: ^6.7.1
  freezed: ^2.4.7
  
  # 测试工具
  mockito: ^5.4.4
  bloc_test: ^9.1.6
```

### 3.2 3D渲染依赖
```yaml
dependencies:
  # 3D渲染
  flutter_cube: ^0.1.1
  three_dart: ^0.0.16
  
  # 物理引擎
  flutter_physics: ^1.0.8
  
  # 数学计算
  vector_math: ^2.1.4
```

## 4. 配置文件

### 4.1 环境配置
```dart
// lib/core/config/env_config.dart
enum Environment {
  development,
  staging,
  production,
}

class EnvConfig {
  final Environment environment;
  final String apiUrl;
  final String wsUrl;
  
  EnvConfig({
    required this.environment,
    required this.apiUrl,
    required this.wsUrl,
  });
  
  static EnvConfig get development => EnvConfig(
    environment: Environment.development,
    apiUrl: 'http://localhost:5001',
    wsUrl: 'ws://localhost:5001',
  );
  
  static EnvConfig get production => EnvConfig(
    environment: Environment.production,
    apiUrl: 'https://api.messenger-bottle.com',
    wsUrl: 'wss://api.messenger-bottle.com',
  );
}
```

### 4.2 主题配置
```dart
// lib/core/theme/app_theme.dart
class AppTheme {
  static ThemeData get light => ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    // 自定义主题配置
  );
  
  static ThemeData get dark => ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
    // 自定义主题配置
  );
}
```

## 5. 初始化检查清单

### 5.1 环境检查
- [ ] Flutter环境配置完成
- [ ] 开发工具安装完成
- [ ] Git仓库初始化

### 5.2 项目配置
- [ ] 项目结构创建完成
- [ ] 依赖配置完成
- [ ] 环境配置文件创建
- [ ] 主题配置完成

### 5.3 开发准备
- [ ] VS Code/Android Studio配置完成
- [ ] 代码规范工具配置完成
- [ ] 测试环境准备完成

## 6. 下一步计划

完成项目初始化后，下一步将进行：
1. Firebase环境搭建
2. 数据库设计
3. API架构设计

## 注意事项
1. 确保所有团队成员的开发环境一致
2. 遵循Flutter开发规范
3. 保持依赖版本的统一
4. 做好版本控制
5. 及时更新文档 
# 第二阶段：用户系统实现

## 1. 用户认证系统

### 1.1 注册功能（Day 1-2）
#### Day 1: 注册界面
- 创建注册表单
- 实现输入验证
- 添加隐私政策

#### Day 2: 注册逻辑
- 实现注册 API
- 添加错误处理
- 实现注册成功流程

### 1.2 登录功能（Day 3-4）
#### Day 3: 登录界面
- 创建登录表单
- 实现记住密码
- 添加快捷登录

#### Day 4: 登录逻辑
- 实现登录 API
- Token 存储机制
- 登录状态管理

### 1.3 Token 管理（Day 5）
- 实现 Token 存储
- Token 刷新机制
- 过期处理逻辑

## 2. 个人中心实现

### 2.1 用户信息（Day 6-7）
#### Day 6: 基础信息
- 个人资料展示
- 头像上传功能
- 基本信息编辑

#### Day 7: 数据统计
- 漂流瓶统计
- 互动数据展示
- 成就系统展示

### 2.2 每日限制（Day 8-9）
#### Day 8: 限制系统
- 投掷次数统计
- 捡拾次数统计
- 限制规则实现

#### Day 9: 刷新机制
- 每日重置逻辑
- 额度更新提醒
- 特殊日期处理

### 2.3 设置功能（Day 10）
- 通知设置
- 隐私设置
- 声音设置
- 主题设置

## 3. 技术实现

### 3.1 数据模型
```dart
class User {
  final String id;
  final String nickname;
  final String email;
  final String avatar;
  final UserStats stats;
  final DailyLimits limits;
  
  User({
    required this.id,
    required this.nickname,
    required this.email,
    required this.avatar,
    required this.stats,
    required this.limits,
  });
}

class UserStats {
  final int bottlesThrown;
  final int bottlesPicked;
  final int interactions;
  
  UserStats({
    required this.bottlesThrown,
    required this.bottlesPicked,
    required this.interactions,
  });
}

class DailyLimits {
  final int maxThrows;
  final int maxPicks;
  final int remainingThrows;
  final int remainingPicks;
  final DateTime lastResetTime;
  
  DailyLimits({
    required this.maxThrows,
    required this.maxPicks,
    required this.remainingThrows,
    required this.remainingPicks,
    required this.lastResetTime,
  });
}
```

### 3.2 状态管理
```dart
class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;
  
  Future<void> login(String email, String password) async {
    // 登录逻辑
  }
  
  Future<void> register(UserRegistrationData data) async {
    // 注册逻辑
  }
  
  Future<void> updateDailyLimits() async {
    // 更新每日限制
  }
}
```

### 3.3 API 服务
```dart
class UserService {
  final Dio _dio;
  
  Future<User> login(String email, String password) async {
    // 登录请求
  }
  
  Future<User> register(Map<String, dynamic> data) async {
    // 注册请求
  }
  
  Future<void> updateProfile(Map<String, dynamic> data) async {
    // 更新个人信息
  }
}
```

## 4. 测试计划

### 4.1 单元测试
- 用户模型测试
- API 服务测试
- 状态管理测试

### 4.2 集成测试
- 登录流程测试
- 注册流程测试
- 限制系统测试

### 4.3 UI 测试
- 表单验证测试
- 错误提示测试
- 页面跳转测试

## 5. 注意事项

### 5.1 安全考虑
- 密码加密存储
- 敏感信息保护
- Token 安全管理

### 5.2 用户体验
- 错误提示友好
- 加载状态展示
- 操作反馈及时

### 5.3 性能优化
- 缓存策略
- 图片加载优化
- 状态更新优化 
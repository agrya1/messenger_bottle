# 后端系统实现指南

## 1. 后端架构设计

### 1.1 系统架构
```
后端系统
├── 应用层 (API)
│   ├── RESTful接口
│   ├── WebSocket服务
│   └── 认证中间件
├── 业务层 (Service)
│   ├── 用户服务
│   ├── 漂流瓶服务
│   ├── 会员服务
│   └── 支付服务
├── 数据层 (Repository)
│   ├── 数据访问
│   ├── 缓存管理
│   └── 数据同步
└── 基础设施层
    ├── 数据库
    ├── 缓存系统
    ├── 消息队列
    └── 文件存储
```

### 1.2 技术栈选择
- **服务器**: Firebase Cloud Functions
- **数据库**: Firebase Firestore
- **缓存**: Redis
- **消息队列**: Firebase Cloud Pub/Sub
- **文件存储**: Firebase Storage
- **API网关**: Firebase Functions
- **监控**: Firebase Monitoring

### 1.3 数据库设计
```typescript
// 用户集合
interface UserCollection {
  id: string;
  email: string;
  profile: {
    nickname: string;
    avatar: string;
    createdAt: Timestamp;
  };
  subscription: {
    type: SubscriptionType;
    expiredAt: Timestamp;
  };
  bottleStats: {
    sent: number;
    received: number;
    replied: number;
  };
}

// 漂流瓶集合
interface BottleCollection {
  id: string;
  senderId: string;
  content: {
    text: string;
    images: string[];
    emotion: EmotionType;
  };
  status: BottleStatus;
  location: {
    latitude: number;
    longitude: number;
  };
  createdAt: Timestamp;
  pickedAt?: Timestamp;
  pickedBy?: string;
}

// 交互记录集合
interface InteractionCollection {
  id: string;
  bottleId: string;
  userId: string;
  type: InteractionType;
  content: string;
  createdAt: Timestamp;
}
```

## 2. API设计

### 2.1 RESTful API
```typescript
// 用户相关API
interface UserAPI {
  // 用户注册
  POST /api/users/register
  Request {
    email: string;
    password: string;
    nickname: string;
  }
  Response {
    userId: string;
    token: string;
  }

  // 用户登录
  POST /api/users/login
  Request {
    email: string;
    password: string;
  }
  Response {
    token: string;
    user: UserProfile;
  }

  // 获取用户信息
  GET /api/users/:userId
  Response {
    user: UserProfile;
  }
}

// 漂流瓶相关API
interface BottleAPI {
  // 投放漂流瓶
  POST /api/bottles
  Request {
    content: string;
    images?: string[];
    emotion?: EmotionType;
    location?: Location;
  }
  Response {
    bottleId: string;
  }

  // 捡到漂流瓶
  POST /api/bottles/:bottleId/pick
  Response {
    bottle: BottleDetail;
  }

  // 回复漂流瓶
  POST /api/bottles/:bottleId/reply
  Request {
    content: string;
  }
  Response {
    replyId: string;
  }
}
```

### 2.2 WebSocket API
```typescript
// 实时通信接口
interface WebSocketEvents {
  // 漂流瓶状态更新
  'bottle:status' {
    bottleId: string;
    status: BottleStatus;
    timestamp: number;
  }

  // 新消息通知
  'message:new' {
    type: MessageType;
    content: any;
    timestamp: number;
  }

  // 系统通知
  'system:notification' {
    type: NotificationType;
    message: string;
    timestamp: number;
  }
}
```

## 3. 后端服务实现

### 3.1 用户服务
```typescript
class UserService {
  constructor(
    private userRepo: UserRepository,
    private authService: AuthService,
  ) {}

  async register(data: RegisterDTO): Promise<User> {
    // 验证邮箱是否已存在
    const exists = await this.userRepo.findByEmail(data.email);
    if (exists) {
      throw new ConflictException('Email already exists');
    }

    // 创建用户
    const user = await this.userRepo.create({
      ...data,
      password: await this.authService.hashPassword(data.password),
    });

    return user;
  }

  async login(email: string, password: string): Promise<LoginResult> {
    // 验证用户
    const user = await this.userRepo.findByEmail(email);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // 验证密码
    const isValid = await this.authService.verifyPassword(
      password,
      user.password,
    );
    if (!isValid) {
      throw new UnauthorizedException('Invalid password');
    }

    // 生成token
    const token = await this.authService.generateToken(user);

    return { user, token };
  }
}
```

### 3.2 漂流瓶服务
```typescript
class BottleService {
  constructor(
    private bottleRepo: BottleRepository,
    private userRepo: UserRepository,
    private eventEmitter: EventEmitter,
  ) {}

  async createBottle(data: CreateBottleDTO, userId: string): Promise<Bottle> {
    // 创建漂流瓶
    const bottle = await this.bottleRepo.create({
      ...data,
      senderId: userId,
      status: BottleStatus.FLOATING,
      createdAt: new Date(),
    });

    // 发送事件
    this.eventEmitter.emit('bottle:created', bottle);

    return bottle;
  }

  async pickBottle(bottleId: string, userId: string): Promise<Bottle> {
    // 获取漂流瓶
    const bottle = await this.bottleRepo.findById(bottleId);
    if (!bottle) {
      throw new NotFoundException('Bottle not found');
    }

    // 更新状态
    bottle.status = BottleStatus.PICKED;
    bottle.pickedBy = userId;
    bottle.pickedAt = new Date();

    await this.bottleRepo.update(bottle);

    // 发送事件
    this.eventEmitter.emit('bottle:picked', bottle);

    return bottle;
  }
}
```

### 3.3 会员服务
```typescript
class SubscriptionService {
  constructor(
    private subscriptionRepo: SubscriptionRepository,
    private paymentService: PaymentService,
  ) {}

  async subscribe(
    userId: string,
    plan: SubscriptionPlan,
  ): Promise<Subscription> {
    // 创建支付
    const payment = await this.paymentService.createPayment({
      userId,
      amount: plan.price,
      currency: 'USD',
    });

    // 等待支付完成
    await this.paymentService.waitForPayment(payment.id);

    // 创建订阅
    const subscription = await this.subscriptionRepo.create({
      userId,
      plan,
      startDate: new Date(),
      endDate: this.calculateEndDate(plan),
    });

    return subscription;
  }

  async checkSubscription(userId: string): Promise<boolean> {
    const subscription = await this.subscriptionRepo.findByUserId(userId);
    if (!subscription) {
      return false;
    }

    return subscription.endDate > new Date();
  }
}
```

## 4. 数据库优化

### 4.1 索引设计
```typescript
// 用户集合索引
db.collection('users').createIndex({ email: 1 }, { unique: true });
db.collection('users').createIndex({ 'subscription.expiredAt': 1 });

// 漂流瓶集合索引
db.collection('bottles').createIndex({ senderId: 1 });
db.collection('bottles').createIndex({ status: 1 });
db.collection('bottles').createIndex({ 
  location: '2dsphere',
  status: 1,
  createdAt: -1 
});

// 交互记录索引
db.collection('interactions').createIndex({ 
  bottleId: 1,
  createdAt: -1 
});
```

### 4.2 查询优化
```typescript
// 使用复合索引优化查询
const bottles = await db.collection('bottles')
  .find({
    status: 'FLOATING',
    location: {
      $near: {
        $geometry: {
          type: 'Point',
          coordinates: [longitude, latitude],
        },
        $maxDistance: 5000,
      },
    },
  })
  .sort({ createdAt: -1 })
  .limit(10);

// 使用投影优化返回字段
const users = await db.collection('users')
  .find({}, { 
    email: 1, 
    profile: 1,
    subscription: 1 
  });
```

## 5. 性能优化

### 5.1 缓存策略
```typescript
class CacheService {
  constructor(private redis: Redis) {}

  async getOrSet<T>(
    key: string,
    callback: () => Promise<T>,
    ttl: number = 3600,
  ): Promise<T> {
    // 尝试从缓存获取
    const cached = await this.redis.get(key);
    if (cached) {
      return JSON.parse(cached);
    }

    // 执行回调获取数据
    const data = await callback();

    // 存入缓存
    await this.redis.set(
      key,
      JSON.stringify(data),
      'EX',
      ttl,
    );

    return data;
  }

  async invalidate(pattern: string): Promise<void> {
    const keys = await this.redis.keys(pattern);
    if (keys.length > 0) {
      await this.redis.del(...keys);
    }
  }
}
```

### 5.2 数据库优化
```typescript
// 批量操作优化
async function batchUpdate(bottles: Bottle[]): Promise<void> {
  const batch = db.batch();
  
  for (const bottle of bottles) {
    const ref = db.collection('bottles').doc(bottle.id);
    batch.update(ref, { status: bottle.status });
  }

  await batch.commit();
}

// 分页查询优化
async function paginateBottles(
  lastId: string | null,
  limit: number,
): Promise<Bottle[]> {
  let query = db.collection('bottles')
    .orderBy('createdAt', 'desc')
    .limit(limit);

  if (lastId) {
    const lastDoc = await db.collection('bottles').doc(lastId).get();
    query = query.startAfter(lastDoc);
  }

  return query.get();
}
```

## 6. 安全措施

### 6.1 认证中间件
```typescript
async function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) {
      throw new UnauthorizedException('No token provided');
    }

    const decoded = await verifyToken(token);
    req.user = decoded;

    next();
  } catch (error) {
    next(error);
  }
}
```

### 6.2 数据验证
```typescript
class BottleValidator {
  static createBottleSchema = Joi.object({
    content: Joi.string().required().max(1000),
    images: Joi.array().items(Joi.string().uri()).max(5),
    emotion: Joi.string().valid(...Object.values(EmotionType)),
    location: Joi.object({
      latitude: Joi.number().required(),
      longitude: Joi.number().required(),
    }),
  });

  static validate(data: any): void {
    const { error } = this.createBottleSchema.validate(data);
    if (error) {
      throw new ValidationException(error.message);
    }
  }
}
```

## 7. 测试策略

### 7.1 单元测试
```typescript
describe('UserService', () => {
  let userService: UserService;
  let userRepo: MockUserRepository;

  beforeEach(() => {
    userRepo = new MockUserRepository();
    userService = new UserService(userRepo);
  });

  describe('register', () => {
    it('should create new user', async () => {
      const userData = {
        email: 'test@example.com',
        password: 'password123',
        nickname: 'Test User',
      };

      const user = await userService.register(userData);

      expect(user).toBeDefined();
      expect(user.email).toBe(userData.email);
      expect(user.nickname).toBe(userData.nickname);
    });

    it('should throw error if email exists', async () => {
      const userData = {
        email: 'existing@example.com',
        password: 'password123',
        nickname: 'Test User',
      };

      userRepo.findByEmail.mockResolvedValue({ id: '1', ...userData });

      await expect(userService.register(userData))
        .rejects
        .toThrow('Email already exists');
    });
  });
});
```

### 7.2 集成测试
```typescript
describe('Bottle API', () => {
  let app: Express;
  let token: string;

  beforeAll(async () => {
    app = await createTestApp();
    token = await getTestToken();
  });

  describe('POST /api/bottles', () => {
    it('should create new bottle', async () => {
      const response = await request(app)
        .post('/api/bottles')
        .set('Authorization', `Bearer ${token}`)
        .send({
          content: 'Test bottle',
          emotion: 'HAPPY',
        });

      expect(response.status).toBe(201);
      expect(response.body.bottleId).toBeDefined();
    });

    it('should validate request body', async () => {
      const response = await request(app)
        .post('/api/bottles')
        .set('Authorization', `Bearer ${token}`)
        .send({});

      expect(response.status).toBe(400);
      expect(response.body.message).toContain('content');
    });
  });
});
```

### 7.3 性能测试
```typescript
describe('Performance Tests', () => {
  it('should handle 100 concurrent requests', async () => {
    const requests = Array(100).fill(null).map(() => 
      request(app)
        .get('/api/bottles/random')
        .set('Authorization', `Bearer ${token}`)
    );

    const responses = await Promise.all(requests);
    
    for (const response of responses) {
      expect(response.status).toBe(200);
    }
  });

  it('should respond within 100ms', async () => {
    const start = Date.now();
    
    await request(app)
      .get('/api/bottles/random')
      .set('Authorization', `Bearer ${token}`);
    
    const duration = Date.now() - start;
    expect(duration).toBeLessThan(100);
  });
});
```

## 8. 监控与日志

### 8.1 性能监控
```typescript
class PerformanceMonitor {
  private metrics: Map<string, Metric>;

  constructor() {
    this.metrics = new Map();
  }

  async trackOperation<T>(
    name: string,
    operation: () => Promise<T>,
  ): Promise<T> {
    const start = Date.now();
    try {
      const result = await operation();
      this.recordSuccess(name, Date.now() - start);
      return result;
    } catch (error) {
      this.recordError(name, error);
      throw error;
    }
  }

  private recordSuccess(name: string, duration: number): void {
    const metric = this.getMetric(name);
    metric.totalCalls++;
    metric.totalDuration += duration;
    metric.lastDuration = duration;
  }

  private recordError(name: string, error: any): void {
    const metric = this.getMetric(name);
    metric.errors.push({
      timestamp: new Date(),
      error: error.message,
    });
  }
}
```

### 8.2 日志系统
```typescript
class Logger {
  constructor(private context: string) {}

  info(message: string, data?: any): void {
    this.log('INFO', message, data);
  }

  error(message: string, error?: Error): void {
    this.log('ERROR', message, {
      error: error?.message,
      stack: error?.stack,
    });
  }

  private log(level: string, message: string, data?: any): void {
    const log = {
      timestamp: new Date().toISOString(),
      level,
      context: this.context,
      message,
      data,
    };

    console.log(JSON.stringify(log));
  }
}
```

## 9. 部署流程

### 9.1 环境配置
```yaml
# Firebase配置
firebase:
  development:
    projectId: "bottle-dev"
    location: "us-central1"
    
  staging:
    projectId: "bottle-staging"
    location: "us-central1"
    
  production:
    projectId: "bottle-prod"
    location: "us-central1"

# 环境变量
env_variables:
  development:
    NODE_ENV: "development"
    LOG_LEVEL: "debug"
    
  staging:
    NODE_ENV: "staging"
    LOG_LEVEL: "info"
    
  production:
    NODE_ENV: "production"
    LOG_LEVEL: "warn"
```

### 9.2 部署脚本
```bash
#!/bin/bash

# 部署函数
deploy_functions() {
  local env=$1
  echo "Deploying functions to $env environment..."
  
  # 加载环境变量
  source .env.$env
  
  # 构建项目
  npm run build
  
  # 部署到Firebase
  firebase use $env
  firebase deploy --only functions
  
  echo "Deployment completed!"
}

# 执行部署
ENV=${1:-development}
deploy_functions $ENV
```

## 10. 维护计划

### 10.1 日常维护
- 日志分析和监控
- 性能指标跟踪
- 数据库备份
- 安全更新

### 10.2 应急预案
- 服务降级策略
- 数据恢复流程
- 回滚机制
- 紧急联系人 
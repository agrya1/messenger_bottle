# 漂流瓶内容展示系统

## 1. 系统概述
内容展示系统负责管理漂流瓶内容的展示、动画效果和交互逻辑。

## 2. 核心功能

### 2.1 内容管理
```dart
class BottleContent {
  final String? text;
  final List<String> images;
  final String? video;
  final EmotionType? emotion;
  final DateTime timestamp;
  
  BottleContent({
    this.text,
    this.images = const [],
    this.video,
    this.emotion,
    required this.timestamp,
  });
}

class BottleContentSystem {
  final BottleModel model;
  final AnimationController animationController;
  
  // 瓶子内容
  late BottleContent content;
  late bool hasNewMessage;
  
  // 动画控制器
  late AnimationController openAnimationController;
  late AnimationController glowAnimationController;
  
  // 展示瓶子内容
  Future<void> showContent(BuildContext context) async {
    // 播放打开动画
    await _playOpenAnimation();
    
    // 显示内容对话框
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BottleContentDialog(
        content: content,
        animation: openAnimationController,
      ),
    );
    
    // 播放关闭动画
    await _playCloseAnimation();
  }
}
```

### 2.2 动画效果
```dart
class BottleAnimations {
  // 瓶子打开动画
  Future<void> _playOpenAnimation() async {
    openAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    // 创建瓶子旋转动画
    final rotateAnimation = Tween<double>(
      begin: 0.0,
      end: pi / 6,
    ).animate(
      CurvedAnimation(
        parent: openAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // 创建瓶盖打开动画
    final capAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: openAnimationController,
        curve: Curves.easeOut,
      ),
    );
    
    // 播放动画
    model.rotate(rotateAnimation.value);
    model.openCap(capAnimation.value);
    await openAnimationController.forward();
  }
  
  // 新消息提示动画
  void _playNewMessageAnimation() {
    glowAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    final glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: glowAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    glowAnimation.addListener(() {
      model.updateGlowEffect(glowAnimation.value);
    });
  }
}
```

### 2.3 UI 组件
```dart
class BottleContentDialog extends StatelessWidget {
  final BottleContent content;
  final AnimationController animation;
  
  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'bottle_content',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: ContentView(content: content),
        ),
      ),
    );
  }
}

class ContentView extends StatelessWidget {
  final BottleContent content;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标题栏
        _buildHeader(),
        
        // 内容区域
        _buildContent(),
        
        // 情感图标
        if (content.emotion != null)
          _buildEmotionIcon(),
          
        // 互动按钮
        _buildActionButtons(),
      ],
    );
  }
  
  Widget _buildContent() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文本内容
          if (content.text != null)
            Text(
              content.text!,
              style: TextStyle(fontSize: 16),
            ),
          
          // 图片内容
          if (content.images.isNotEmpty)
            ImageGridView(images: content.images),
            
          // 视频内容
          if (content.video != null)
            VideoPlayer(videoUrl: content.video!),
        ],
      ),
    );
  }
}
```

## 3. 使用示例

```dart
// 初始化内容展示系统
final contentSystem = BottleContentSystem(
  model: bottleModel,
  animationController: AnimationController(vsync: this),
);

// 显示瓶子内容
void onBottleTapped() async {
  await contentSystem.showContent(context);
}

// 设置新消息
void onNewMessage(BottleContent newContent) {
  contentSystem.content = newContent;
  contentSystem.hasNewMessage = true;
  contentSystem._playNewMessageAnimation();
}
```

## 4. 注意事项

1. **性能优化**
   - 使用懒加载加载图片和视频内容
   - 合理管理动画资源
   - 及时释放不需要的资源

2. **用户体验**
   - 保持动画流畅
   - 提供适当的反馈
   - 处理各种异常情况

3. **内容管理**
   - 支持多种内容格式
   - 处理内容加载失败
   - 提供内容预览功能 
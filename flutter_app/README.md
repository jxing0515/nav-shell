# Nav Shell (Flutter)

原生导航壳 + 系统 WebView 的网址导航应用（React 版移植）。

## 功能
- 横屏=左侧栏，竖屏=底部栏（原生 Flutter 组件）
- 单例系统 WebView 显示当前页面（非 iframe）
- 单击切换 / 双击刷新 / 长按管理（编辑·删除）
- 设置页：增删改、拖拽排序（shared_preferences 持久化）

## 运行
```bash
flutter pub get
flutter run
```

## 构建 APK
```bash
flutter build apk --debug
```

## 本机环境注意
- 必须把 PUB_CACHE 放在与项目同盘（如 `D:/\.pub-cache`），否则 Kotlin 增量编译报
  “this and base files have different roots” 跨盘错误。
- Gradle 已通过 `android/gradle.properties` 锁定 JDK 21。
- Windows 桌面端 WebView 需另装 `webview_flutter_windows`（当前未启用）。

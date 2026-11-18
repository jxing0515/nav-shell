# nav-shell

一个轻量的 **Flutter 导航壳**，把多个自建服务 / 网页聚合到一个可配置的导航页里；附一套在自建 NAS 上部署 **AzurPilot**（Python 自动化工具）的容器化脚本与排障备忘。

两个部分互相独立，可以只用其中一个。

---

## 一、flutter_app —— 导航壳 App

把常用网页（NAS 面板、自建服务、常用站点）做成底部导航 + WebView 容器，配置项可增删改，支持备份导出。

### 功能

- **可配置导航项**：标题、URL、图标的增删改与排序（`lib/settings/page_form.dart`、`lib/models/page_item.dart`）
- **WebView 容器**：单页内嵌展示，带加载态与返回处理（`lib/widgets/web_content.dart`）
- **底部导航栏**：图标 + 文字，选中态高亮（`lib/widgets/nav_bar.dart`、`lib/widgets/nav_item.dart`）
- **设置页**：导航项管理、校验（URL 合法性与重名检查，`lib/utils/validators.dart`）
- **备份与恢复**：导航配置导出/导入，用于换机或误删后还原（`lib/utils/backup.dart`、`lib/settings/backup_actions.dart`）
- **状态管理**：`AppStore` + `StoreScope`（`InheritedNotifier` 模式），不依赖第三方状态库

### 结构

```
flutter_app/
├── lib/
│   ├── main.dart               # 入口，App 初始化
│   ├── home/home_page.dart     # 主页面：导航项 + WebView 容器切换
│   ├── widgets/                # nav_bar / nav_item / web_content
│   ├── settings/               # 设置页、页面表单、备份动作
│   ├── store/                  # app_store（状态）、store_scope（注入）
│   ├── utils/                  # backup（导入导出）、validators（校验）
│   └── models/page_item.dart   # 导航项数据模型
└── pubspec.yaml                # 版本 1.0.3+4
```

### 构建

```bash
cd flutter_app
flutter pub get
flutter build apk --release        # Android
flutter build windows --release    # Windows（桌面端）
```

Flutter SDK 要求见 `pubspec.yaml` 的 `environment.sdk`。

---

## 二、NAS 部署脚本 —— AzurPilot 容器化

把 AzurPilot 在飞牛 fnOS（Linux）上用 Docker Compose 跑起来，并保留一套可重放的本地补丁，避免重新拉代码后被冲掉。

### 脚本

| 文件 | 作用 |
|---|---|
| `apply_local_patches.py` | 一次性应用全部本地补丁：apt 阿里云源、镜像内补 node/npm、容器名、镜像 tag、WebUI 端口 |
| `patch_dockerfile_apt.py` | 只改 Dockerfile 的 apt 源（国内网络下构建必需） |
| `patch_dockerfile_apt2.py` | apt 源补丁的第二版（含依赖修正） |
| `patch_dockerfile_node.py` | 在运行镜像内安装 node/npm，用于前端产物缺失时自愈 |

> `git checkout -f` / `git reset --hard` 之后**必须重跑** `apply_local_patches.py`，否则上述补丁全部丢失。

### 部署要点（详见 `README-nas-azurpilot.md`）

- **双实例编排**：dir1（稳定版，非 React 前端）与 dir2（dev_frontend 分支，React 新前端），各自独立数据卷与镜像 tag，WebUI 端口隔离 `25548` / `25549`
- **两实例不能同时运行**：它们驱动同一个 redroid 模拟器，双开必然互抢操作——按需在热备与在用之间切换
- **健康检查**：原配置把探针端口写成了反向代理端口（永远返回成功 → 假 healthy），已改为服务真实端口
- **前端产物**：compose 整目录挂载会盖掉镜像内构建好的 `frontend/dist`，已把镜像内产物播种到宿主目录；指纹变化时启动脚本自动 `npm ci && npm run build` 自愈
- **镜像拉取**：`registry-1.docker.io` 直连超时，改走 NAS 镜像源
- **仓库历史修复**：上游仓库存在缺失父提交，导致 `git log` / `rev-list` 拓扑遍历直接 fatal；用 `git replace --graft` 打桩绕过（只改本地遍历视图，不动工作树）

---

## 说明

- `flutter_app` 为独立开发的导航壳应用（版本 1.0.3+4）
- NAS 部署脚本与备忘源于本人自建环境的真实部署过程，路径 / 端口 / 内网地址已做占位符处理，按自己环境替换即可
- 仓库不含任何凭据、密钥或真实网络地址

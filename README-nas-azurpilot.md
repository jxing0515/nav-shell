# AzurPilot 双目录部署备忘

## 两个目录

| 目录 | 分支 | 镜像 | 容器名 | WebUI 端口 | 状态 |
|------|------|------|--------|-----------|------|
| `/vol1/1000/docker/AzurPilot`  (dir1) | `master` @ 850f0ebbe，非 React | `alas:py314` | alas | 25548（lucky 反代 22267 → 25548） | 热备，**已停止** |
| `/vol1/1000/docker/AzurPilot2` (dir2) | `dev_frontend` @ 44d47efa7，React 新前端 | `alas:py314-dev-20260914` | alas2 | 25549（需在 lucky 里自行加反代） | 运行中 |

- dir1 的 venv 卷：`azurpilot_alas-venv`；dir2 的 venv 卷：`azurpilot2_alas-venv`（自动独立，已从镜像播种）。
- 两个实例**同时只能跑一个**：它们驱动同一个模拟器（redroid / `<NAS_IP>:5555`），双开必然互相抢操作。
- dir1 的 compose 仍是 `restart: unless-stopped`，`docker stop alas` 后不会自己起来；开机自启相关策略按需自行调整。

## 更新 dir2（React 版）

```bash
cd /vol1/1000/docker/AzurPilot2
git fetch origin
git checkout -f -B dev_frontend origin/dev_frontend   # ← 会冲掉下面的本地补丁
python3 /vol1/1000/docker/AzurPilot2-patches/apply_local_patches.py
docker compose build
docker compose up -d
```

`git checkout -f` / `git reset --hard` 之后**必须**重跑 `apply_local_patches.py`，否则会丢失：
apt 阿里云源、运行镜像里的 node/npm、容器名 `alas2`、镜像 tag、25549 端口。

## 回滚到 dir1（非 React 稳定版）

```bash
docker stop alas2
cd /vol1/1000/docker/AzurPilot && docker compose up -d
```

## 已知坑

1. **前端产物被 bind mount 遮住**：compose 把整个目录挂到 `/app/AzurPilot`，会盖掉镜像里构建好的
   `frontend/dist`。已把镜像内的 dist 播种到 dir2 宿主目录 `frontend/dist/`（指纹一致，启动不再需要 npm）。
   万一指纹变了：镜像内已带 node/npm，启动时会自动 `npm ci && npm run build` 自愈（需要外网）。
2. **`uv.lock` 未被 master/dev 跟踪**（只有 dev_frontend 跟踪）。所以 dir1 重建镜像时 `uv sync --frozen`
   会报 “Unable to find lockfile”；要么先 `uv lock`，要么继续用现成的 `alas:py314` 镜像。
3. **healthcheck 原为 22267**（那是 lucky 的端口，永远返回成功 → 假 healthy），已改为真实端口。
4. 构建走 `docker.fnnas.com` 镜像；`registry-1.docker.io` 直连是超时的。
5. **仓库历史有洞（两个目录都中招，与本次部署无关）**：`081d1369`（2025-11-14 merge「紧急委托装备识别优化」）
   的两个父提交 `f7e5c0b5`、`9dc3651e` 在对象库里不存在，导致 `git log`/`rev-list` 这类
   **拓扑遍历**直接 fatal（症状：更新器页「无法读取提交记录」、无法比对上游、ff-only 更新做不了祖先判断）。
   已用 graft 让遍历绕过这两个缺失父提交：

   ```bash
   git replace --graft 081d1369a8d53ae243732b94a01a014d1b7ee506   # 只改本地遍历视图，不动工作树
   ```

   两个目录都已执行（`refs/replace/081d1369...`）。`git fsck` 仍会报这两条 missing（原始对象没变，属于噪声）。
   想彻底修好（补齐 876MB 历史）：`git fetch --refetch origin` 或重新 clone 后替换 `.git`；
   撤销本补丁用 `git replace -d 081d1369a8d53ae243732b94a01a014d1b7ee506`。

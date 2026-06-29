# wloc 自部署副本

这是 [Yu9191/wloc](https://github.com/Yu9191/wloc)（Apple WLOC 网络定位修改）的**私有自部署副本**，用来部署并维护我自己的 Cloudflare Worker 实例，替换公共实例 `wloc-spoofer.wloc.workers.dev`。

> 项目原理、模块订阅、快捷指令等说明见仓库根的 [`README.md`](README.md)（保持与上游一致，本文件只记录自部署相关内容）。

---

## 我的部署信息

| 项 | 内容 |
|---|---|
| 平台 | Cloudflare Workers |
| Cloudflare 账号 | `realyn@qq.com` |
| **专属地址** | **https://wloc-spoofer.realyn.workers.dev** |
| 部署配置 | `worker/wrangler.jsonc`（worker 名 `wloc-spoofer`，入口 `src/index.js`） |
| 部署命令 | `worker/` 下 `npm run deploy`（即 `wrangler deploy --minify`） |

---

## 日常使用

- **选点页面**：开着代理，用 Safari 打开 https://wloc-spoofer.realyn.workers.dev/ ，建议「添加到主屏幕」。此页面已是自己的实例，无需任何改动。
- **快捷指令（可选）**：iCloud 快捷指令默认调用公共地址 `wloc-spoofer.wloc.workers.dev`。想走自己的实例，在 iPhone「快捷指令」App 里把 URL 改成 `wloc-spoofer.realyn.workers.dev`（设备上手动操作，不改也能用公共实例）。

---

## 一键更新 + 部署

仓库根提供 [`deploy.sh`](deploy.sh)，一条命令完成「同步上游 → 部署 → 推送私有仓库」：

```bash
./deploy.sh             # 同步上游 + 部署 + 推送
./deploy.sh --no-sync   # 跳过上游同步，仅部署当前代码
./deploy.sh --no-push   # 部署后不推送到私有仓库
```

脚本会先检查 Cloudflare 登录状态（未登录会提示 `npx wrangler login`）。

---

## 手动操作（脚本背后做的事）

```bash
# 1. 同步上游最新代码
git fetch upstream
git merge upstream/main

# 2. 部署
cd worker
npm install          # 依赖变动时才需要
npm run deploy

# 3. 推送到自己的私有仓库
cd ..
git push origin main
```

---

## Git 远程配置

| remote | 地址 | 用途 |
|--------|------|------|
| `origin` | `github.com/realyn/wloc-deploy`（私有） | 我自己的部署副本，推送目标 |
| `upstream` | `github.com/Yu9191/wloc` | 上游原始项目，拉取更新来源 |

因为本副本只**新增** `deploy.sh` / `DEPLOY.md`、不改动上游已有文件，`git merge upstream/main` 通常不会冲突。

---

## 首次部署记录

部署于 2026-06-29，步骤：

```bash
cd worker
npm install
npx wrangler login      # 浏览器 OAuth 授权（一次性）
npm run deploy          # 输出专属地址
```

验证：`/` 返回选点页面 HTTP 200；`/api/parse` 坐标 GCJ-02→WGS84 转换正确。

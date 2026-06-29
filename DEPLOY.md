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

## 在 iPhone 上使用（Surge）

> 菜单名按 Surge 5（中/英关键词都标了），不同版本路径可能略有差异。

**1. 安装 wloc 模块**
Surge 底部「模块 / Modules」→ 右上 **＋ / 安装新模块** →「从 URL 安装 / Install from URL」，粘贴：
```
https://raw.githubusercontent.com/Yu9191/wloc/refs/heads/main/modules/wloc.sgmodule
```
安装后确保模块**开关打开**。模块会自动加入脚本规则和 MITM 主机名 `gs-loc.apple.com / gs-loc-cn.apple.com`。

**2. MITM 根证书（一次性）**
1. Surge →「更多 / More」→ **MitM** → Root CA Certificate → 生成 / Install
2. 设置 → 通用 → VPN 与设备管理 → 安装 Surge CA 描述文件
3. 设置 → 通用 → 关于本机 → **证书信任设置** → 对 Surge CA 打开**完全信任**（← 最易漏）
4. 回 Surge More → MitM，确认 **MitM 总开关 ON**

**3. 开启 Surge**：首页主开关打开，顶部出现 VPN 图标。

**4. 设置位置**：Safari 打开 https://wloc-spoofer.realyn.workers.dev/ → 选点 → 「储存到设备」→ ✓。

**5. 用「请求 / Requests」验证（Surge 独有）**
底部「请求 / Requests」搜 `gs-loc`：
- 储存时见 `gs-loc.apple.com/wloc-settings/save` 且带 🔓 解密标记 → 写入成功
- 定位触发时见 `/clls/wloc` 被脚本处理 → 坐标已替换
- 看不到 🔓 → MITM 没生效，回查第 2 步证书信任

**6. 验证定位（⚠️ iOS 26+ 必须重启）**
iOS 26/27+ 会缓存旧定位，改了可能没变化，必须重启清缓存：
选点储存 → 开飞行模式 → 关定位服务 → **重启** → 关飞行模式(WiFi 也关) → 连 Surge(VPN 图标) → 开定位服务 → 看地图。iOS 15~18 通常无需重启。

**恢复真实定位**（任选）：关闭 wloc 模块（iOS 26+ 关后重启）/ 运行快捷指令「wloc 清理恢复位置」/ 执行 `$persistentStore.write(null, "wloc_settings")` 进入透传模式。

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

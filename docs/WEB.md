# PixEz Web

PixEz 现在可以直接以网页形式运行，并通过 Docker Compose 一键部署。

Web 端不是简单的 `flutter build web`：Pixiv 的接口没有 CORS 头、图片域名
`i.pximg.net` 校验 `Referer`、浏览器又禁止设置 `Host` 头，所以浏览器无法直接
访问 Pixiv。项目内置了 nginx 与一个小的 Node 会话后端：Pixiv Refresh Token 只
保存在服务端，浏览器只持有 HttpOnly 会话 Cookie。

```
Browser ──► nginx :80 ──┬── /              Flutter bundle (build/web)
                        ├── /login         登录页（Node 后端）
                        ├── /api/          会话 API（Node 后端）
                        ├── /pixiv-api/    Node 后端 → app-api.pixiv.net（注入 token）
                        ├── /pixiv-oauth/  oauth.secure.pixiv.net
                        ├── /pximg/        i.pximg.net（代理，可切换为直连图床）
                        ├── /spximg/       s.pximg.net
                        ├── /pixivision/   www.pixivision.net
                        └── /saucenao/     saucenao.com
```

## 快速开始（Docker Compose）

```bash
git clone git@github.com:luvhx/pixez-flutter-docker.git
cd pixez-flutter-docker
cp .env.example .env          # 设置 PIXEZ_SETUP_TOKEN
docker compose up -d --build
```

打开 <http://localhost:7493>，会跳转到 `/login`：输入 `.env` 里的
`PIXEZ_SETUP_TOKEN` 和一个 Pixiv Refresh Token 完成首次配置。

常用环境变量（可写入 `.env`）：

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `PIXEZ_PORT` | `7493` | 宿主机映射端口 |
| `PIXEZ_TAG` | `latest` | 构建出的镜像 tag |
| `FLUTTER_VERSION` | `3.47.7` | Docker 构建时下载的 Flutter SDK 版本（需满足 Dart ≥ 3.11.5）|
| `TZ` | `Asia/Shanghai` | 容器时区 |
| `PIXEZ_SETUP_TOKEN` | 无（必填）| `/login` 首次配置/更换账号的管理口令 |

### 登录与会话

- 采用**单个共享 Pixiv 账号**：管理员在 `/login` 配置一次，所有访问者共用。
- Refresh Token 只保存在容器卷 `pixez-state` 的 `/data/state.json` 中，浏览器
  只会拿到 `pixez_session` 这个 HttpOnly 签名 Cookie。
- 未登录访问首页会自动跳转到 `/login`；设置页的「Logout」会清除 Cookie 并回到
  登录页，服务端账号会保留，直到用管理口令重新配置。
- 更换账号：重新打开 `/login`，填写管理口令和新的 Refresh Token 即可；新 token
  验证失败不会影响已配置的账号。
- Refresh Token 可用 `node tool/get_token.js` 获取。

### 图片加载：服务器代理 / 自定义图床

默认浏览器通过 `/pximg`、`/spximg` 走服务器代理，兼容性最好。

在 **Preferences → 自定义图床（Web）** 里填写图床域名（如 `i.pixiv.re`）后，
图片由浏览器直接向该图床请求，不再经过服务器，可节省带宽。

> 直连图床必须返回 CORS 头（`Access-Control-Allow-Origin`），否则图片解码会失败；
> 留空即可恢复服务器代理。

其它命令：

```bash
docker compose logs -f          # 查看日志
docker compose down             # 停止
docker compose build --no-cache # 完全重新构建
```

镜像大小约为 nginx 基础镜像 + 50 MB 前端产物；Flutter 编译阶段只在构建时
占用磁盘。

### 自动构建（GitHub Actions）

[`.github/workflows/build_web.yml`](../.github/workflows/build_web.yml) 会在以下时机
自动构建 Web 镜像并推送到 GitHub Container Registry：

| 触发 | 行为 | 生成的 tag |
| --- | --- | --- |
| push 到 `master` | 构建 + 推送 | `master`、`sha-<短哈希>`、`latest` |
| push `v*` tag | 构建 + 推送 | `1.9.88`、`1.9`、`sha-<短哈希>` |
| Pull Request | 仅构建校验，不推送 | `pr-<编号>` |
| 手动 `workflow_dispatch` | 可选是否推送 | 同分支/tag 规则 |

镜像地址（public，无需登录）：

```bash
docker pull ghcr.io/luvhx/pixez-flutter-docker:latest
docker run -d --name pixez-web -p 7493:80 ghcr.io/luvhx/pixez-flutter-docker:latest
```

手动触发时还可以指定 Flutter SDK 版本（默认 `3.47.7`）以及是否推送镜像。

### 使用 GHCR 镜像部署（不构建）

仓库自带 `docker-compose.prod.yml`，直接拉取上面的镜像运行，服务器上无需 Flutter
和编译环境：

```bash
cp .env.example .env
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d

docker compose -f docker-compose.prod.yml ps
curl -fsS http://127.0.0.1:7493/healthz
```

更新到最新镜像：

```bash
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

可用 `PIXEZ_IMAGE` 指向镜像站或 fork 的包，用 `PIXEZ_TAG` 固定 tag：

```bash
PIXEZ_IMAGE=ghcr.io/luvhx/pixez-flutter-docker PIXEZ_TAG=latest \
  docker compose -f docker-compose.prod.yml up -d
```

> `docker-compose.yml`（本地构建）与 `docker-compose.prod.yml`（拉取镜像）
> 使用相同的项目名、容器名和缓存卷，二选一启动即可。

## 本地构建（不使用 Docker）

要求：Flutter stable（Dart ≥ 3.11.5）、Node.js（仅开发用代理脚本）。

```bash
./tool/build_web.sh
node tool/dev_server.js        # http://127.0.0.1:8099
```

本地调试需要同时启动后端与静态服务器：

```bash
# 终端 1：会话后端（默认 8080）
PIXEZ_STATE_FILE=./.pixez-state.json PIXEZ_SETUP_TOKEN=dev node server/index.mjs

# 终端 2：静态文件 + 反向代理（/login、/api、/pixiv-api 转发到后端）
node tool/dev_server.js
```

`tool/dev_server.js` 的行为与 `deploy/nginx.conf` 一致（静态文件 + 反向代理）。

如果要部署到已有 nginx，复制 `build/web` 到站点目录，并引入
`deploy/nginx.conf` 与 `deploy/00-cache.conf` 即可。

## Web 端的实现要点

| 能力 | 原生实现 | Web 实现 |
| --- | --- | --- |
| HTTP | `rhttp`（Rust/reqwest，可选 ECH/自定义 DNS） | Dio `BrowserHttpClientAdapter` + 同源代理 |
| 数据库 | `sqflite_common_ffi`（SQLite） | `sqflite_common_ffi_web`（SQLite/WebAssembly，数据存 IndexedDB） |
| 图片缓存 | `flutter_cache_manager` 磁盘缓存 | `cached_network_image_web`（浏览器 HTTP 缓存） |
| 保存图片 | SAF / 相册 / 文件系统 | 浏览器下载（Blob + `<a download>`） |
| 设置导入导出 | SAF 文件选择器 | 文件选择器 / 浏览器下载 |
| 登录 | WebView + `pixiv://` 回调 | 服务端会话：`/login` 配置 Refresh Token，token 不下发浏览器 |
| 剪贴板 | 复制图片 | 复制图片链接（浏览器限制） |
| 刷新率 | `flutter_displaymode` | 由浏览器决定 |
| 后台下载 | 独立 isolate 队列 | 浏览器下载，进度显示在任务页 |
| Fluent UI（桌面） | `window_manager` + `flutter_acrylic` | 不启用，使用 Material UI |

改动集中在 `lib/platform/` 与 `lib/net/`：

- `lib/platform/io.dart` — `dart:io` 兼容层（Web 端为空实现）
- `lib/platform/dirs.dart` — `path_provider` 兼容层
- `lib/platform/db.dart` — SQLite 工厂切换
- `lib/platform/storage_init.dart` — 启动时初始化平台存储
- `lib/net/http_adapter.dart` — rhttp / 浏览器适配器切换
- `lib/net/endpoints.dart` — 原生绝对地址 / Web 同源代理前缀
- `lib/document_plugin.dart`、`lib/saf_plugin.dart` — 保存/导入导出
- `lib/er/fetcher.dart` — 下载队列（原生 isolate / Web 直接下载）

## 已知限制

- **登录**：Web 端使用服务端会话，需在 `/login` 配置一次 Refresh Token；Pixiv 已
  关闭第三方密码登录，因此不支持账号密码方式。
- **应用内购买**：`in_app_purchase` 没有 Web 实现，赞助入口在 Web 端不生效。
- **Android 专属功能**：小组件、SAF 目录、后台任务、刷新率设置等不可用。
- **iOS 专属功能**：App Group 共享缓存、剪贴板图片等不可用。
- **下载**：受浏览器限制，只能逐个触发下载；不能写入任意目录。批量下载会
  依次弹出多个下载请求，建议在浏览器中允许该站点「自动下载多个文件」。
- **图片防盗链**：必须通过本项目的 nginx 访问，直接 `flutter run -d chrome`
  会因为跨域/Referer 问题加载不出图片。

## 安全建议

- 生产环境请在前面再加一层 HTTPS（Caddy / Traefik / 云负载均衡）。
- 代理会把 `Host`、`Referer` 重写为 Pixiv 的域名，请勿把该服务暴露给不可信
  用户，否则可能被当作 Pixiv API 的匿名代理使用。
- Refresh Token 只保存在服务端卷 `pixez-state`（默认 `/data/state.json`）中，
  浏览器只有 HttpOnly 会话 Cookie；请限制该卷的访问权限。
- `PIXEZ_SETUP_TOKEN` 是账号配置口令，请使用长随机值；泄露后他人可以替换账号。
- 建议在 nginx 前再加一层 HTTPS，避免会话 Cookie 在明文 HTTP 中传输。

## 排错

| 现象 | 排查 |
| --- | --- |
| 页面白屏 | 打开开发者工具看 `main.dart.js` 是否 200；确认 `build/web` 已复制到 nginx 根目录 |
| 图片 403/404 | 检查 `/pximg/` 代理是否生效，`Referer` 是否为 `https://www.pixiv.net/` |
| 一直跳转 `/login` | 会话 Cookie 未带上或已失效；检查浏览器是否禁用 Cookie，或重新登录 |
| API 401 `pixiv_auth_failed` | Refresh Token 失效；在 `/login` 用管理口令重新配置 |
| 登录报 `invalid_grant` | refresh token 失效或被吊销，重新运行 `node tool/get_token.js` |
| 数据没有保存 | 浏览器是否禁用了 IndexedDB / 隐私模式 |
| `sqlite3.wasm` 404 | 构建前执行 `dart run sqflite_common_ffi_web:setup` |
| 中文显示为方块 | 服务器/浏览器缺少中文字体；Flutter Web 使用系统字体渲染 |

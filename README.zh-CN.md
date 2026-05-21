# Sub2API Status Bar

简体中文 | [English](README.md)

Sub2API Status Bar 是一款面向 Sub2API 用户的 macOS 菜单栏助手。它可以把每日花费、Token 用量、额度压力、模型分布和订阅限制常驻在菜单栏里，不需要一直打开 Web 控制台。

![Sub2API Status Bar 预览](docs/assets/product-preview.png)

## 亮点

- 原生 macOS 菜单栏应用，带紧凑的 SwiftUI 弹窗
- Usage Insights 会把余额、额度、月度预算、花费趋势、用量趋势、模型成本集中度和延迟转成优先级信号
- 本地主动提醒，支持 warning/error 级别和静默间隔设置
- 数据过期保护：最近一次刷新太久时，菜单栏和本地提醒会提示数据已陈旧
- 设置中显示通知权限状态，并可快速打开 macOS 通知设置
- Copy Share Card：生成适合社媒分享的匿名用量卡片和文本，可一键起草 X 帖子
- Copy Usage Report：复制不含凭据的可分享用量摘要
- 可自定义 Insight 阈值，包括额度压力、余额可用天数、月度预算、Token 激增、模型占比和延迟
- 用户仪表盘卡片：余额、API Keys、请求数、花费、百万 Token 混合成本、Token 总量、RPM/TPM 和响应时间
- 订阅额度卡片，分别展示日、周、月进度
- 七日用量趋势，支持 Tokens、Spend、Requests 三种视图
- 模型分布展示成本占比、百万 Token 混合成本和 Token 构成
- 可选菜单栏文字摘要，支持 Auto、Spend、Balance、Quota、Tokens、Requests 模式
- 首次连接检查清单、登录流程和可选手动 Bearer Token 设置
- 针对缺少 URL、会话过期、Token 替换、服务器不可达等问题提供恢复建议
- 支持多个已保存账号并快速切换
- 支持开机启动、手动刷新、复制诊断、显示配置文件
- 本地配置存储；无遥测、无第三方分析
- 可从 Settings 检查 GitHub Releases 更新

## 产品方向

Sub2API Status Bar 面向普通用户：快速回答“我现在是否健康、发生了什么变化、接下来该关注什么”。它借鉴大型用量仪表盘的有用部分，但不会把菜单栏变成又一个完整分析控制台：

- OpenAI 风格的用量可见性：按日查看用量、成本、Token、模型组合和吞吐。
- LiteLLM 风格的运行护栏：额度压力、预算可用期，以及接近限流语义的 RPM/TPM 信号。
- Helicone / Langfuse 风格的观测线索：本地提醒、成本集中度、用量趋势变化、延迟和安全诊断。

产品倾向是先展示可行动信号，深入排查则交给已配置的 Sub2API Web 控制台。

## 要求

- macOS 13 或更高版本
- 本地开发需要 Swift 6.1 或更高版本
- Sub2API 服务器需要启用用户 API 端点

## 用户 API 端点

应用需要 Sub2API 服务器提供 `/api/v1` 端点：

- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`
- `GET /api/v1/subscriptions/summary`
- `GET /api/v1/usage/dashboard/stats`
- `GET /api/v1/usage/dashboard/trend`
- `GET /api/v1/usage/dashboard/models`

登录或手动设置 Token 后，请求会发送 `Authorization: Bearer <token>`。

## 从源码运行

```bash
swift run Sub2APIStatusBar
```

首次启动后，点击菜单栏图标并填写：

- 服务器 URL，例如 `https://sub2api.example.com`
- 账号邮箱
- 密码

非敏感偏好会保存到：

```text
~/Library/Application Support/Sub2APIStatusBar/config.json
```

登录 Token 也保存在同一个本地配置文件中。应用不使用 macOS Keychain。

如需切换账号或移除已保存凭据，请打开 Settings 并选择 **Disconnect**。

Settings 还包含：

- **Show text in menu bar**：在菜单栏显示紧凑用量摘要
- **Metric**：选择菜单栏优先展示 Auto、Spend、Balance、Quota、Tokens 或 Requests
- **Notify on insights**：重要用量信号达到设定级别时发送本地 macOS 通知
- **Notification status**：确认通知是否可用，或在权限被阻止时打开 macOS 设置
- **Insights thresholds**：调整额度、余额、花费激增、Token 激增、模型占比和延迟警告阈值
- **Launch at login**：随 macOS 启动
- **Copy Share Card**：复制匿名视觉用量卡片和社媒文本，不包含账号细节
- **Copy Usage Report**：复制隐藏凭据的可分享用量摘要
- **Copy Diagnostics**：复制支持排查用的安全诊断信息，Token 会被隐藏
- **Copy Support Bundle**：复制可直接用于 issue 的支持模板，并包含安全诊断
- **Show Config**：显示本地 `config.json`

如果刷新持续失败，菜单栏和弹窗会在大约三个刷新间隔后标记数据已过期，本地 Insight 提醒也可以提示你不要把旧数据误认为当前状态。

可选首次运行环境变量：

```bash
SUB2API_BASE_URL=https://sub2api.example.com \
SUB2API_AUTH_TOKEN=your-token \
SUB2API_SHOW_MENU_BAR_TEXT=true \
swift run Sub2APIStatusBar
```

## 构建 macOS 应用

```bash
VERSION=v0.1.11 ./scripts/build-app.sh
```

输出：

```text
dist/Sub2APIStatusBar.app
```

构建脚本会生成应用图标、复制 Bundle 资源，并默认使用 ad-hoc 签名。如需使用 Developer ID 证书签名：

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
VERSION=v0.1.11 \
./scripts/build-app.sh
```

## 打包发布

```bash
VERSION=v0.1.11 ./scripts/package-release.sh
```

输出：

```text
dist/Sub2APIStatusBar-0.1.11-macOS.zip
dist/Sub2APIStatusBar-0.1.11-macOS.zip.sha256
dist/Sub2APIStatusBar-0.1.11-macOS.dmg
dist/Sub2APIStatusBar-0.1.11-macOS.dmg.sha256
```

`.dmg` 是面向普通用户的安装镜像，包含 Applications 快捷方式。`.zip` 继续用于自动化和发布验证。

## 公证发布

使用 Developer ID Application 证书签名后，可以用以下命令提交公证并 stapling：

```bash
APPLE_ID="you@example.com" \
TEAM_ID="TEAMID" \
APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx" \
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
VERSION=v0.1.11 \
./scripts/notarize-release.sh
```

## GitHub Release 签名

带 `v*` 标签的 GitHub Actions 发布需要 Apple 签名和公证密钥。推送标签前，请配置以下仓库 secrets：

- `APPLE_CERTIFICATE_BASE64`：base64 编码的 `.p12` Developer ID Application 证书
- `APPLE_CERTIFICATE_PASSWORD`：该 `.p12` 的密码
- `APPLE_KEYCHAIN_PASSWORD`：CI 临时 keychain 密码
- `DEVELOPER_ID_APPLICATION`：证书身份，例如 `Developer ID Application: Your Name (TEAMID)`
- `APPLE_ID`：`notarytool` 使用的 Apple ID 邮箱
- `TEAM_ID`：Apple Developer Team ID
- `APP_SPECIFIC_PASSWORD`：用于公证的 app-specific password

如果没有配置签名密钥，分支和 Pull Request 构建仍会生成 ad-hoc 签名产物。带标签的发布会在缺少完整签名配置时失败，避免公开发布未公证应用。CI 会上传 `.dmg`、`.zip` 和 SHA-256 校验文件。

## 更新

应用启动时会检查一次 GitHub Releases，也可以从 Settings > Updates 手动检查。发现新版本时，弹窗会显示更新提示并链接到下载页。

GitHub 的公开 latest-release API 只暴露已发布版本。草稿 release 不会显示给用户。

## 开发检查

```bash
swift test
swift build
./scripts/capture-product-preview.swift
./scripts/package-release.sh
./scripts/verify-release.sh
```

GitHub Actions 会在 `main`、Pull Request、标签和手动 workflow dispatch 上运行同类检查。发布验证会从干净的临时位置检查 zip 和 DMG。

视觉变更后，请重新生成 README 产品预览：

```bash
./scripts/capture-product-preview.swift
```

## 故障排查

如果 Swift 报告 PCH 使用了不同的 module cache path，通常是项目移动或重命名后 `.build` 仍指向旧目录。清理本地构建缓存后再运行：

```bash
./scripts/clean-build-cache.sh
swift run Sub2APIStatusBar
```

## 隐私

Sub2API Status Bar 会把服务器 URL、auth token、refresh token、显示偏好、Insight 阈值、账号列表和刷新间隔存储在本地 Application Support 配置文件中。它不使用 macOS Keychain，也不会向配置的 Sub2API 服务器和 GitHub Releases 更新检查以外的地方发送数据。

## 鸣谢

感谢 [LinuxDo](https://linux.do/) 社区的讨论、分享和反馈。

## 许可证

MIT

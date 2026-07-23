# YueDu-iOS 构建指南

## 项目概述

YueDu-iOS 是阅读萤火虫（Android YueDu 3.0）的 iOS 移植版本，基于 SwiftUI 开发，支持自定义书源、本地书籍、网络爬取等功能。

- **仓库地址**：https://github.com/ccf-yang/YueDu-iOS
- **构建分支**：`bd`
- **最低支持系统**：iOS 16.0
- **Xcode 版本**：16.2（CI 使用 macOS 15 Runner）

---

## 一、GitHub Actions 自动构建

### 1.1 触发方式

CI Workflow 支持两种触发方式：

| 触发方式 | 说明 |
|---------|------|
| **推送代码** | 向 `bd` 分支推送 commit 时自动触发（`.md` 文件和 `.github/` 目录除外） |
| **手动触发** | 无需提交代码，在 GitHub 网页上点击按钮即可触发 |

---

### 1.2 手动触发 Workflow（无需提交代码）

> ⚠️ **重要说明**：GitHub 的「Run workflow」按钮**不在** workflow 运行列表页面，需要先点击左侧具体的 Workflow 名称才能看到。

**详细步骤（含截图说明）：**

**第一步**：打开 Actions 总览页，点击左侧列表中的 Workflow 名称

```
https://github.com/ccf-yang/YueDu-iOS/actions
```

在左侧 **「Actions」→「All workflows」** 下，找到并点击：
```
构建 YueDu-iOS IPA（无证书版）
```

**第二步**：进入该 Workflow 的专属页面后，右侧过滤栏上方会出现 **「Run workflow」** 蓝色/绿色按钮

```
https://github.com/ccf-yang/YueDu-iOS/actions/workflows/build-ipa.yml
```

页面布局示意：
```
Actions > 构建 YueDu-iOS IPA（无证书版）
                                        [Run workflow ▼]  ← 按钮在这里
Filter workflow runs
────────────────────────────────────────
  #23  fix: change var book...   bd  7分钟前
  #22  Manually run by ...       bd  7分钟前
```

**第三步**：点击 **「Run workflow」** 按钮，弹出下拉框：
- Branch 选择 **`bd`**
- 点击绿色 **「Run workflow」** 按钮确认

**第四步**：页面刷新后出现新记录（状态 🟡 In progress），点击进入查看实时日志

> **注意**：
> - 如果整个 Actions 页面左侧都看不到该 Workflow，说明 workflow 文件还未推送到仓库默认分支
> - 手动触发需要对仓库有 **Write** 或 **Admin** 权限（仓库 Owner 默认满足）
> - 若按钮仍不可见，可用 API 触发：见下方「1.3 通过 API 手动触发」

---

### 1.3 通过 API 手动触发（备用方案）

如果网页按钮不可见，可用以下 curl 命令直接触发（需要 GitHub Token）：

```bash
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer <YOUR_GITHUB_TOKEN>" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/ccf-yang/YueDu-iOS/actions/workflows/build-ipa.yml/dispatches \
  -d '{"ref":"bd"}'
```

返回 HTTP 204 表示触发成功，随后在 Actions 页面即可看到新的运行记录。



构建成功后（约 5-10 分钟），在 Actions 运行详情页底部的 **Artifacts** 区域下载 IPA：

```
YueDu-iOS-unsigned-{运行编号}.zip
```

解压后得到 `YueDu-iOS-unsigned.ipa`，保留 **90 天**。

---

## 二、构建产物说明

| 产物 | 说明 |
|------|------|
| `YueDu-iOS-unsigned.ipa` | 无签名 IPA，可通过 Sideloadly / AltStore 安装 |
| 构建日志 | 在 Actions 运行详情页实时查看 |

---

## 三、本地安装 IPA（无开发者证书）

### 方式 A：Sideloadly（推荐）

1. 下载 [Sideloadly](https://sideloadly.io/)（支持 Windows / macOS）
2. 用数据线连接 iPhone，信任电脑
3. 打开 Sideloadly，拖入 `YueDu-iOS-unsigned.ipa`
4. 输入 Apple ID（免费账号即可），点击 **Start**
5. 安装完成后，前往 **设置 → 通用 → VPN与设备管理** 信任开发者证书
6. 每 7 天需重新安装一次（免费账号限制）

### 方式 B：AltStore

1. 安装 [AltStore](https://altstore.io/)
2. 通过 AltStore 侧载 IPA，同样需每 7 天刷新

### 方式 C：付费开发者账号（长期有效）

使用 $99/年 的 Apple 开发者账号签名，安装后永久有效，无需每 7 天重装。

---

## 四、Workflow 文件说明

文件路径：`.github/workflows/build-ipa.yml`

```yaml
on:
  workflow_dispatch:      # 手动触发
  push:
    branches: [ bd ]      # bd 分支推送自动触发
    paths-ignore:
      - '**.md'
      - '.github/**'
```

**构建步骤：**

| 步骤 | 说明 |
|------|------|
| Checkout | 检出 bd 分支代码 |
| Select Xcode 16 | 切换到 Xcode 16.2 |
| Resolve SPM | 解析 Swift Package 依赖 |
| Build .app | 无签名编译 Release 包 |
| Package IPA | 将 .app 打包成 .ipa 文件 |
| Upload Artifact | 上传 IPA 到 GitHub Artifacts（保留 90 天） |

---

## 五、常见问题排查

### Q1：构建失败，报 `onChange(of:) is only available in iOS 17.0`

**原因**：使用了 iOS 17 专属的双参数 `onChange` 写法。

**修复**：
```swift
// ❌ iOS 17+ 专属
.onChange(of: value) { _, newValue in ... }

// ✅ iOS 16 兼容
.onChange(of: value) { newValue in ... }
```

---

### Q2：构建失败，报 `No simulator runtime version available`

**原因**：Assets.xcassets 中 AppIcon 定义不完整，触发模拟器运行时检查。

**修复**：在 `AppIcon.appiconset/Contents.json` 的 images 条目中添加 `"scale": "1x"`，并在 workflow xcodebuild 命令中加入：
```
ASSETCATALOG_COMPILER_SKIP_APP_STORE_DEPLOYMENT=YES
```

---

### Q3：手动触发 Workflow 按钮是灰色的

**原因**：当前账号对仓库没有 Write 权限，或 Workflow 文件不在默认分支上。

**解决**：
- 确认已登录 GitHub 且对仓库有写权限
- 确认 `.github/workflows/build-ipa.yml` 文件已推送到 `bd` 分支

---

### Q4：Artifacts 区域没有找到 IPA 下载链接

**原因**：构建可能失败，或 Artifact 已超过 90 天保留期。

**解决**：重新手动触发一次 Workflow 即可生成新的 Artifact。

---

## 六、项目结构速览

```
YueDu-iOS/
├── .github/
│   └── workflows/
│       └── build-ipa.yml          # CI/CD 构建脚本
├── YueDu-iOS.xcodeproj/           # Xcode 项目文件
├── YueDu-iOS/
│   ├── App/
│   │   ├── YueDuApp.swift         # 应用入口
│   │   └── ContentView.swift      # Tab 切换主视图
│   ├── Models/                    # 数据模型
│   ├── Services/                  # 网络/数据库/规则引擎
│   ├── ViewModels/                # MVVM ViewModel 层
│   ├── Views/                     # SwiftUI 视图
│   │   ├── BookshelfView.swift    # 书架页面
│   │   ├── ReaderView.swift       # 阅读器页面
│   │   ├── SearchView.swift       # 搜索页面
│   │   └── SettingsView.swift     # 书源管理/设置页面
│   ├── Utils/                     # 工具类
│   └── Resources/
│       ├── Assets.xcassets        # 图标/颜色资源
│       └── Info.plist             # 应用权限配置
└── instruct.md                    # 本文档
```

---

## 七、联系与反馈

如遇到构建问题，可将 GitHub Actions 完整日志截图提供给开发者进行诊断。

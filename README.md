# 阅读 iOS (YueDu-iOS)

> 基于 Android 版「阅读 legado 3.0」的 iOS SwiftUI 完整移植版本  
> 支持自定义书源规则爬取、跨书源搜索、网络小说阅读、本地 TXT/EPUB 书籍导入

---

## 快速开始（3 步运行）

### 第一步：克隆项目

```bash
git clone https://github.com/ccf-yang/YueDu-iOS.git
cd YueDu-iOS
git checkout bd
```

### 第二步：用 Xcode 打开

```bash
open YueDu-iOS.xcodeproj
```

> Xcode 会自动拉取 SPM 依赖（**ZipArchive**），首次需等待约 30 秒

### 第三步：配置签名并运行

1. 在 Xcode 顶部选择目标设备（iPhone 真机 或 模拟器）
2. 点击 `YueDu-iOS` Target → **Signing & Capabilities**
3. 设置你的 **Team**（Apple ID 即可，无需付费开发者账号用于模拟器）
4. 按 `Cmd + R` 编译运行

---

## 打包 IPA 文件（3 种方式）

### 方式一：Xcode Archive（推荐）

```
1. Xcode 菜单 → Product → Archive（需真机 scheme，选 "Any iOS Device"）
2. 打开 Organizer（Window → Organizer）
3. 选择刚生成的 Archive → "Distribute App"
4. 选择 "Development" 或 "Ad Hoc"
5. 导出 .ipa 文件到本地
```

### 方式二：xcodebuild 命令行

```bash
# 1. 编译 Archive
xcodebuild archive \
  -project YueDu-iOS.xcodeproj \
  -scheme YueDu-iOS \
  -destination "generic/platform=iOS" \
  -archivePath ./build/YueDu-iOS.xcarchive

# 2. 导出 IPA（需要 ExportOptions.plist）
xcodebuild -exportArchive \
  -archivePath ./build/YueDu-iOS.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath ./build/ipa/
```

ExportOptions.plist 示例：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

### 方式三：Sideloadly 免签安装（无需开发者账号）

```
1. 下载 Sideloadly：https://sideloadly.io/
2. 将 iPhone 连接 Mac（信任设备）
3. 把 .ipa 文件拖入 Sideloadly
4. 填写 Apple ID（免费账号即可）
5. 点击 Start，等待安装完成
6. 设置 → 通用 → VPN与设备管理 → 信任开发者证书
```

---

## 项目结构

```
YueDu-iOS/
├── Package.swift                    ← SPM 依赖（ZipArchive）
├── YueDu-iOS.xcodeproj/            ← Xcode 工程文件
└── YueDu-iOS/
    ├── App/
    │   ├── YueDuApp.swift          ← @main 入口，初始化 SQLite
    │   └── ContentView.swift       ← TabView 主框架（书架/搜索/设置）
    ├── Models/                     ← 数据模型
    │   ├── Book.swift
    │   ├── BookChapter.swift
    │   ├── BookSource.swift        ← 书源 + SearchResult + Bookmark
    │   └── ReadConfig.swift
    ├── Services/                   ← 业务逻辑层
    │   ├── DatabaseService.swift   ← SQLite（5张表 + WAL模式）
    │   ├── NetworkService.swift    ← HTTP + GBK/UTF-8 自动编码检测
    │   ├── RuleEngineService.swift ← 规则引擎（CSS/Regex/XPath/JSONPath）
    │   ├── BookSourceService.swift ← 并发搜索 + 内容爬取 + 导入导出
    │   ├── LocalBookService.swift  ← TXT自动分章 + EPUB解析
    │   └── DataManagementService.swift
    ├── ViewModels/                 ← MVVM ViewModel 层
    ├── Views/                      ← SwiftUI 视图层
    │   ├── BookshelfView.swift     ← 书架（分组/排序/网格）
    │   ├── SearchView.swift        ← 搜索（历史/跨书源结果）
    │   ├── ReaderView.swift        ← 阅读器（主题/字号/目录/书签）
    │   └── SettingsView.swift      ← 书源管理 + 数据备份恢复
    ├── Utils/
    │   ├── HTMLParser.swift        ← CSS选择器 + 正则解析
    │   ├── StringUtils.swift
    │   ├── DateUtils.swift
    │   └── FileUtils.swift
    └── Resources/
        ├── Info.plist
        └── Assets.xcassets/
```

---

## 核心功能

| 功能 | 说明 |
|------|------|
| 📚 书架管理 | 分组、排序、封面网格展示、阅读进度 |
| 🔍 跨书源搜索 | 最多 5 个书源并发搜索，相关性排序去重 |
| 📖 规则引擎 | CSS选择器 / 正则 / XPath / JSONPath / `@@`规则链 |
| 📁 本地书籍 | TXT 自动按章节标题分章，EPUB 解压解析 |
| 🔖 书签笔记 | 添加书签、查看/跳转书签列表 |
| 🌙 阅读主题 | 白天 / 护眼 / 夜间 / 牛皮纸 四套主题 |
| 📤 书源管理 | JSON导入导出 / URL远程导入 / 启用禁用分组 |
| 💾 数据备份 | 全量导出/恢复（书籍+书源+书签） |

---

## 环境要求

| 工具 | 最低版本 |
|------|---------|
| Xcode | 15.0+ |
| iOS 部署目标 | 16.0+ |
| Swift | 5.9+ |
| macOS | 13.0 Ventura+ |

---

## 书源格式（兼容阅读3）

本项目完全兼容 legado/阅读3 标准书源 JSON 格式，可直接导入现有书源：

```json
{
  "bookSourceUrl": "https://example.com",
  "bookSourceName": "示例书源",
  "bookSourceGroup": "综合",
  "ruleSearch": "{\"searchUrl\":\"https://example.com/search?q={{key}}\",\"bookList\":\".book-item\",\"name\":\".title@text\",\"author\":\".author@text\",\"bookUrl\":\".title@href\"}",
  "ruleToc": "{\"chapterList\":\".chapter-list a\",\"chapterTitle\":\"@text\",\"chapterUrl\":\"@href\"}",
  "ruleContent": "{\"content\":\".read-content@text\"}"
}
```

---

## 已知限制 & 后续计划

- [ ] `@js:` JavaScript 规则执行（需集成 JavaScriptCore）
- [ ] 书源登录（Cookie 注入 + loginCheckJs）
- [ ] 发现页（exploreUrl 规则）
- [ ] 音频书源播放器
- [ ] GitHub Actions 自动化 IPA 构建

---

## License

本项目基于 [LGPL-3.0](https://www.gnu.org/licenses/lgpl-3.0.html) 协议开源，致敬原版 [legado](https://github.com/gedoor/legado) 项目。

---

## 目录结构

```
YueDu-iOS/
├── Package.swift                    ← SPM 依赖声明（ZipArchive）
├── YueDu-iOS.xcodeproj/            ← Xcode 项目（已预配置）
└── YueDu-iOS/
    ├── App/
    │   ├── YueDuApp.swift          ← App 入口，初始化数据库
    │   └── ContentView.swift       ← TabView 主界面
    ├── Models/
    │   ├── Book.swift              ← 书籍数据模型
    │   ├── BookChapter.swift       ← 章节模型
    │   ├── BookSource.swift        ← 书源模型
    │   └── ReadConfig.swift        ← 阅读配置模型
    ├── Services/
    │   ├── DatabaseService.swift   ← SQLite 本地数据库（books/chapters/sources/cache）
    │   ├── NetworkService.swift    ← HTTP 请求（GBK/UTF-8 自动编码检测）
    │   ├── RuleEngineService.swift ← 规则引擎（CSS/Regex/XPath/JSONPath）
    │   ├── BookSourceService.swift ← 书源爬取、搜索、导入导出
    │   ├── LocalBookService.swift  ← TXT/EPUB 本地书籍解析
    │   └── DataManagementService.swift ← 数据备份/恢复/缓存清理
    ├── ViewModels/
    │   ├── BookshelfViewModel.swift
    │   ├── SearchViewModel.swift
    │   ├── ReaderViewModel.swift
    │   └── SettingsViewModel.swift
    ├── Views/
    │   ├── BookshelfView.swift     ← 书架、分组、书籍卡片、本地导入
    │   ├── SearchView.swift        ← 搜索、历史记录、跨书源结果
    │   ├── ReaderView.swift        ← 阅读器（主题/字号/目录/书签）
    │   └── SettingsView.swift      ← 设置、书源管理、数据管理
    ├── Utils/
    │   ├── HTMLParser.swift        ← HTML/CSS选择器/正则解析
    │   ├── StringUtils.swift       ← HTML实体解码、文本处理
    │   ├── DateUtils.swift         ← 日期格式化
    │   └── FileUtils.swift         ← 文件读写工具
    └── Resources/
        ├── Info.plist
        └── Assets.xcassets/
```

---

## 环境要求

| 工具 | 版本 |
|------|------|
| Xcode | 15.0+ |
| iOS 部署目标 | iOS 16.0+ |
| Swift | 5.9+ |
| macOS | 13.0+ (Ventura) |

---

## 第三方依赖

| 包 | 用途 | SPM URL |
|----|------|---------|
| ZipArchive | EPUB 解压 | https://github.com/ZipArchive/ZipArchive.git |

---

## 在 Xcode 中打开

1. 双击 `YueDu-iOS.xcodeproj` 打开项目
2. Xcode 会自动解析 Swift Package（ZipArchive），等待完成
3. 选择目标设备（iPhone 真机或模拟器）
4. 按 `Cmd+R` 编译运行

> ⚠️ 若使用真机，需要在 Xcode → Signing & Capabilities 设置你的 Apple Developer Team

---

## 核心功能说明

### 书源规则引擎
支持阅读3标准书源 JSON 格式，规则类型：
- **CSS 选择器**：`div.chapter-list > a@href`
- **正则**：`/href="([^"]+)"/`
- **XPath**：`//div[@class="chapter"]//a`
- **JSONPath**：`$.data.list`
- **规则链**：用 `@@` 分隔多级提取

### 书源导入方式
1. 从本地 JSON 文件导入（设置 → 书源管理 → 导入）
2. 从 URL 直接拉取（支持阅读3书源仓库地址）
3. 手动填写（书源编辑器）

### 本地书籍
- **TXT**：自动按"第X章"等关键词分章，无章节时按3000字分块
- **EPUB**：解压 ZIP → 解析 OPF → 提取 spine 顺序 → 逐章缓存

### 阅读器主题
| 主题 | 背景 | 文字 |
|------|------|------|
| 白天 | #FFFFFF | #1C1C1E |
| 护眼 | #C7EDCC | #1C1C1E |
| 夜间 | #1C1C1E | #AAAAAA |
| 牛皮纸 | #F5DEB3 | #3E2723 |

---

## 打包 IPA（无开发者账号方式）

使用 AltStore / Sideloadly 侧载：
```bash
# 1. Xcode → Product → Archive
# 2. Organizer → Distribute App → Ad Hoc / Development
# 3. 导出 .ipa 文件
# 4. 用 Sideloadly 安装到设备
```

---

## 已知限制

- JavaScript 规则（`@js:` 前缀）当前版本不执行，需要 JavaScriptCore 集成（后续版本）
- 登录书源需要额外实现 Cookie 注入
- 音频书源暂未实现播放器

---

## 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 3.0.0 | 2026-07 | iOS SwiftUI 完整移植版 |

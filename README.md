# YueDu iOS

一款适用于 iOS 的开源小说阅读器，移植自 YueDu-Firefly（阅读 3.0）。

## 功能特性

- 📚 书架管理 - 本地书籍管理和排序
- 🔍 书源管理 - 自定义书源配置
- 📖 阅读器 - 自定义阅读界面和字体
- 💾 本地存储 - SQLite 数据库存储
- 🌐 网络支持 - URLSession 网络请求
- 📱 SwiftUI - 现代化 UI 框架

## 最低要求

- iOS 16.0+
- Xcode 14.0+
- Swift 5.7+

## 项目结构

```
YueDu-iOS/
├── App/                    # 应用入口
├── Models/                 # 数据模型
├── Services/              # 业务服务层
├── ViewModels/            # 视图模型
├── Views/                 # UI 视图层
├── Utils/                 # 工具类
└── Resources/             # 资源文件
```

## 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/ccf-yang/YueDu-iOS.git
cd YueDu-iOS
```

### 2. 打开项目

```bash
open YueDu-iOS.xcodeproj
```

### 3. 构建和运行

使用 Xcode 的 Run 按钮或快捷键 Cmd+R

## 许可证

GNU General Public License v3.0

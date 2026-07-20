// swift-tools-version: 5.9
import PackageDescription

// Package.swift 仅用于本地 Xcode 开发参考
// GitHub Actions CI 直接编译 .xcodeproj，无需 SPM
// ZipArchive 依赖已移除，改用系统原生 ZIP 解压实现
let package = Package(
    name: "YueDu-iOS",
    platforms: [.iOS(.v16)],
    targets: [
        .target(
            name: "YueDu-iOS",
            path: "YueDu-iOS"
        ),
    ]
)

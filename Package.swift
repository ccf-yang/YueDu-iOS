// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YueDu-iOS",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "YueDu-iOS", targets: ["YueDu-iOS"]),
    ],
    dependencies: [
        // ZipArchive：用于 EPUB 解压
        .package(url: "https://github.com/ZipArchive/ZipArchive.git", from: "2.5.5"),
    ],
    targets: [
        .target(
            name: "YueDu-iOS",
            dependencies: [
                .product(name: "ZipArchive", package: "ZipArchive"),
            ],
            path: "YueDu-iOS"
        ),
    ]
)

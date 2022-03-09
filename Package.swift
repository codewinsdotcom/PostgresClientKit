// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "PostgresClientKit",
    products: [
        .library(
            name: "PostgresClientKit",
            targets: ["PostgresClientKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/BlueSocket.git", from: "2.0.0"),
        .package(url: "https://github.com/IBM-Swift/BlueSSLService", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "PostgresClientKit",
            dependencies: ["Socket", "SSLService"]),
        .testTarget(
            name: "PostgresClientKitTests",
            dependencies: ["PostgresClientKit"]),
    ]
)

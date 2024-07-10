// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IcpKit",
    platforms: [
        .iOS(.v14),
    ], 
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "IcpKit", targets: ["IcpKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/attaswift/BigInt.git", .upToNextMajor(from: "5.3.0")),
        .package(url: "https://github.com/outfoxx/PotentCodables.git", .upToNextMajor(from: "3.2.0")),
        .package(url: "https://github.com/Jarema/Base32.git", .upToNextMajor(from: "0.10.2"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "IcpKit",
            dependencies: [
                "BigInt",
                "PotentCodables",
                "Base32"
            ]
        ),
        .testTarget(
            name: "IcpKitTests",
            dependencies: [
                "IcpKit",
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)

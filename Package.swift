// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LiveViewNativeBleClient",
    platforms: [
        .iOS("16.0"),
        .macOS("13.0"),
        .watchOS("9.0"),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "LiveViewNativeBleClient",
            targets: ["LiveViewNativeBleClient"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/adiibanez/liveview-client-swiftui.git", from: "0.4.0-rc.0.core-events"),
        .package(url: "https://github.com/NordicSemiconductor/IOS-CoreBluetooth-Mock.git", from: "0.18.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "LiveViewNativeBleClient",
            dependencies: [
                .product(name: "LiveViewNative", package: "liveview-client-swiftui"),
                .product(name: "CoreBluetoothMock", package: "IOS-CoreBluetooth-Mock")
            ]
        ),
        .testTarget(
                    name: "LiveViewNativeBleClientTests",
                    dependencies: ["LiveViewNativeBleClient"],
                    resources: [.process("TestInfo.plist")] // Resources/
                )
        
    ]
)

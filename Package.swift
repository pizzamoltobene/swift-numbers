// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "SwiftNumbers",
  defaultLocalization: "en",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .library(
      name: "SwiftNumbers",
      targets: ["SwiftNumbersCore"]
    ),
    .library(
      name: "SwiftNumbersCore",
      targets: ["SwiftNumbersCore"]
    ),
    .executable(
      name: "swiftnumbers",
      targets: ["swiftnumbers"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.30.0"),
    .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
    .package(url: "https://github.com/lovetodream/swift-snappy.git", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "SwiftNumbersContainer",
      dependencies: [
        .product(name: "ZIPFoundation", package: "ZIPFoundation")
      ]
    ),
    .target(
      name: "SwiftNumbersIWA",
      dependencies: [
        "SwiftNumbersContainer",
        "SwiftNumbersProto",
        .product(name: "Snappy", package: "swift-snappy"),
      ]
    ),
    .target(
      name: "SwiftNumbersProto",
      dependencies: [
        .product(name: "SwiftProtobuf", package: "swift-protobuf"),
        "SwiftNumbersContainer",
      ],
      resources: [
        .copy("swift-protobuf-config.json"),
        .copy("google"),
      ],
      plugins: [
        .plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")
      ]
    ),
    .target(
      name: "SwiftNumbersCore",
      dependencies: [
        "SwiftNumbersContainer",
        "SwiftNumbersIWA",
        "SwiftNumbersProto",
      ]
    ),
    .executableTarget(
      name: "swiftnumbers",
      dependencies: [
        "SwiftNumbersCore",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .testTarget(
      name: "SwiftNumbersTests",
      dependencies: [
        "SwiftNumbersCore",
        "SwiftNumbersContainer",
        "SwiftNumbersIWA",
        "SwiftNumbersProto",
      ],
      resources: [
        .copy("Goldens")
      ]
    ),
  ]
)

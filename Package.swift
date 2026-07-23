// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Perch",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Perch", targets: ["Perch"]),
    ],
    targets: [
        .executableTarget(
            name: "Perch",
            resources: [.process("Assets")]
        ),
    ]
)

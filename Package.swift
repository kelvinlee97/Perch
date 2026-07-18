// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BirdTodo",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "BirdTodo", targets: ["BirdTodo"]),
    ],
    targets: [
        .executableTarget(
            name: "BirdTodo",
            resources: [.process("Assets")]
        ),
    ]
)

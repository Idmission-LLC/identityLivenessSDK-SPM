// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IDentityLivenessSDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "IDentityLivenessSDK", targets: ["IDentityLivenessSDKTarget"]),
        .library(name: "IDentityLivenessModels", targets: ["IDentityLivenessModelsTarget"])
    ],
    targets: [
        // These targets link the binary frameworks and the external dependencies together.
        .target(
            name: "IDentityLivenessSDKTarget",
            dependencies: [
                "IDentityLivenessSDK",
                "SelfieCaptureLiveness"
            ],
            path: "Sources/IDentityLiveness"
        ),
        .target(
            name: "IDentityLivenessModelsTarget",
            dependencies: ["IDentityLivenessModels"],
            path: "Sources/IDentityLivenessModels"
        ),

        // --- Binary Targets (Liveness) ---
        .binaryTarget(name: "IDentityLivenessSDK", path: "Frameworks/IDentityLivenessSDK.xcframework"),
        .binaryTarget(name: "SelfieCaptureLiveness", path: "Frameworks/SelfieCaptureLiveness.xcframework"),
        .binaryTarget(name: "IDentityLivenessModels", path: "Frameworks/IDentityLivenessModels.xcframework")
    ]
)

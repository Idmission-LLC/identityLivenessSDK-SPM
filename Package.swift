// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IDentityLivenessSDK",
    platforms: [
        .iOS("15.6")
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
        .binaryTarget(name: "IDentityLivenessSDK", url: "https://github.com/Idmission-LLC/ios-sdk-releases/releases/download/liveness-11.1.19.2.5/IDentityLivenessSDK.zip", checksum: "fb111d5ce2efaeac052a79e62cd2b636a1356e25d736f7831249ff55defcf5c3"),
        .binaryTarget(name: "SelfieCaptureLiveness", url: "https://github.com/Idmission-LLC/ios-sdk-releases/releases/download/liveness-11.1.19.2.5/SelfieCaptureLiveness.zip", checksum: "fab4b32cb376ade81500a2ccc666e6ea57c22b4746a4028323f54a2ab77df01f"),
        .binaryTarget(name: "IDentityLivenessModels", url: "https://github.com/Idmission-LLC/ios-sdk-releases/releases/download/liveness-11.1.19.2.5/IDentityLivenessModels.zip", checksum: "7235207428c6f27bb10f416e8fc73dd3fd2b285ad79e151d32cee307726aae5e")
    ]
)

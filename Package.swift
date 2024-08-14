// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HeadsetHub",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "JLSDK", targets: ["JL_AdvParse", "JL_HashPair", "JL_OTALib"]),
        .library(name: "BESSDK", targets: ["BESSDK"]),
    ],
    targets: [
        // JL
        .binaryTarget(
            name: "JL_AdvParse",
            path: "JLSDK/JLAdvParse.xcframework"
        ),
        
        .binaryTarget(
            name: "JL_HashPair",
            path: "JLSDK/JLHashPair.xcframework"
        ),
        
        .binaryTarget(
            name: "JL_OTALib",
            path: "JLSDK/JLOtaLib.xcframework"
        ),
        // BES
        .target(
            name: "BESSDK",
            path: "BESSDK"
        ),
    ]
)

// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HeadsetHub",
    products: [
        .library(name: "JLSDK", targets: ["JL_AdvParse", "JL_HashPair", "JL_OTALib"])
    ],
    targets: [
        // JL
        .binaryTarget(
            name: "JL_AdvParse",
            path: "JLSDK/JL_AdvParse.xcframework"
        ),
        
        .binaryTarget(
            name: "JL_HashPair",
            path: "JLSDK/JL_HashPair.xcframework"
        ),
        
        .binaryTarget(
            name: "JL_OTALib",
            path: "JLSDK/JL_OTALib.xcframework"
        )
    ]
)

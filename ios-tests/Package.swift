// swift-tools-version: 5.9
import PackageDescription

// Test-only harness for src/ios's Swift shim files. Not part of the plugin's own distribution or
// install path (Cordova plugins are consumed via plugin.xml + CocoaPods, not SPM — see plugin.xml's
// <podspec> block); this package exists solely so `xcodebuild test`/`swift test` can compile and
// exercise AppsFlyerPlugin.swift / AppsFlyerAttribution.swift against the real AppsFlyerRPC /
// AppsFlyerLib frameworks without requiring a full Cordova-generated iOS project.
let package = Package(
    name: "AppsFlyerCordovaShim",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "AppsFlyerCordovaShim", targets: ["AppsFlyerCordovaShim"])
    ],
    dependencies: [
        // Versions verified against the real CocoaPods trunk podspec (AppsFlyerRPC 7.0.13 depends
        // on AppsFlyerFramework 7.0.2) and matching git tags on both repos — NOT the versions
        // named in the migration brief, which don't exist as published releases. SPM can't inherit
        // this pin transitively from AppsFlyerRPC's own binaryTarget, so it's pinned explicitly
        // here and must be bumped in lockstep with AppsFlyerRPC. plugin.xml's CocoaPods podspec
        // doesn't need the equivalent pin — CocoaPods resolves it transitively from AppsFlyerRPC's
        // own dependency declaration.
        .package(url: "https://github.com/AppsFlyerSDK/appsflyer-apple-rpc.git", exact: "7.0.13"),
        .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework-Static.git", exact: "7.0.2"),
    ],
    targets: [
        // Module name is "Cordova" purely as a test double -- the real CordovaLib has no Swift
        // module by that name (see AppsFlyerPlugin.swift's AF_CORDOVA_SPM_TEST comment). Gated
        // behind that same flag so production's `import Cordova` only fires in this harness.
        .target(
            name: "Cordova",
            dependencies: [],
            path: "Sources/CordovaTestSupport"
        ),
        .target(
            name: "AppsFlyerCordovaShim",
            dependencies: [
                "Cordova",
                .product(name: "AppsFlyerRPC", package: "appsflyer-apple-rpc"),
                .product(name: "AppsFlyerLib-Static", package: "AppsFlyerFramework-Static"),
            ],
            // Sources/AppsFlyerCordovaShim/*.swift are symlinks into ../../../src/ios — SPM
            // targets can't declare a `path` outside the package root, so the package root stays
            // self-contained while the symlinked files keep this a test of the real production
            // sources, not a copy that can drift out of sync.
            path: "Sources/AppsFlyerCordovaShim",
            swiftSettings: [.define("AF_CORDOVA_SPM_TEST")]
        ),
        .testTarget(
            name: "AppsFlyerCordovaShimTests",
            dependencies: ["AppsFlyerCordovaShim", "Cordova"],
            path: "Tests/AppsFlyerCordovaShimTests"
        ),
    ]
)

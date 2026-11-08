// swift-tools-version: 6.2
import PackageDescription
let package = Package(name: "WatchWeeksCore", platforms: [.iOS(.v17), .macOS(.v14)], products: [.library(name: "WatchWeeksCore", targets: ["WatchWeeksCore"])], targets: [.target(name: "WatchWeeksCore"), .testTarget(name: "WatchWeeksCoreTests", dependencies: ["WatchWeeksCore"])])

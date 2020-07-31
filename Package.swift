// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QRCodeReader",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "QRCodeReader",
            targets: ["QRCodeReader"]),
    ],
    targets: [
        .target(
            name: "QRCodeReader",
            path: "QRCodeReader/Classes"),
    ]
)

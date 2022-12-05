// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Copyright 2021 Esri.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import PackageDescription

let package = Package(
    name: "arcgis-maps-sdk-swift-toolkit",
    platforms: [
        .iOS(.v15),
        .macCatalyst(.v15)
    ],
    products: [
        .library(
            name: "ArcGISToolkit",
            targets: ["ArcGISToolkit"]
        ),
    ],
    dependencies: [
        // To use a daily build of the Swift API, change the path below to point to the daily build's `output` folder.
        .package(name: "arcgis-maps-swift", path: "../swift/ArcGIS")
    ],
    targets: [
        .target(
            name: "ArcGISToolkit",
            dependencies: [
                .product(name: "ArcGIS", package: "arcgis-maps-swift")
            ]
        ),
        .testTarget(
            name: "ArcGISToolkitTests",
            dependencies: ["ArcGISToolkit"]
        )
    ]
)

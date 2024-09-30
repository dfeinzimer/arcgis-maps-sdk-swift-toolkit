// Copyright 2024 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import XCTest
import ArcGIS
@testable import ArcGISToolkit

class PreplannedMapModelStatusTests: XCTestCase {
    private typealias Status = PreplannedMapModel.Status
    
    func testNeedsToBeLoaded() {
        XCTAssertFalse(Status.loading.needsToBeLoaded)
        XCTAssertFalse(Status.packaging.needsToBeLoaded)
        XCTAssertFalse(Status.packaged.needsToBeLoaded)
        XCTAssertFalse(Status.downloading.needsToBeLoaded)
        XCTAssertFalse(Status.downloaded.needsToBeLoaded)
        XCTAssertFalse(Status.mmpkLoadFailure(CancellationError()).needsToBeLoaded)
        XCTAssertTrue(Status.notLoaded.needsToBeLoaded)
        XCTAssertTrue(Status.downloadFailure(CancellationError()).needsToBeLoaded)
        XCTAssertTrue(Status.loadFailure(CancellationError()).needsToBeLoaded)
        XCTAssertTrue(Status.packageFailure.needsToBeLoaded)
        XCTAssertTrue(Status.opened.needsToBeLoaded)
    }
    
    func testAllowsDownload() {
        XCTAssertFalse(Status.notLoaded.allowsDownload)
        XCTAssertFalse(Status.loading.allowsDownload)
        XCTAssertFalse(Status.loadFailure(CancellationError()).allowsDownload)
        XCTAssertFalse(Status.packaging.allowsDownload)
        XCTAssertTrue(Status.packaged.allowsDownload)
        XCTAssertFalse(Status.packageFailure.allowsDownload)
        XCTAssertFalse(Status.downloading.allowsDownload)
        XCTAssertFalse(Status.downloaded.allowsDownload)
        XCTAssertTrue(Status.downloadFailure(CancellationError()).allowsDownload)
        XCTAssertFalse(Status.mmpkLoadFailure(CancellationError()).allowsDownload)
        XCTAssertFalse(Status.opened.allowsDownload)
    }
    
    func testIsDownloaded() {
        XCTAssertFalse(Status.notLoaded.isDownloaded)
        XCTAssertFalse(Status.loading.isDownloaded)
        XCTAssertFalse(Status.loadFailure(CancellationError()).isDownloaded)
        XCTAssertFalse(Status.packaging.isDownloaded)
        XCTAssertFalse(Status.packaged.isDownloaded)
        XCTAssertFalse(Status.packageFailure.isDownloaded)
        XCTAssertFalse(Status.downloading.isDownloaded)
        XCTAssertTrue(Status.downloaded.isDownloaded)
        XCTAssertFalse(Status.downloadFailure(CancellationError()).isDownloaded)
        XCTAssertFalse(Status.mmpkLoadFailure(CancellationError()).isDownloaded)
        XCTAssertFalse(Status.opened.isDownloaded)
    }
    
    func testIsOpened() {
        XCTAssertFalse(Status.notLoaded.isOpened)
        XCTAssertFalse(Status.loading.isOpened)
        XCTAssertFalse(Status.loadFailure(CancellationError()).isOpened)
        XCTAssertFalse(Status.packaging.isOpened)
        XCTAssertFalse(Status.packaged.isOpened)
        XCTAssertFalse(Status.packageFailure.isOpened)
        XCTAssertFalse(Status.downloading.isOpened)
        XCTAssertFalse(Status.downloaded.isOpened)
        XCTAssertFalse(Status.downloadFailure(CancellationError()).isOpened)
        XCTAssertFalse(Status.mmpkLoadFailure(CancellationError()).isOpened)
        XCTAssertTrue(Status.opened.isOpened)
    }
    
    func testAllowsRemoval() {
        XCTAssertFalse(Status.notLoaded.allowsRemoval)
        XCTAssertFalse(Status.loading.allowsRemoval)
        XCTAssertTrue(Status.loadFailure(CancellationError()).allowsRemoval)
        XCTAssertFalse(Status.packaging.allowsRemoval)
        XCTAssertFalse(Status.packaged.allowsRemoval)
        XCTAssertTrue(Status.packageFailure.allowsRemoval)
        XCTAssertFalse(Status.downloading.allowsRemoval)
        XCTAssertTrue(Status.downloaded.allowsRemoval)
        XCTAssertTrue(Status.downloadFailure(CancellationError()).allowsRemoval)
        XCTAssertTrue(Status.mmpkLoadFailure(CancellationError()).allowsRemoval)
        XCTAssertFalse(Status.opened.allowsRemoval)
    }
}

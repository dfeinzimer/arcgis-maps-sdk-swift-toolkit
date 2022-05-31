// Copyright 2022 Esri.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import ArcGIS
import Combine
import SwiftUI
import XCTest
@testable import ArcGISToolkit

@MainActor
final class FloorFilterViewModelTests: XCTestCase {
    /// Tests that a `FloorFilterViewModel` succesfully initializes with a `FloorManager` and
    /// `Binding<Viewpoint?>`.`
    /// Tests that a `FloorFilterViewModel` succesfully initializes with a `FloorManager`.`
    func testInitWithFloorManagerAndViewpoint() async throws {
        let floorManager = try await floorManager(
            forWebMapWithIdentifier: .testMap
        )
        
        let viewModel = FloorFilterViewModel(
            floorManager: floorManager,
            viewpoint: .constant(.researchAnnexLattice)
        )
        
        XCTAssertFalse(viewModel.sites.isEmpty)
        XCTAssertFalse(viewModel.facilities.isEmpty)
        XCTAssertFalse(viewModel.levels.isEmpty)
    }
    
    /// Confirms that the selected site/facility/level properties and the viewpoint are correctly updated.
    func testSetSite() async throws {
        let floorManager = try await floorManager(
            forWebMapWithIdentifier: .testMap
        )
        
        var _viewpoint: Viewpoint? = .researchAnnexLattice
        let viewpoint = Binding(get: { _viewpoint }, set: { _viewpoint = $0 })
        let viewModel = FloorFilterViewModel(
            floorManager: floorManager,
            viewpoint: viewpoint
        )
        
        let site = try XCTUnwrap(viewModel.sites.first)
        
        viewModel.setSite(site, zoomTo: true)
        let selectedSite = viewModel.selectedSite
        let selectedFacility = viewModel.selectedFacility
        let selectedLevel = viewModel.selectedLevel
        XCTAssertEqual(selectedSite, site)
        XCTAssertNil(selectedFacility)
        XCTAssertNil(selectedLevel)
        XCTAssertEqual(
            _viewpoint?.targetGeometry.extent.center.x,
            selectedSite?.geometry?.extent.center.x
        )
    }
    
    func testSetFacility() async throws {
        let floorManager = try await floorManager(
            forWebMapWithIdentifier: .testMap
        )
        
        var _viewpoint: Viewpoint? = .researchAnnexLattice
        let viewpoint = Binding(get: { _viewpoint }, set: { _viewpoint = $0 })
        let viewModel = FloorFilterViewModel(
            automaticSelectionMode: .never,
            floorManager: floorManager,
            viewpoint: viewpoint
        )
        
        let facility = try XCTUnwrap(viewModel.facilities.first)
        
        viewModel.setFacility(facility, zoomTo: true)
        let selectedFacility = viewModel.selectedFacility
        let selectedLevel = viewModel.selectedLevel
        let defaultLevel = selectedFacility?.defaultLevel
        XCTAssertEqual(selectedFacility, facility)
        XCTAssertEqual(selectedLevel, defaultLevel)
        XCTAssertEqual(
            _viewpoint?.targetGeometry.extent.center.x,
            selectedFacility?.geometry?.extent.center.x
        )
    }
    
    /// Confirms that the selected site/facility/level properties and the viewpoint are correctly updated.
    func testSetLevel() async throws {
        let floorManager = try await floorManager(
            forWebMapWithIdentifier: .testMap
        )
        
        let initialViewpoint: Viewpoint = .researchAnnexLattice
        var _viewpoint: Viewpoint? = initialViewpoint
        let viewpoint = Binding(get: { _viewpoint }, set: { _viewpoint = $0 })
        let viewModel = FloorFilterViewModel(
            floorManager: floorManager,
            viewpoint: viewpoint
        )
        
        let levels = viewModel.levels
        let level = try XCTUnwrap(levels.first)
        
        viewModel.setLevel(level)
        let selectedLevel = viewModel.selectedLevel
        XCTAssertEqual(selectedLevel, level)
        XCTAssertEqual(
            _viewpoint?.targetGeometry.extent.center.x,
            initialViewpoint.targetGeometry.extent.center.x
        )
        levels.forEach { level in
            if level.verticalOrder == selectedLevel?.verticalOrder {
                XCTAssertTrue(level.isVisible)
            } else {
                XCTAssertFalse(level.isVisible)
            }
        }
    }
    
    /// Confirms that the selected site/facility/level properties and the viewpoint are correctly updated.
    func testAutoSelectAlways() async throws {
        let floorManager = try await floorManager(
            forWebMapWithIdentifier: .testMap
        )
        
        let viewpointLosAngeles: Viewpoint = .losAngeles
        var _viewpoint: Viewpoint? = viewpointLosAngeles
        let viewpoint = Binding(get: { _viewpoint }, set: { _viewpoint = $0 })
        let viewModel = FloorFilterViewModel(
            automaticSelectionMode: .always,
            floorManager: floorManager,
            viewpoint: viewpoint
        )
        
        // Viewpoint is Los Angeles, selection should be nil
        viewModel.automaticallySelectFacilityOrSite()
        
        var selectedFacility = viewModel.selectedFacility
        var selectedSite = viewModel.selectedSite
        XCTAssertNil(selectedFacility)
        XCTAssertNil(selectedSite)
        
        _viewpoint = .researchAnnexLattice
        viewModel.automaticallySelectFacilityOrSite()
        
        // Viewpoint is the Lattice facility at the Research Annex site
        selectedFacility = viewModel.selectedFacility
        selectedSite = viewModel.selectedSite
        XCTAssertEqual(selectedSite?.name, "Research Annex")
        XCTAssertEqual(selectedFacility?.name, "Lattice")
        
        _viewpoint = .losAngeles
        viewModel.automaticallySelectFacilityOrSite()
        
        // Viewpoint is Los Angeles, selection should be nil
        selectedFacility = viewModel.selectedFacility
        selectedSite = viewModel.selectedSite
        XCTAssertNil(selectedSite)
        XCTAssertNil(selectedFacility)
    }
    
    /// Confirms that the selected site/facility/level properties and the viewpoint are correctly updated.
    func testAutoSelectAlwaysNotClearing() async throws {
        let floorManager = try await floorManager(
            forWebMapWithIdentifier: .testMap
        )
        
        var _viewpoint: Viewpoint? = .researchAnnexLattice
        let viewpoint = Binding(get: { _viewpoint }, set: { _viewpoint = $0 })
        let viewModel = FloorFilterViewModel(
            automaticSelectionMode: .alwaysNotClearing,
            floorManager: floorManager,
            viewpoint: viewpoint
        )
        
        viewModel.automaticallySelectFacilityOrSite()
        
        // Viewpoint is the Lattice facility at the Research Annex site
        var selectedFacility = viewModel.selectedFacility
        var selectedSite = viewModel.selectedSite
        XCTAssertEqual(selectedSite?.name, "Research Annex")
        XCTAssertEqual(selectedFacility?.name, "Lattice")
        
        // Viewpoint is Los Angeles, but selection should remain Redlands Main Q
        _viewpoint = .losAngeles
        viewModel.automaticallySelectFacilityOrSite()
        
        // Viewpoint is Los Angeles, but selection should remain Redlands Main Q
        selectedFacility = viewModel.selectedFacility
        selectedSite = viewModel.selectedSite
        XCTAssertEqual(selectedSite?.name, "Research Annex")
        XCTAssertEqual(selectedFacility?.name, "Lattice")
    }
    
    /// Confirms that the selected site/facility/level properties and the viewpoint are correctly updated.
    func testAutoSelectNever() async throws {
        let floorManager = try await floorManager(
            forWebMapWithIdentifier: .testMap
        )
        
        var _viewpoint: Viewpoint? = .losAngeles
        let viewpoint = Binding(get: { _viewpoint }, set: { _viewpoint = $0 })
        let viewModel = FloorFilterViewModel(
            automaticSelectionMode: .never,
            floorManager: floorManager,
            viewpoint: viewpoint
        )
        
        viewModel.automaticallySelectFacilityOrSite()
        
        // Viewpoint is Los Angeles, selection should be nil
        var selectedFacility = viewModel.selectedFacility
        var selectedSite = viewModel.selectedSite
        XCTAssertNil(selectedFacility)
        XCTAssertNil(selectedSite)
        
        _viewpoint = .researchAnnexLattice
        viewModel.automaticallySelectFacilityOrSite()
        
        // Viewpoint is the Lattice facility at the Research Annex site
        selectedFacility = viewModel.selectedFacility
        selectedSite = viewModel.selectedSite
        XCTAssertNil(selectedFacility)
        XCTAssertNil(selectedSite)
    }
    
    private func floorManager(
        forWebMapWithIdentifier id: PortalItem.ID,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> FloorManager {
        let portal = Portal(url: URL(string: "https://www.arcgis.com/")!, isLoginRequired: false)
        let item = PortalItem(portal: portal, id: id)
        let map = Map(item: item)
        try await map.load()
        let floorManager = try XCTUnwrap(map.floorManager, file: file, line: line)
        try await floorManager.load()
        return floorManager
    }
}

private extension PortalItem.ID {
    static let testMap = Self("b4b599a43a474d33946cf0df526426f5")!
}

private extension Viewpoint {
    static var researchAnnexLattice: Viewpoint {
        Viewpoint(
            center:
                Point(
                    x: -13045075.712950204,
                    y: 4036858.6146756615,
                    spatialReference: .webMercator
                ),
            scale: 550.0
        )
    }
    
    static let losAngeles = Viewpoint(
        center: Point(
            x: -13164116.3284,
            y: 4034465.8065,
            spatialReference: .webMercator
        ),
        scale: 10_000
    )
}

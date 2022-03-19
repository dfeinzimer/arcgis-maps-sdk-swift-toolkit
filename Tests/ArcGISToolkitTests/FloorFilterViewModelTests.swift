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

class FloorFilterViewModelTests: XCTestCase {
    /// Applies credentials necessary to run tests.
    override func setUp() async throws {
        await addCredentials()
    }

    /// Tests that a `FloorFilterViewModel` succesfully initializes with a `FloorManager`.`
    func testInitFloorFilterViewModelWithFloorManager() async {
        guard let map = await makeMap(),
              let floorManager = map.floorManager else {
            return
        }
        var _viewpoint: Viewpoint? = getEsriRedlandsViewpoint(.zero)
        let viewpoint = Binding(get: { _viewpoint }, set: { _viewpoint = $0 })
        let viewModel = await FloorFilterViewModel(
            floorManager: floorManager,
            viewpoint: viewpoint
        )
        await verifyInitialization(viewModel)
        let sites = await viewModel.sites
        let facilities = await viewModel.facilities
        let levels = await viewModel.levels
        XCTAssertFalse(sites.isEmpty)
        XCTAssertFalse(facilities.isEmpty)
        XCTAssertFalse(levels.isEmpty)
    }

    /// Tests that a `FloorFilterViewModel` succesfully initializes with a `FloorManager` and
    /// `Binding<Viewpoint>?`.`
    func testInitFloorFilterViewModelWithFloorManagerAndViewpoint() async {
        guard let map = await makeMap(),
              let floorManager = map.floorManager else {
            return
        }
        var _viewpoint: Viewpoint? = getEsriRedlandsViewpoint(.zero)
        let viewpoint = Binding(get: { _viewpoint }, set: { _viewpoint = $0 })
        let viewModel = await FloorFilterViewModel(
            floorManager: floorManager,
            viewpoint: viewpoint
        )
        await verifyInitialization(viewModel)
        let sites = await viewModel.sites
        let facilities = await viewModel.facilities
        let levels = await viewModel.levels
        let vmViewpoint = await viewModel.viewpoint
        XCTAssertFalse(sites.isEmpty)
        XCTAssertFalse(facilities.isEmpty)
        XCTAssertFalse(levels.isEmpty)
        XCTAssertNotNil(vmViewpoint)
    }

    /// Confirms that the selected site/facility/level properties and the viewpoint are correctly updated.
    func testSetSite() async {
        guard let map = await makeMap(),
              let floorManager = map.floorManager else {
            return
        }
        let initialViewpoint = getEsriRedlandsViewpoint(.zero)
        var _viewpoint: Viewpoint? = initialViewpoint
        let viewpoint = Binding(get: { _viewpoint }, set: { _viewpoint = $0 })
        let viewModel = await FloorFilterViewModel(
            floorManager: floorManager,
            viewpoint: viewpoint
        )
        await verifyInitialization(viewModel)
        let site = await viewModel.sites.first
        await viewModel.setSite(site)
        let selectedSite = await viewModel.selectedSite
        let selectedFacility = await viewModel.selectedFacility
        let selectedLevel = await viewModel.selectedLevel
        XCTAssertEqual(selectedSite, site)
        XCTAssertNil(selectedFacility)
        XCTAssertNil(selectedLevel)
        XCTAssertEqual(
            _viewpoint?.targetGeometry.extent.center.x,
            initialViewpoint.targetGeometry.extent.center.x
        )
        await viewModel.setSite(site, zoomTo: true)
        XCTAssertEqual(
            _viewpoint?.targetGeometry.extent.center.x,
            selectedSite?.geometry?.extent.center.x
        )
    }

    /// Confirms that the selected site/facility/level properties and the viewpoint are correctly updated.
    func testSetFacility() async {
        guard let map = await makeMap(),
              let floorManager = map.floorManager else {
            return
        }
        let initialViewpoint = getEsriRedlandsViewpoint(.zero)
        var _viewpoint: Viewpoint? = initialViewpoint
        let viewpoint = Binding(get: { _viewpoint }, set: { _viewpoint = $0 })
        let viewModel = await FloorFilterViewModel(
            automaticSelectionMode: .never,
            floorManager: floorManager,
            viewpoint: viewpoint
        )
        await verifyInitialization(viewModel)
        let facility = await viewModel.facilities.first
        await viewModel.setFacility(facility)
        let selectedFacility = await viewModel.selectedFacility
        let selectedLevel = await viewModel.selectedLevel
        let defaultLevel = await viewModel.defaultLevel(for: selectedFacility)
        XCTAssertEqual(selectedFacility, facility)
        XCTAssertEqual(selectedLevel, defaultLevel)
        XCTAssertEqual(
            _viewpoint?.targetGeometry.extent.center.x,
            initialViewpoint.targetGeometry.extent.center.x
        )
        await viewModel.setFacility(facility, zoomTo: true)
        XCTAssertEqual(
            _viewpoint?.targetGeometry.extent.center.x,
            selectedFacility?.geometry?.extent.center.x
        )
    }

    /// Confirms that the selected site/facility/level properties and the viewpoint are correctly updated.
    func testSetLevel() async {
        guard let map = await makeMap(),
              let floorManager = map.floorManager else {
            return
        }
        let initialViewpoint = getEsriRedlandsViewpoint(.zero)
        var _viewpoint: Viewpoint? = initialViewpoint
        let viewpoint = Binding(get: { _viewpoint }, set: { _viewpoint = $0 })
        let viewModel = await FloorFilterViewModel(
            floorManager: floorManager,
            viewpoint: viewpoint
        )
        await verifyInitialization(viewModel)
        let levels = await viewModel.levels
        let level = levels.first
        await viewModel.setLevel(level)
        let selectedLevel = await viewModel.selectedLevel
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
    func testAutoSelectAlways() async {
        guard let map = await makeMap(),
              let floorManager = map.floorManager else {
            return
        }
        let viewpointLosAngeles = Viewpoint(
            center: Point(
                x: -13164116.3284,
                y: 4034465.8065,
                spatialReference: .webMercator
            ),
            scale: 10_000
        )
        var _viewpoint: Viewpoint? = viewpointLosAngeles
        let viewpoint = Binding(get: { _viewpoint }, set: { _viewpoint = $0 })
        let viewModel = await FloorFilterViewModel(
            automaticSelectionMode: .always,
            floorManager: floorManager,
            viewpoint: viewpoint
        )
        await verifyInitialization(viewModel)

        // Viewpoint is Los Angeles, selection should be nil
        var selectedFacility = await viewModel.selectedFacility
        var selectedSite = await viewModel.selectedSite
        XCTAssertNil(selectedFacility)
        XCTAssertNil(selectedSite)

        // Viewpoint is Redlands Main Q
        _viewpoint = getEsriRedlandsViewpoint(scale: 1000)
        await viewModel.updateSelection()
        selectedFacility = await viewModel.selectedFacility
        selectedSite = await viewModel.selectedSite
        XCTAssertEqual(selectedSite?.name, "Redlands Main")
        XCTAssertEqual(selectedFacility?.name, "Q")

        // Viewpoint is Los Angeles, selection should be nil
        _viewpoint = viewpointLosAngeles
        await viewModel.updateSelection()
        selectedFacility = await viewModel.selectedFacility
        selectedSite = await viewModel.selectedSite
        XCTAssertNil(selectedSite)
        XCTAssertNil(selectedFacility)
    }

    /// Confirms that the selected site/facility/level properties and the viewpoint are correctly updated.
    func testAutoSelectAlwaysNotClearing() async {
        guard let map = await makeMap(),
              let floorManager = map.floorManager else {
            return
        }
        let viewpointLosAngeles = Viewpoint(
            center: Point(
                x: -13164116.3284,
                y: 4034465.8065,
                spatialReference: .webMercator
            ),
            scale: 10_000
        )
        var _viewpoint: Viewpoint? = getEsriRedlandsViewpoint(scale: 1000)
        let viewpoint = Binding(get: { _viewpoint }, set: { _viewpoint = $0 })
        let viewModel = await FloorFilterViewModel(
            automaticSelectionMode: .alwaysNotClearing,
            floorManager: floorManager,
            viewpoint: viewpoint
        )
        await verifyInitialization(viewModel)

        // Viewpoint is Redlands Main Q
        _viewpoint = getEsriRedlandsViewpoint(scale: 1000)
        await viewModel.updateSelection()
        var selectedFacility = await viewModel.selectedFacility
        var selectedSite = await viewModel.selectedSite
        XCTAssertEqual(selectedSite?.name, "Redlands Main")
        XCTAssertEqual(selectedFacility?.name, "Q")

        // Viewpoint is Los Angeles, but selection should remain Redlands Main Q
        _viewpoint = viewpointLosAngeles
        await viewModel.updateSelection()
        selectedFacility = await viewModel.selectedFacility
        selectedSite = await viewModel.selectedSite
        XCTAssertEqual(selectedSite?.name, "Redlands Main")
        XCTAssertEqual(selectedFacility?.name, "Q")
    }

    /// Confirms that the selected site/facility/level properties and the viewpoint are correctly updated.
    func testAutoSelectNever() async {
        guard let map = await makeMap(),
              let floorManager = map.floorManager else {
            return
        }
        let viewpointLosAngeles = Viewpoint(
            center: Point(
                x: -13164116.3284,
                y: 4034465.8065,
                spatialReference: .webMercator
            ),
            scale: 10_000
        )
        var _viewpoint: Viewpoint? = viewpointLosAngeles
        let viewpoint = Binding(get: { _viewpoint }, set: { _viewpoint = $0 })
        let viewModel = await FloorFilterViewModel(
            automaticSelectionMode: .never,
            floorManager: floorManager,
            viewpoint: viewpoint
        )
        await verifyInitialization(viewModel)

        // Viewpoint is Los Angeles, selection should be nil
        var selectedFacility = await viewModel.selectedFacility
        var selectedSite = await viewModel.selectedSite
        XCTAssertNil(selectedFacility)
        XCTAssertNil(selectedSite)

        // Viewpoint is Redlands Main Q but selection should still be nil
        _viewpoint = getEsriRedlandsViewpoint(scale: 1000)
        await viewModel.updateSelection()
        selectedFacility = await viewModel.selectedFacility
        selectedSite = await viewModel.selectedSite
        XCTAssertNil(selectedFacility)
        XCTAssertNil(selectedSite)
    }

    /// Get a map constructed from an ArcGIS portal item.
    /// - Returns: A map constructed from an ArcGIS portal item.
    private func makeMap() async -> Map? {
        // Multiple sites/facilities: Esri IST map with all buildings.
//        let portal = Portal(url: URL(string: "https://indoors.maps.arcgis.com/")!, isLoginRequired: false)
//        let portalItem = PortalItem(portal: portal, id: Item.ID(rawValue: "49520a67773842f1858602735ef538b5")!)

        // Redlands Campus map with multiple sites and facilities.
        let portal = Portal(url: URL(string: "https://runtimecoretest.maps.arcgis.com/")!, isLoginRequired: false)
        let portalItem = PortalItem(portal: portal, id: Item.ID(rawValue: "7687805bd42549f5ba41237443d0c60a")!)

        // Single site (ESRI Redlands Main) and facility (Building L).
//        let portal = Portal(url: URL(string: "https://indoors.maps.arcgis.com/")!, isLoginRequired: false)
//        let portalItem = PortalItem(portal: portal, id: Item.ID(rawValue: "f133a698536f44c8884ad81f80b6cfc7")!)

        let map = Map(item: portalItem)
        do {
            try await map.load()
        } catch {
            XCTFail("\(#fileID), \(#function), \(#line), \(error.localizedDescription)")
            return nil
        }
        return map
    }

    /// Verifies that the `FloorFilterViewModel` has succesfully initialized.
    /// - Parameter viewModel: The view model to analyze.
    private func verifyInitialization(_ viewModel: FloorFilterViewModel) async {
        let expectation = XCTestExpectation(
            description: "View model successfully initialized"
        )
        let subscription = await viewModel.$isLoading
            .sink { loading in
                if !loading {
                    expectation.fulfill()
                }
            }
        wait(for: [expectation], timeout: 10.0)
        subscription.cancel()
    }
}

extension FloorFilterViewModelTests {
    /// The coordinates for the Redlands Esri campus.
    var point: Point {
        Point(
            x: -13046157.242121734,
            y: 4036329.622884897,
            spatialReference: .webMercator
        )
    }

    /// Builds viewpoints to use for tests.
    /// - Parameter rotation: The rotation to use for the resulting viewpoint.
    /// - Returns: A viewpoint object for tests.
    func getEsriRedlandsViewpoint(_ rotation: Double = .zero, scale: Double = 10_000) -> Viewpoint {
        return Viewpoint(center: point, scale: scale, rotation: rotation)
    }
}

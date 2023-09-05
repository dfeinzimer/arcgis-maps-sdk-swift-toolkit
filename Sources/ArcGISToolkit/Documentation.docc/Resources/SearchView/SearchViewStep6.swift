import SwiftUI
import ArcGIS
import ArcGISToolkit

struct SearchExampleView: View {
    let locatorDataSource = SmartLocatorSearchSource(
        name: "My locator",
        maximumResults: 16,
        maximumSuggestions: 16
    )
    
    @StateObject private var dataModel = MapDataModel(
        map: Map(basemapStyle: .arcGISImagery)
    )
    
    private let searchResultsOverlay = GraphicsOverlay()
    
    @State private var searchResultViewpoint: Viewpoint? = Viewpoint(
        center: Point(x: -93.258133, y: 44.986656, spatialReference: .wgs84),
        scale: 1000000
    )
    
    @State private var isGeoViewNavigating = false
    
    @State private var geoViewExtent: Envelope?
    
    @State private var queryArea: Geometry?
    
    @State private var queryCenter: Point?
    
    var body: some View {
        MapViewReader { mapViewProxy in
            MapView(
                map: dataModel.map,
                viewpoint: searchResultViewpoint,
                graphicsOverlays: [searchResultsOverlay]
            )
            .overlay {
                SearchView(
                    sources: [locatorDataSource],
                    viewpoint: $searchResultViewpoint,
                    geoViewProxy: mapViewProxy
                )
            }
        }
    }
}

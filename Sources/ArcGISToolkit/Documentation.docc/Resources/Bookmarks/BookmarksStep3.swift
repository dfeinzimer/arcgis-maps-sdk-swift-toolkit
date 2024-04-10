import ArcGIS
import ArcGISToolkit
import SwiftUI

struct BookmarksExampleView: View {
    @State private var bookmarksIsPresented = false
    
    @State private var map = Map(url: URL(string: "https://www.arcgis.com/home/item.html?id=16f1b8ba37b44dc3884afc8d5f454dd2")!)!
    
    @State private var selection: Bookmark?
    
    var body: some View {
        MapViewReader { mapViewProxy in
            MapView(map: map)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            bookmarksIsPresented.toggle()
                        } label: {
                            Label(
                                "Show Bookmarks",
                                systemImage: "bookmark"
                            )
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $bookmarksIsPresented) {
                            Bookmarks(
                                isPresented: $bookmarksIsPresented,
                                geoModel: map,
                                selection: $selection
                            )
                        }
                    }
                }
        }
    }
}

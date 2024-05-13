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

import SwiftUI
import ArcGIS

public struct PreplannedListItemView: View {
    /// The view model for the preplanned map.
    @ObservedObject var preplannedMapModel: PreplannedMapModel
    /// The view model for the map view.
    @ObservedObject var mapViewModel: OfflineMapAreasView.MapViewModel
    /// A Boolean value indicating whether the preplanned map area can be downloaded.
    @State private var canDownload = true
    
    public var body: some View {
        HStack {
            HStack {
                let preplannedMapArea = preplannedMapModel.preplannedMapArea
                if let thumbnail = preplannedMapModel.preplannedMapArea.portalItem.thumbnail {
                    LoadableImageView(loadableImage: thumbnail)
                        .frame(width: 64, height: 44)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(preplannedMapArea.portalItem.title)
                        .font(.headline)
                    if !preplannedMapArea.portalItem.description.isEmpty {
                        Text(preplannedMapArea.portalItem.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                switch preplannedMapModel.result {
                case .success:
                    Image(systemName: "checkmark.circle.fill")
                case .failure:
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.red)
                case .none:
                    if !canDownload {
                        // Map is still packaging.
                        Image(systemName: "clock.badge.xmark")
                    } else {
                        // Map package is available for download.
                        Image(systemName: "arrow.down.circle")
                    }
                }
            }
            .onReceive(preplannedMapModel.preplannedMapArea.$loadStatus) { status in
                // If the preplanned map area fails to load, it may not be packaged.
                if status == .failed {
                    canDownload = false
                } else if preplannedMapModel.preplannedMapArea.packagingStatus == .complete {
                    // Otherwise, check the packaging status to determine if the map area is
                    // available to download.
                    canDownload = true
                }
            }
            .task {
                do {
                    try await preplannedMapModel.preplannedMapArea.load()
                } catch {
                    print(error)
                }
            }
        }
    }
}

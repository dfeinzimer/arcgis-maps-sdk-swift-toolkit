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

import ArcGIS
import Combine
import Foundation
import UIKit

extension OfflineMapAreasView {
    /// The model class for the offline map areas view.
    @MainActor
    class MapViewModel: ObservableObject {
        /// The portal item ID of the web map.
        private let portalItemID: PortalItem.ID?
        
        /// The offline map task.
        private let offlineMapTask: OfflineMapTask
        
        /// The preplanned offline map information.
        @Published private(set) var preplannedMapModels: Result<[PreplannedMapModel], Error>?
        
        /// The offline preplanned map information.
        @Published private(set) var offlinePreplannedModels = [PreplannedMapModel]()
        
        init(map: Map) {
            offlineMapTask = OfflineMapTask(onlineMap: map)
            portalItemID = map.item?.id
        }
        
        /// Gets the preplanned map areas from the offline map task and creates the
        /// preplanned map models.
        func makePreplannedMapModels() async {
            guard let portalItemID else { return }
            
            preplannedMapModels = await Result {
                try await offlineMapTask.preplannedMapAreas
                    .filter { $0.id != nil }
                    .sorted(using: KeyPathComparator(\.portalItem.title))
                    .map {
                        PreplannedMapModel(
                            offlineMapTask: offlineMapTask,
                            mapArea: $0,
                            portalItemID: portalItemID,
                            preplannedMapAreaID: $0.id!
                        )
                    }
            }
        }
        
        /// Gets the offline preplanned map areas by using the preplanned map area IDs found in the
        /// preplanned map areas directory to create preplanned map models.
        func makeOfflinePreplannedMapModels() {
            guard let portalItemID else { return }
            
            do {
                let portalItemDirectory = FileManager.default.preplannedAreasDirectory(
                    forPortalItemID: portalItemID
                )
                let preplannedMapAreaDirectories = try FileManager.default.contentsOfDirectory(
                    at: portalItemDirectory,
                    includingPropertiesForKeys: nil
                )
                
                let mapAreas = preplannedMapAreaDirectories
                    .compactMap { PortalItem.ID($0.lastPathComponent) }
                    .compactMap { mapAreaID in
                        readMetadata(
                            for: portalItemID,
                            preplannedMapAreaID: mapAreaID
                        )
                    }
                
                offlinePreplannedModels = mapAreas.map { mapArea in
                    PreplannedMapModel(
                        mapArea: mapArea,
                        portalItemID: portalItemID,
                        preplannedMapAreaID: mapArea.id!
                    )
                }
                .sorted(using: KeyPathComparator(\.preplannedMapArea.title))
                
            } catch {
                return
            }
        }
        
        /// Reads the metadata for a given preplanned map area from a portal item and returns a preplanned
        /// map area protocol constructed with the metadata.
        /// - Parameters:
        ///   - portalItemID: The ID for the portal item.
        ///   - preplannedMapAreaID: The ID for the preplanned map area.
        /// - Returns: A preplanned map area protocol.
        private func readMetadata(
            for portalItemID: PortalItem.ID,
            preplannedMapAreaID: PortalItem.ID
        ) -> PreplannedMapAreaProtocol? {
            do {
                let metadataPath = FileManager.default.metadataPath(
                    forPortalItemID: portalItemID,
                    preplannedMapAreaID: preplannedMapAreaID
                )
                let contentString = try String(contentsOf: metadataPath)
                let jsonData = Data(contentString.utf8)
                
                let thumbnailURL = FileManager.default.thumbnailPath(
                    forPortalItemID: portalItemID,
                    preplannedMapAreaID: preplannedMapAreaID
                )
                let thumbnailImage = UIImage(contentsOfFile: thumbnailURL.relativePath)
                
                if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    guard let title = json[OfflineMapAreasView.title] as? String,
                          let description = json[OfflineMapAreasView.description] as? String,
                          let id = json[OfflineMapAreasView.id] as? String,
                          let itemID = PortalItem.ID(id) else { return nil }
                    return OfflinePreplannedMapArea(
                        title: title,
                        description: description,
                        id: itemID,
                        thumbnailImage: thumbnailImage
                    )
                }
            } catch {
                return nil
            }
            return nil
        }
        
        /// Requests authorization to show notifications.
        func requestUserNotificationAuthorization() async {
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        }
    }
}

private struct OfflinePreplannedMapArea: PreplannedMapAreaProtocol {
    var packagingStatus: PreplannedMapArea.PackagingStatus?
    
    var title: String
    
    var description: String
    
    var thumbnail: LoadableImage?
    
    var thumbnailImage: UIImage?
    
    var id: PortalItem.ID?
    
    func retryLoad() async throws {}
    
    func makeParameters(using offlineMapTask: OfflineMapTask) async throws -> DownloadPreplannedOfflineMapParameters {
        DownloadPreplannedOfflineMapParameters()
    }
    
    init(
        title: String,
        description: String,
        id: PortalItem.ID,
        thumbnailImage: UIImage? = nil
    ) {
        self.title = title
        self.description = description
        self.id = id
        self.thumbnailImage = thumbnailImage
    }
}

extension OfflineMapAreasView {
    static let title = "title"
    static let description = "description"
    static let id = "id"
}

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
import Foundation

extension FileManager {
    /// Calculates the size of a directory and all its contents.
    /// - Parameter url: The directory's URL.
    /// - Returns: The total size in bytes.
    func sizeOfDirectory(at url: URL) -> Int {
        guard let enumerator = enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var accumulatedSize = 0
        for case let fileURL as URL in enumerator {
            guard let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
                continue
            }
            accumulatedSize += size
        }
        return accumulatedSize
    }
    
    /// Returns a Boolean value indicating if the specified directory is empty.
    /// - Parameter path: The path to check.
    func isDirectoryEmpty(atPath path: URL) -> Bool {
        (try? FileManager.default.contentsOfDirectory(atPath: path.path()).isEmpty) ?? true
    }
}

extension URL {
    /// The path to the web map directory for a specific portal item.
    /// `Documents/OfflineMapAreas/<Portal Item ID>/`
    /// - Parameter portalItemID: The ID of the web map portal item.
    private static func portalItemDirectory(forPortalItemID portalItemID: PortalItem.ID) -> URL {
        URL.documentsDirectory.appending(components: "OfflineMapAreas", "\(portalItemID)/")
    }
    
    /// The path to the directory for a specific map area from the preplanned map areas directory for a specific portal item.
    /// `Documents/OfflineMapAreas/<Portal Item ID>/Preplanned/<Preplanned Area ID>/`
    /// - Parameters:
    ///   - portalItemID: The ID of the web map portal item.
    ///   - preplannedMapAreaID: The ID of the preplanned map area portal item.
    /// - Returns: A URL to the preplanned map area directory.
    static func preplannedDirectory(
        forPortalItemID portalItemID: PortalItem.ID,
        preplannedMapAreaID: PortalItem.ID? = nil
    ) -> URL {
        if let preplannedMapAreaID {
            portalItemDirectory(forPortalItemID: portalItemID).appending(components: "Preplanned", "\(preplannedMapAreaID)/")
        } else {
            portalItemDirectory(forPortalItemID: portalItemID).appending(components: "Preplanned/")
        }
    }
}

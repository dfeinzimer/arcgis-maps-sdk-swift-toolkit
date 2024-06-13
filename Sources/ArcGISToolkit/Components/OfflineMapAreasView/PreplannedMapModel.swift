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

/// An object that encapsulates state about a preplanned map.
@MainActor
public class PreplannedMapModel: ObservableObject, Identifiable {
    /// The preplanned map area.
    let preplannedMapArea: any PreplannedMapAreaProtocol
    
    /// The task to use to take the area offline.
    private let offlineMapTask: OfflineMapTask
    
    /// The download directory for the preplanned map areas.
    private let preplannedDirectory: URL
    
    /// The ID of the preplanned map area.
    private let preplannedMapAreaID: String
    
    /// The mobile map package for the preplanned map area.
    private(set) var mobileMapPackage: MobileMapPackage?
    
    /// The currently running download job.
    @Published private(set) var job: DownloadPreplannedOfflineMapJob?
    
    /// The combined status of the preplanned map area.
    @Published private(set) var status: Status = .notLoaded
    
    /// The result of the download job. When the result is `.success` the mobile map package is returned.
    /// If the result is `.failure` then the error is returned. The result will be `nil` when the preplanned
    /// map area is still packaging or loading.
    @Published private(set) var result: Result<MobileMapPackage, Error>?
    
    /// A Boolean value indicating if download can be called.
    var canDownload: Bool {
        switch status {
        case .notLoaded, .loading, .loadFailure, .packaging, .packageFailure,
                .downloading, .downloaded:
            false
        case .packaged, .downloadFailure:
            true
        }
    }
    
    init?(
        offlineMapTask: OfflineMapTask,
        mapArea: PreplannedMapAreaProtocol,
        directory: URL
    ) {
        self.offlineMapTask = offlineMapTask
        preplannedMapArea = mapArea
        preplannedDirectory = directory
        
        if let itemID = preplannedMapArea.id {
            preplannedMapAreaID = itemID.rawValue
        } else {
            return nil
        }
        
        setDownloadJob()
        
        if let mobileMapPackage {
            self.mobileMapPackage = mobileMapPackage
            status = .downloaded
        }
    }
    
    /// Loads the preplanned map area and updates the status.
    func load() async {
        guard status.needsToBeLoaded else { return }
        do {
            // Load preplanned map area to obtain packaging status.
            status = .loading
            try await preplannedMapArea.retryLoad()
            // Note: Packaging status is `nil` for compatibility with
            // legacy webmaps that have incomplete metadata.
            // If the area loads, then you know for certain the status is complete.
            updateStatus(for: preplannedMapArea.packagingStatus ?? .complete)
        } catch MappingError.packagingNotComplete {
            // Load will throw an `MappingError.packagingNotComplete` error if not complete,
            // this case is not a normal load failure.
            updateStatus(for: preplannedMapArea.packagingStatus ?? .failed)
        } catch {
            // Normal load failure.
            status = .loadFailure(error)
        }
    }
    
    /// Sets the model download preplanned offline map job if the job is in progress.
    private func setDownloadJob() {
        for case let preplannedJob as DownloadPreplannedOfflineMapJob in JobManager.shared.jobs {
            if preplannedJob.downloadDirectoryURL.deletingPathExtension().lastPathComponent == preplannedMapAreaID {
                job = preplannedJob
                status = .downloading
                Task {
                    result = await job?.result.map { $0.mobileMapPackage }
                }
            }
        }
    }
    
    /// Updates the status for a given packaging status.
    private func updateStatus(for packagingStatus: PreplannedMapArea.PackagingStatus) {
        // Update area status for a given packaging status.
        switch packagingStatus {
        case .processing:
            status = .packaging
        case .failed:
            status = .packageFailure
        case .complete:
            status = .packaged
        @unknown default:
            fatalError("Unknown packaging status")
        }
    }
    
    /// Updates the status based on the download result of the mobile map package.
    func updateDownloadStatus(for downloadResult: Optional<Result<MobileMapPackage, any Error>>) {
        switch downloadResult {
        case .success(let mobileMapPackage):
            status = .downloaded
            self.mobileMapPackage = mobileMapPackage
        case .failure(let error):
            status = .downloadFailure(error)
        case .none:
            return
        }
    }
    
    /// Sets the mobile map package if downloaded locally.
    func setMobileMapPackage() {
        guard job == nil else { return }
        
        // Construct file URL for mobile map package with file structure:
        // .../OfflineMapAreas/Preplanned/{id}/package/{id}.mmpk
        let fileURL = preplannedDirectory
            .appending(path: preplannedMapAreaID, directoryHint: .isDirectory)
            .appending(component: PreplannedMapModel.PathComponents.package, directoryHint: .isDirectory)
            .appendingPathComponent(preplannedMapAreaID)
            .appendingPathExtension(PreplannedMapModel.PathComponents.mmpk)
        
        if FileManager.default.fileExists(atPath: fileURL.relativePath) {
            self.mobileMapPackage = MobileMapPackage.init(fileURL: fileURL)
            status = .downloaded
        }
    }
    
    /// Posts a local notification that the job completed with success or failure.
    func notifyJobCompleted() {
        guard let job,
              job.status == .succeeded || job.status == .failed,
              let preplannedMapArea = job.parameters.preplannedMapArea,
              let id = preplannedMapArea.id else { return }
        
        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound.default
        
        let jobStatus = job.status == .succeeded ? "Succeeded" : "Failed"
        
        content.title = "Download \(jobStatus)"
        content.body = "The job for \(preplannedMapArea.title) has \(jobStatus.lowercased())."
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = id.rawValue
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Downloads the preplanned map area.
    /// - Precondition: `canDownload`
    func downloadPreplannedMapArea() async {
        precondition(canDownload)
        status = .downloading
        
        do {
        let (downloadDirectory, mmpkDirectory) = createDownloadDirectories()
        guard let mmpkDirectory,
              let downloadDirectory,
              let parameters = await createParameters() else { return }
        
        await runDownloadTask(for: parameters, in: mmpkDirectory, downloadDirectory: downloadDirectory)
         } catch {
            // If creating the parameters or directories fails, set the failure.
            self.result = .failure(error)
         }
    }
    
    /// Creates download directories for the preplanned map area and its mobile map package.
    /// - Returns: The URL for the mobile map package directory.
    private func createDownloadDirectories() -> (URL?, URL?) {
        guard let preplannedDirectory,
              let preplannedMapAreaID else { return (nil, nil) }
        let downloadDirectory = preplannedDirectory
            .appending(path: preplannedMapAreaID, directoryHint: .isDirectory)
        
        let packageDirectory = downloadDirectory
            .appending(component: PreplannedMapModel.PathComponents.package, directoryHint: .isDirectory)
        
        try FileManager.default.createDirectory(atPath: downloadDirectory.relativePath, withIntermediateDirectories: true)
        
        try FileManager.default.createDirectory(atPath: packageDirectory.relativePath, withIntermediateDirectories: true)
        
        let mmpkDirectory = packageDirectory
            .appendingPathComponent(preplannedMapAreaID)
            .appendingPathExtension(PreplannedMapModel.PathComponents.mmpk)
        
        return (downloadDirectory, mmpkDirectory)
    }
    
    /// Runs the download task to download the preplanned offline map.
    /// - Parameters:
    ///   - parameters: The parameters used to download the offline map.
    ///   - mmpkDirectory: The directory used to place the mobile map package result.
    private func runDownloadTask(
        for parameters: DownloadPreplannedOfflineMapParameters,
        in mmpkDirectory: URL,
        downloadDirectory: URL
    ) async {
        // Create the download preplanned offline map job.
        let job = offlineMapTask.makeDownloadPreplannedOfflineMapJob(
            parameters: parameters,
            downloadDirectory: mmpkDirectory
        )
        
        JobManager.shared.jobs.append(job)
        
        self.job = job
        
        // Start the job.
        job.start()
        
        // Await the output of the job and assigns the result.
        result = await job.result.map { $0.mobileMapPackage }
        
        // Save metadata if download succeeds.
        writeJSONFile(to: downloadDirectory, mmpkDirectory: mmpkDirectory)
    }
    
    /// Writes preplanned map area metadata and thumbnail image data to local files in the specified directories.
    /// - Parameters:
    ///   - directory: The directory for the preplanned map area.
    ///   - mmpkDirectory: The directory for the mobile map package.
    @MainActor
    private func writeJSONFile(to directory: URL, mmpkDirectory: URL) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        
        let fileURL = directory
            .appending(path: "metadata", directoryHint: .notDirectory)
            .appendingPathExtension("json")
        
        FileManager.default.createFile(atPath: fileURL.relativePath, contents: nil)
        
        // Save preplanned map area thumbnail image in `thumbnail.png` file.
        if let thumbnail = preplannedMapArea.thumbnail?.image {
            let thumbnailURL = directory
                .appending(path: "thumbnail", directoryHint: .notDirectory)
                .appendingPathExtension("png")
            
            FileManager.default.createFile(atPath: thumbnailURL.relativePath, contents: nil)
            
            if let thumbnailData = thumbnail.pngData() {
                try? thumbnailData.write(to: thumbnailURL, options: .atomic)
            }
        }
        
        // Save preplanned map area metadata in `metadata.json` file.
        guard let id = preplannedMapArea.id?.rawValue else { return }
        
        let jsonObject: [String: Any] = [
            "title" : preplannedMapArea.title,
            "description" : preplannedMapArea.description,
            "id" : id,
            "mmpkURL" : mmpkDirectory.relativePath
        ]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .sortedKeys)
            try jsonData.write(to: fileURL, options: .atomic)
        } catch {
            print(error)
        }
    }
}

extension PreplannedMapModel {
    /// The status of the preplanned map area model.
    enum Status {
        /// Preplanned map area not loaded.
        case notLoaded
        /// Preplanned map area is loading.
        case loading
        /// Preplanned map area failed to load.
        case loadFailure(Error)
        /// Preplanned map area is packaging.
        case packaging
        /// Preplanned map area is packaged and ready for download.
        case packaged
        /// Preplanned map area packaging failed.
        case packageFailure
        /// Preplanned map area is being downloaded.
        case downloading
        /// Preplanned map area is downloaded.
        case downloaded
        /// Preplanned map area failed to download.
        case downloadFailure(Error)
        
        /// A Boolean value indicating whether the model is in a state
        /// where it needs to be loaded or reloaded.
        var needsToBeLoaded: Bool {
            switch self {
            case .loading, .packaging, .packaged, .downloading, .downloaded:
                false
            default:
                true
            }
        }
    }
}

private extension PreplannedMapModel {
    enum PathComponents {
        static var package: String { "package" }
        static var mmpk: String { "mmpk" }
    }
}

extension PreplannedMapModel: Hashable {
    nonisolated public static func == (lhs: PreplannedMapModel, rhs: PreplannedMapModel) -> Bool {
        lhs === rhs
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

/// A type that acts as a preplanned map area.
protocol PreplannedMapAreaProtocol {
    func retryLoad() async throws
    func makeParameters(using offlineMapTask: OfflineMapTask) async throws -> DownloadPreplannedOfflineMapParameters?
    
    var packagingStatus: PreplannedMapArea.PackagingStatus? { get }
    var title: String { get }
    var description: String { get }
    var thumbnail: LoadableImage? { get }
    var thumbnailImage: UIImage? { get }
    var id: PortalItem.ID? { get }
}

/// Extend `PreplannedMapArea` to conform to `PreplannedMapAreaProtocol`.
extension PreplannedMapArea: PreplannedMapAreaProtocol {
    func makeParameters(using offlineMapTask: OfflineMapTask) async throws -> DownloadPreplannedOfflineMapParameters? {
        // Create the parameters for the download preplanned offline map job.
        let parameters = try await offlineMapTask.makeDefaultDownloadPreplannedOfflineMapParameters(
            preplannedMapArea: self
        )
        // Set the update mode to no updates as the offline map is display-only.
        parameters.updateMode = .noUpdates
        
        return parameters
    }
    
    var title: String {
        portalItem.title
    }
    
    var thumbnail: LoadableImage? {
        portalItem.thumbnail
    }
    
    var thumbnailImage: UIImage? { nil }
    
    var description: String {
        portalItem.description
    }
    
    var id: PortalItem.ID? {
        portalItem.id
    }
}

struct OfflinePreplannedMapArea: PreplannedMapAreaProtocol {
    func retryLoad() async throws {}
    
    init(
        mapArea: ArcGIS.PreplannedMapArea? = nil,
        packagingStatus: ArcGIS.PreplannedMapArea.PackagingStatus? = nil,
        title: String,
        description: String,
        thumbnail: ArcGIS.LoadableImage? = nil,
        thumbnailImage: UIImage? = nil,
        id: ArcGIS.Item.ID? = nil
    ) {
        self.mapArea = mapArea
        self.packagingStatus = packagingStatus
        self.title = title
        self.description = description
        self.thumbnail = thumbnail
        self.thumbnailImage = thumbnailImage
        self.id = id
    }
    var mapArea: ArcGIS.PreplannedMapArea?
    
    var packagingStatus: ArcGIS.PreplannedMapArea.PackagingStatus?
    
    var title: String
    
    var description: String
    
    var thumbnail: ArcGIS.LoadableImage?
    
    var thumbnailImage: UIImage?
    
    var id: ArcGIS.Item.ID?
}

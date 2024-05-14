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
import OSLog
import SwiftUI
import UniformTypeIdentifiers

/// The context menu shown when the new attachment button is pressed.
struct AttachmentImportMenu: View {
    
    /// The attachment form element displaying the menu.
    private let element: AttachmentsFormElement
    
    /// Creates an `AttachmentImportMenu`
    /// - Parameter element: The attachment form element displaying the menu.
    /// - Parameter onAdd: The action to perform when an attachment is added.
    init(element: AttachmentsFormElement, onAdd: ((FeatureAttachment) async throws -> Void)? = nil) {
        self.element = element
        self.onAdd = onAdd
    }
    
    /// A Boolean value indicating whether the attachment camera controller is presented.
    @State private var cameraIsShowing = false
    
    /// A Boolean value indicating whether the attachment file importer is presented.
    @State private var fileImporterIsShowing = false
    
    /// A Boolean value indicating whether the attachment photo picker is presented.
    @State private var photoPickerIsPresented = false
    
    /// The new image attachment data retrieved from the photos picker.
    @State private var newAttachmentImportData: AttachmentImportData?
    
    /// The new attachment retrieved from the device's camera.
    @State private var capturedImage: UIImage?
    
    /// The action to perform when an attachment is added.
    let onAdd: ((FeatureAttachment) async throws -> Void)?
    
    private func takePhotoOrVideoButton() -> Button<some View> {
       Button {
            cameraIsShowing = true
        } label: {
            Label {
                Text(
                    "Take Photo or Video",
                    bundle: .toolkitModule,
                    comment: "A label for a button to capture a new photo or video."
                )
            } icon: {
                Image(systemName: "camera")
            }
            .labelStyle(.titleAndIcon)
        }
    }
    
    private func chooseFromLibraryButton() -> Button<some View> {
       Button {
            photoPickerIsPresented = true
        } label: {
            Label {
                Text(
                    "Choose From Library",
                    bundle: .toolkitModule,
                    comment: "A label for a button to choose a photo or video from the user's photo library."
                )
            } icon: {
                Image(systemName: "photo")
            }
            .labelStyle(.titleAndIcon)
        }
    }
    
    private func chooseFromFilesButton() -> Button<some View> {
       Button {
            fileImporterIsShowing = true
        } label: {
            Label {
                Text(
                    "Choose From Files",
                    bundle: .toolkitModule,
                    comment: "A label for a button to choose an file from the user's files."
                )
            } icon: {
                Image(systemName: "folder")
            }
            .labelStyle(.titleAndIcon)
        }
    }
    
    var body: some View {
        Menu {
            if element.input is AnyAttachmentsFormInput {
                // Show photo/video and library picker if
                // we're allowing all input types.
                takePhotoOrVideoButton()
                chooseFromLibraryButton()
            }
            // Always show file picker, no matter the input type.
            chooseFromFilesButton()
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .padding(5)
        }
#if targetEnvironment(macCatalyst)
        .menuStyle(.borderlessButton)
#endif
        .task(id: newAttachmentImportData) {
            guard let newAttachmentImportData else { return }
            do {
                var fileName: String
                if !newAttachmentImportData.fileName.isEmpty {
                    fileName = newAttachmentImportData.fileName
                } else {
                    // This is probably not good and should be re-thought.
                    // Look at how the `AGSPopupAttachmentsViewController` handles this
                    // https://devtopia.esri.com/runtime/cocoa/blob/b788189d3d2eb43b7da8f9cc9af18ed2f3aa6925/api/iOS/Popup/ViewController/AGSPopupAttachmentsViewController.m#L755
                    // and
                    // https://devtopia.esri.com/runtime/cocoa/blob/b788189d3d2eb43b7da8f9cc9af18ed2f3aa6925/api/iOS/Popup/ViewController/AGSPopupAttachmentsViewController.m#L725
                    fileName = "Attachment \(element.attachments.count + 1).\(newAttachmentImportData.contentType.split(separator: "/").last!)"
                }
                let newAttachment = try await element.addAttachment(
                    // Can this be better? What does legacy do?
                    name: fileName,
                    contentType: newAttachmentImportData.contentType,
                    data: newAttachmentImportData.data
                )
                try await onAdd?(newAttachment)
            } catch {
                // TODO: Figure out error handling
                print("Error adding attachment: \(error)")
            }
            self.newAttachmentImportData = nil
        }
        .task(id: capturedImage) {
            guard let capturedImage, let data = capturedImage.pngData() else { return }
            newAttachmentImportData = AttachmentImportData(data: data, contentType: "image/png")
            self.capturedImage = nil
        }
        .fileImporter(isPresented: $fileImporterIsShowing, allowedContentTypes: [.item]) { result in
            switch result {
            case .success(let url):
                // gain access to the url resource and verify there's data.
                if url.startAccessingSecurityScopedResource(),
                   let data = FileManager.default.contents(atPath: url.path) {
                    newAttachmentImportData = AttachmentImportData(
                        data: data,
                        contentType: url.mimeType(),
                        fileName: url.lastPathComponent
                    )
                } else {
                    print("File picker data was empty or could not get access.")
                }
                
                // release access
                url.stopAccessingSecurityScopedResource()
            case .failure(let error):
                print("Error importing from file importer: \(error).")
            }
        }
        .fullScreenCover(isPresented: $cameraIsShowing) {
            AttachmentCameraController(capturedImage: $capturedImage)
        }
        .modifier(
            AttachmentPhotoPicker(
                newAttachmentImportData: $newAttachmentImportData,
                photoPickerIsPresented: $photoPickerIsPresented
            )
        )
    }
}

extension URL {
    /// The Mime type based on the path extension.
    /// - Returns: The Mime type string.
    public func mimeType() -> String {
        if let mimeType = UTType(filenameExtension: self.pathExtension)?.preferredMIMEType {
            return mimeType
        }
        else {
            return "application/octet-stream"
        }
    }
}

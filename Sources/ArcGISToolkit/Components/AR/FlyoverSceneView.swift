// Copyright 2023 Esri.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import ARKit
import SwiftUI
import ArcGIS

extension FlyoverSceneView {
    class Model: NSObject, ObservableObject, ARSessionDelegate {
        var sceneViewProxy: SceneViewProxy?
        let configuration: ARWorldTrackingConfiguration
        let session = ARSession()
        let cameraController: TransformationMatrixCameraController
        
        init(initialCamera: Camera, translationFactor: Double) {
            configuration = ARWorldTrackingConfiguration()
            configuration.worldAlignment = .gravityAndHeading
            
            let cameraController = TransformationMatrixCameraController(originCamera: initialCamera)
            cameraController.translationFactor = translationFactor
            self.cameraController = cameraController
            
            super.init()
            
            session.delegate = self
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            updateLastGoodDeviceOrientation()
            sceneViewProxy?.updateCameraAndFieldOfView(frame: frame, cameraController: cameraController, orientation: lastGoodDeviceOrientation)
        }
        
        /// The last portrait or landscape orientation value.
        private var lastGoodDeviceOrientation = UIDeviceOrientation.portrait
        
        /// Updates the last good device orientation.
        func updateLastGoodDeviceOrientation() {
            // Get the device orientation, but don't allow non-landscape/portrait values.
            let deviceOrientation = UIDevice.current.orientation
            if deviceOrientation.isValidInterfaceOrientation {
                lastGoodDeviceOrientation = deviceOrientation
            }
        }
    }
}

/// A scene view that provides an augmented reality fly over experience.
public struct FlyoverSceneView: View {
    @State private var arViewProxy = ARSwiftUIViewProxy()
    private let sceneViewBuilder: (SceneViewProxy) -> SceneView
    @StateObject var model: Model
    
    /// Creates a fly over scene view.
    /// - Parameters:
    ///   - initialCamera: The initial camera.
    ///   - translationFactor: The translation factor that defines how much the scene view translates
    ///   as the device moves.
    ///   - sceneView: A closure that builds the scene view to be overlayed on top of the
    ///   augmented reality video feed.
    /// - Remark: The provided scene view will have certain properties overridden in order to
    /// be effectively viewed in augmented reality. Properties such as the camera controller,
    /// and view drawing mode.
    public init(
        initialCamera: Camera,
        translationFactor: Double,
        @ViewBuilder sceneView: @escaping (SceneViewProxy) -> SceneView
    ) {
        self.sceneViewBuilder = sceneView
        _model = StateObject(wrappedValue: Model(initialCamera: initialCamera, translationFactor: translationFactor))
    }
    
    public var body: some View {
        ZStack {
            SceneViewReader { sceneViewProxy in
                sceneViewBuilder(sceneViewProxy)
                    .cameraController(model.cameraController)
                    .onAppear {
                        model.sceneViewProxy = sceneViewProxy
                        model.session.run(model.configuration)
                    }
                    .onDisappear {
                        model.session.pause()
                    }
            }
        }
    }
}

extension SceneViewProxy {
    /// Updates the scene view's camera and field of view for a given augmented reality frame.
    /// - Parameters:
    ///   - frame: The current AR frame.
    ///   - cameraController: The current camera controller assigned to the scene view.
    ///   - orientation: The device orientation.
    func updateCameraAndFieldOfView(
        frame: ARFrame,
        cameraController: TransformationMatrixCameraController,
        orientation: UIDeviceOrientation
    ) {
        let cameraTransform = frame.camera.transform
        
        // Rotate camera transform 90 degrees counter-clockwise in the XY plane.
        let transform = simd_float4x4.init(
            cameraTransform.columns.1,
            -cameraTransform.columns.0,
            cameraTransform.columns.2,
            cameraTransform.columns.3
        )
        
        let quaternion = simd_quatf(transform)
        
        let transformationMatrix = TransformationMatrix.normalized(
            quaternionX: Double(quaternion.vector.x),
            quaternionY: Double(quaternion.vector.y),
            quaternionZ: Double(quaternion.vector.z),
            quaternionW: Double(quaternion.vector.w),
            translationX: Double(transform.columns.3.x),
            translationY: Double(transform.columns.3.y),
            translationZ: Double(transform.columns.3.z)
        )
        
        // Set the matrix on the camera controller.
        cameraController.transformationMatrix = .identity.adding(transformationMatrix)
        
        // Set FOV on scene view.
        let intrinsics = frame.camera.intrinsics
        let imageResolution = frame.camera.imageResolution
        
        setFieldOfViewFromLensIntrinsics(
            xFocalLength: intrinsics[0][0],
            yFocalLength: intrinsics[1][1],
            xPrincipal: intrinsics[2][0],
            yPrincipal: intrinsics[2][1],
            xImageSize: Float(imageResolution.width),
            yImageSize: Float(imageResolution.height),
            deviceOrientation: orientation
        )
    }
}

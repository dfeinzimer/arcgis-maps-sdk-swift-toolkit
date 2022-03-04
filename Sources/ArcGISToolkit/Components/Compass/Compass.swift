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
import SwiftUI

/// A Compass (alias North arrow) shows where north is in a `MapView` or `SceneView`.
public struct Compass: View {
    /// Determines if the compass should automatically hide/show itself when the parent view is oriented
    /// north.
    private let autoHide: Bool

    /// Controls the current opacity of the compass.
    @State
    private var opacity: Double

    /// Indicates if the compass should hide based on the current viewpoint rotation and autoHide
    /// preference.
    var shouldHide: Bool {
        guard let viewpoint = viewpoint else { return autoHide }
        return viewpoint.rotation.isZero && autoHide
    }

    /// Acts as link between the compass and the parent map or scene view.
    @Binding
    private var viewpoint: Viewpoint?

    /// Creates a `Compass`
    /// - Parameters:
    ///   - viewpoint: Acts a communication link between the `MapView` or `SceneView` and the
    ///   compass.
    ///   - autoHide: Determines if the compass automatically hides itself when the `MapView` or
    ///   `SceneView` is oriented north.
    public init(
        viewpoint: Binding<Viewpoint?>,
        autoHide: Bool = true
    ) {
        _viewpoint = viewpoint
        _opacity = State(initialValue: .zero)
        self.autoHide = autoHide
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                CompassBody()
                Needle()
                    .rotationEffect(
                        Angle(degrees: viewpoint?.compassHeading ?? .zero)
                    )
            }
            .frame(
                width: min(geometry.size.width, geometry.size.height),
                height: min(geometry.size.width, geometry.size.height)
            )
        }
        .opacity(opacity)
        .onTapGesture { resetHeading() }
        .onChange(of: viewpoint) { _ in
            let newOpacity: Double = shouldHide ? .zero : 1
            guard opacity != newOpacity else { return }
            withAnimation(.default.delay(shouldHide ? 0.25 : 0)) {
                opacity = newOpacity
            }
        }
        .onAppear { opacity = shouldHide ? 0 : 1 }
        .accessibilityLabel(viewpoint?.compassHeadingDescription ?? "Compass")
    }

    /// Resets the viewpoints `rotation` to zero.
    func resetHeading() {
        guard let viewpoint = viewpoint else { return }
        self.viewpoint = Viewpoint(
            center: viewpoint.targetGeometry.extent.center,
            scale: viewpoint.targetScale,
            rotation: .zero
        )
    }
}

internal extension Viewpoint {
    /// The heading appropriate for displaying a compass.
    /// - Remark: The viewpoint rotation is opposite of the direction of a compass needle.
    var compassHeading: Double {
        rotation.isZero ? .zero : 360 - rotation
    }

    /// A text description of the current heading, sutiable for accessibility voiceover.
    var compassHeadingDescription: String {
        "Compass, heading "
        + Int(self.compassHeading.rounded()).description
        + " degrees "
        + CompassDirection(self.compassHeading).rawValue
    }
}
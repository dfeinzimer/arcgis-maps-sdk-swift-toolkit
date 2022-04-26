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

/// Displays the current scale on-screen
public struct Scalebar: View {
    // - MARK: Internal/Private vars
    
    /// The vertical amount of space used by the scalebar.
    @State private var height: Double?
    
    /// The view model used by the `Scalebar`.
    @StateObject var viewModel: ScalebarViewModel
    
    /// The font used by the scalebar, available in both `Font` and `UIFont` types.
    internal static var font: (font: Font, uiFont: UIFont) {
        let size = 10.0
        let uiFont = UIFont.systemFont(
            ofSize: size,
            weight: .semibold
        )
        let font = Font(uiFont as CTFont)
        return (font, uiFont)
    }
    
    /// The rendering height of the scalebar font.
    internal static var fontHeight: Double {
        return "".size(withAttributes: [.font: Scalebar.font.uiFont]).height
    }
    
    /// Acts as a data provider of the current scale.
    private var viewpoint: Binding<Viewpoint?>
    
    // - MARK: Internal/Private constants
    
    /// The corner radius used by bar style scalebar renders.
    internal static let barCornerRadius = 2.5
    
    /// The frame height allotted to bar style scalebar renders.
    internal static let barFrameHeight = 10.0
    
    /// The darker fill color used by the alternating bar style render.
    internal static let fillColor1 = Color.black
    
    /// The lighter fill color used by the bar style renders.
    internal static let fillColor2 = Color(uiColor: .lightGray).opacity(0.5)
    
    /// The spacing between labels and the scalebar.
    internal static let labelYPad: CGFloat = 2.0
    
    /// The required padding between scalebar labels.
    internal static let labelXPad: CGFloat = 4.0
    
    /// The color of the prominent scalebar line.
    internal static let lineColor = Color.white
    
    /// The line height alloted to line style scalebar renders.
    internal static let lineFrameHeight = 6.0
    
    /// The width of the prominent scalebar line.
    internal static let lineWidth = 3.0
    
    /// The shadow color used by all scalebar style renders.
    internal static let shadowColor = Color(uiColor: .black).opacity(0.65)
    
    /// The shadow radius used by all scalebar style renders.
    internal static let shadowRadius = 1.0
    
    /// The text shadow color used by all scalebar style renders.
    internal static let textShadowColor = Color.white
    
    /// The render style for this `Scalebar`.
    private let style: ScalebarStyle
    
    // - MARK: Public methods/vars
    
    /// A scalebar displays the current map scale.
    /// - Parameters:
    ///   - autoHide: Set this to `true` to have the scalebar automatically show & hide itself.
    ///   - minScale: Set a minScale if you only want the scalebar to appear when you reach a large
    ///     enough scale maybe something like 10_000_000. This could be useful because the scalebar is
    ///     really only accurate for the center of the map on smaller scales (when zoomed way out). A
    ///     minScale of 0 means it will always be visible.
    ///   - spatialReference: The map's spatial reference.
    ///   - style: The visual appearance of the scalebar.
    ///   - units: The units to be displayed in the scalebar.
    ///   - unitsPerPoint: The current number of device independent pixels to map display units.
    ///   - useGeodeticCalculations: Set `false` to compute scale without a geodesic curve.
    ///   - viewpoint: The map's current viewpoint.
    ///   - width: The screen width alloted to the scalebar.
    public init(
        autoHide: Bool = false,
        minScale: Double = .zero,
        spatialReference: SpatialReference? = nil,
        style: ScalebarStyle = .alternatingBar,
        units: ScalebarUnits = NSLocale.current.usesMetricSystem ? .metric : .imperial,
        unitsPerPoint: Binding<Double?>,
        useGeodeticCalculations: Bool = true,
        viewpoint: Binding<Viewpoint?>,
        width: Double
    ) {
        self.style = style
        self.viewpoint = viewpoint
        
        _viewModel = StateObject(
            wrappedValue: ScalebarViewModel(
                autoHide,
                minScale,
                spatialReference,
                style,
                width,
                units,
                unitsPerPoint,
                useGeodeticCalculations,
                viewpoint.wrappedValue
            )
        )
    }
    
    public var body: some View {
        Group {
            if $viewModel.isVisible.wrappedValue {
                switch style {
                case .alternatingBar:
                    alternatingBarStyleRender
                case .bar:
                    barStyleRender
                case .dualUnitLine:
                    dualUnitLineStyleRender
                case .graduatedLine:
                    graduatedLineStyleRender
                case .line:
                    lineStyleRender
                }
            } else {
                EmptyView()
            }
        }
        .onChange(of: viewpoint.wrappedValue) {
            viewModel.viewpointSubject.send($0)
        }
        .onSizeChange {
            height = $0.height
        }
        .frame(
            width: $viewModel.displayLength.wrappedValue,
            height: height ?? .zero
        )
    }
}

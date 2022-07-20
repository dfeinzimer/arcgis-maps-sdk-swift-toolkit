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

extension UtilityNetworkTraceViewModel {
    /// A trace performed on a utility network.
    struct Trace {
        /// A collection of asset labels for all elements returned in the trace.
        var assetLabels = [String]()
        
        /// A user given color for the trace with a default value of green.
        var color: Color = .green {
            didSet {
                // Update the color of any pre-existing starting points
                startingPoints.forEach { startingPoint in
                    guard let symbol = startingPoint.graphic.symbol as? SimpleMarkerSymbol else { return }
                    symbol.color = UIColor(color)
                }
            }
        }
        
        /// The chosen named trace configuration.
        var configuration: UtilityNamedTraceConfiguration?
        
        /// A collection of utility trace function outputs.
        var functionOutputs = [UtilityTraceFunctionOutput]()
        
        /// A collection of graphics generated from the trace.
        var graphics = [Graphic]()
        
        /// A user given name for the trace.
        var name = ""
        
        /// A collection of starting points for the trace.
        var startingPoints = [UtilityNetworkTraceStartingPoint]()
        
        /// A trace result comprised of a collection of UtilityElement objects.
        var utilityElementTraceResult: UtilityElementTraceResult?
        
        /// A trace result comprised of a collection of UtilityTraceFunctionOutput objects.
        var utilityFunctionTraceResult: UtilityFunctionTraceResult?
        
        /// A trace result comprised of Geometry objects
        var utilityGeometryTraceResult: UtilityGeometryTraceResult?
    }
}
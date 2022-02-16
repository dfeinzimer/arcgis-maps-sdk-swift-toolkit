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

import SwiftUI

/// A modifier which displays a background and shadow for a view. Used to represent a selected view.
struct SelectedModifier: ViewModifier {
    /// `true` if the view should display as selected, `false` otherwise.
    var isSelected: Bool
    
    func body(content: Content) -> some View {
        let roundedRect = RoundedRectangle(cornerRadius: 4)
        if isSelected {
            content
                .background(Color.secondary.opacity(0.8))
                .clipShape(roundedRect)
                .shadow(
                    color: Color.secondary.opacity(0.8),
                    radius: 2
                )
        } else {
            content
        }
    }
}

extension View {
    /// View modifier used to denote the view is selected.
    /// - Parameter isSelected: `true` if the view is selected, `false` otherwise.
    /// - Returns: The view being modified.
    func selected(
        _ isSelected: Bool = false
    ) -> some View {
        modifier(SelectedModifier(isSelected: isSelected))
    }
}
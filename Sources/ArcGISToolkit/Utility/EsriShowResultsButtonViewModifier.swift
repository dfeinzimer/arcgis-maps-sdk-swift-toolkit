// Copyright 2021 Esri.

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

struct EsriShowResultsButtonViewModifier: ViewModifier {
    var isEnabled: Bool
    @Binding var isHidden: Bool
    
    func body(content: Content) -> some View {
        HStack {
            content
            if isEnabled {
                EmptyView()
            }
            else {
                Button(
                    action: { isHidden.toggle() },
                    label: {
                        Image(systemName: isHidden ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(Color(.opaqueSeparator))
                    }
                )
            }
        }
    }
}

extension View {
    func esriShowResultsButton(
        isEnabled: Bool,
        isHidden: Binding<Bool>
    ) -> some View {
        ModifiedContent(
            content: self,
            modifier: EsriShowResultsButtonViewModifier(
                isEnabled: isEnabled,
                isHidden: isHidden
            )
        )
    }
}

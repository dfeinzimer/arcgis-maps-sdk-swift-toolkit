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
import ArcGIS

/// A view displaying the elements of a single Popup.
public struct PopupView: View {
    /// Creates a `PopupView` with the given popup.
    /// - Parameters
    ///     popup: The popup to display.
    ///   - isPresented: A Boolean value indicating if the view is presented.
    public init(popup: Popup, isPresented: Binding<Bool>? = nil) {
        self.popup = popup
        self.isPresented = isPresented
    }
    
    /// The `Popup` to display.
    private var popup: Popup
    
    /// A Boolean value specifying whether a "close" button should be shown or not.  If the "close"
    /// button is shown, you should pass in the `isPresented` argument to the initializer,
    /// so that the the "close" button can close the view.
    private var showCloseButton = false
    
    /// A Boolean value indicating whether the popup's elements have been evaluated via
    /// the `popup.evaluateExpressions()` method.
    @State private var isPopupEvaluated: Bool? = nil

    /// The results of calling the `popup.evaluateExpressions()` method.
    @State private var expressionEvaluations: [PopupExpressionEvaluation]? = nil
    
    /// A binding to a Boolean value that determines whether the view is presented.
    private var isPresented: Binding<Bool>?

    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if !popup.title.isEmpty {
                    Text(popup.title)
                        .font(.title)
                        .fontWeight(.bold)
                }
                Spacer()
                if showCloseButton {
                    Button(action: {
                        isPresented?.wrappedValue = false
                    }, label: {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.secondary)
                            .padding([.top, .bottom, .trailing], 4)
                    })
                }
            }
            Divider()
            Group {
                if let isPopupEvaluated = isPopupEvaluated {
                    if isPopupEvaluated {
                        PopupElementScrollView(popup: popup)
                    } else {
                        Text("Popup evaluation failed.")
                    }
                } else {
                    VStack(alignment: .center) {
                        Text("Evaluating popup expressions...")
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .task {
            do {
                expressionEvaluations = try await popup.evaluateExpressions()
                isPopupEvaluated = true
            } catch {
                isPopupEvaluated = false
            }
        }
    }
    
    struct PopupElementScrollView: View {
        var popup: Popup
        var body: some View {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(Array(popup.evaluatedElements.enumerated()), id: \.offset) { index, popupElement in
                        switch popupElement {
                        case let popupElement as AttachmentsPopupElement:
                            AttachmentsPopupElementView(popupElement: popupElement)
                        case let popupElement as FieldsPopupElement:
                            FieldsPopupElementView(popupElement: popupElement)
                        case let popupElement as MediaPopupElement:
                            MediaPopupElementView(popupElement: popupElement)
                        case let popupElement as TextPopupElement:
                            TextPopupElementView(popupElement: popupElement)
                        default:
                            EmptyView()
                        }
                    }
                }
            }
        }
    }
}

extension PopupView {
    /// Specifies whether a "close" button should be shown to the right of the popup title.  If the "close"
    /// button is shown, you should pass in the `isPresented` argument to the `PopupView`
    /// initializer, so that the the "close" button can close the view.
    /// Defaults to `false`.
    /// - Parameter newShowCloseButton: The new value.
    /// - Returns: A new `PopupView`.
    public func showCloseButton(_ newShowCloseButton: Bool) -> Self {
        var copy = self
        copy.showCloseButton = newShowCloseButton
        return copy
    }
}

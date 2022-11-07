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
import UIKit

/// A view displaying the elements of a single Popup.
public struct PopupView: View {
    /// Creates a `PopupView` with the given popup.
    /// - Parameters
    ///     popup: The popup to display.
    ///   - isPresented: A Boolean value indicating if the view is presented.
    public init(popup: Popup, isPresented: Binding<Bool>? = nil) {
        self.popup = popup
        self.isPresented = isPresented
        
//        let navBarAppearance = UINavigationBarAppearance()
//        navBarAppearance.configureWithOpaqueBackground()
//        navBarAppearance.backgroundColor = UIColor(Color.primary.opacity(0.15))
//        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }
    
    /// The `Popup` to display.
    private let popup: Popup
    
    /// A Boolean value specifying whether a "close" button should be shown or not. If the "close"
    /// button is shown, you should pass in the `isPresented` argument to the initializer,
    /// so that the the "close" button can close the view.
    private var showCloseButton = false
    
    /// The result of evaluating the popup expressions.
    @State private var evaluateExpressionsResult: Result<[PopupExpressionEvaluation], Error>?
    
    /// A binding to a Boolean value that determines whether the view is presented.
    private var isPresented: Binding<Bool>?
    
    public var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack {
//                        PopupViewTitle(
//                            popup: self.popup,
//                            isPresented: isPresented,
//                            showCloseButton: showCloseButton,
//                            evaluateExpressionsResult: evaluateExpressionsResult
//                        )
                    Divider()
                    PopupViewBody(
                        popup: self.popup,
                        isPresented: isPresented,
                        showCloseButton: showCloseButton,
                        evaluateExpressionsResult: evaluateExpressionsResult
                    )
//                    .navigationTitle(popup.title)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Text(popup.title)
                                .font(.title)
                        }
                        ToolbarItem(placement: .primaryAction) {
//                            if showCloseButton {
                                Button(action: {
                                    isPresented?.wrappedValue = false
                                }, label: {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.accentColor)
                                        .padding([.top, .bottom, .trailing], 4)
                                })
//                            }

//                            Text(popup.title)
//                                .font(.headline)
                        }
                    }
                    .navigationDestination(for: Array<Popup>.self) { popupArray in
                        List(popupArray, id:\Popup.self) { popup in
                            NavigationLink(value: popup) {
                                VStack(alignment: .leading) {
                                    Text(popup.title)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .navigationTitle("Related Popups")
                    }
                    .navigationDestination(for: Popup.self) { popup in
                        PopupViewBody(
                            popup: popup,
                            showCloseButton: false,
                            evaluateExpressionsResult: Result<[PopupExpressionEvaluation], Error>.success([])
                        )
                        .navigationTitle(popup.title)
                    }
                    .navigationBarTitleDisplayMode(.inline)
                }
            } else {
                NavigationView {
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
                            if let evaluateExpressionsResult {
                                switch evaluateExpressionsResult {
                                case .success(_):
                                    PopupElementScrollView(popupElements: popup.evaluatedElements, popup: popup)
                                case .failure(let error):
                                    Text("Popup evaluation failed: \(error.localizedDescription)")
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
                }
            }
        }
        .task(id: ObjectIdentifier(popup)) {
            evaluateExpressionsResult = nil
            evaluateExpressionsResult = await Result {
                try await popup.evaluateExpressions()
            }
        }
    }
}

struct PopupViewInternal: View {
    let popup: Popup
    private var evaluateExpressionsResult: Result<[PopupExpressionEvaluation], Error>?
    private var showCloseButton = false
    private var isPresented: Binding<Bool>?
    
    /// Creates a `PopupView` with the given popup.
    /// - Parameters
    ///     popup: The popup to display.
    ///   - isPresented: A Boolean value indicating if the view is presented.
    public init(
        popup: Popup,
        isPresented: Binding<Bool>? = nil,
        showCloseButton: Bool,
        evaluateExpressionsResult: Result<[PopupExpressionEvaluation], Error>?
    ) {
        self.popup = popup
        self.isPresented = isPresented
        self.showCloseButton = showCloseButton
        self.evaluateExpressionsResult = evaluateExpressionsResult
    }
    
    var body: some View {
        VStack {
            PopupViewTitle(
                popup: self.popup,
                isPresented: isPresented,
                showCloseButton: showCloseButton,
                evaluateExpressionsResult: evaluateExpressionsResult
            )
            PopupViewBody(
                popup: self.popup,
                isPresented: isPresented,
                showCloseButton: showCloseButton,
                evaluateExpressionsResult: evaluateExpressionsResult
            )
        }
    }
}

struct PopupViewTitle: View {
    let popup: Popup
    private var evaluateExpressionsResult: Result<[PopupExpressionEvaluation], Error>?
    private var showCloseButton = false
    private var isPresented: Binding<Bool>?
    
    /// Creates a `PopupView` with the given popup.
    /// - Parameters
    ///     popup: The popup to display.
    ///   - isPresented: A Boolean value indicating if the view is presented.
    public init(
        popup: Popup,
        isPresented: Binding<Bool>? = nil,
        showCloseButton: Bool,
        evaluateExpressionsResult: Result<[PopupExpressionEvaluation], Error>?
    ) {
        self.popup = popup
        self.isPresented = isPresented
        self.showCloseButton = showCloseButton
        self.evaluateExpressionsResult = evaluateExpressionsResult
    }
    
    var body: some View {
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
        }
    }
}

struct PopupViewBody: View {
    let popup: Popup
    private var evaluateExpressionsResult: Result<[PopupExpressionEvaluation], Error>?
    private var showCloseButton = false
    private var isPresented: Binding<Bool>?
    
    /// Creates a `PopupView` with the given popup.
    /// - Parameters
    ///     popup: The popup to display.
    ///   - isPresented: A Boolean value indicating if the view is presented.
    public init(
        popup: Popup,
        isPresented: Binding<Bool>? = nil,
        showCloseButton: Bool,
        evaluateExpressionsResult: Result<[PopupExpressionEvaluation], Error>?
    ) {
        self.popup = popup
        self.isPresented = isPresented
        self.showCloseButton = showCloseButton
        self.evaluateExpressionsResult = evaluateExpressionsResult
    }
    
    var body: some View {
        Group {
            if let evaluateExpressionsResult {
                switch evaluateExpressionsResult {
                case .success(_):
                    PopupElementScrollView(popupElements: popup.evaluatedElements, popup: popup)
                case .failure(let error):
                    Text("Popup evaluation failed: \(error.localizedDescription)")
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
}

struct PopupElementScrollView: View {
    let popupElements: [PopupElement]
    let popup: Popup
    
    var body: some View {
        List(popupElements) { popupElement in
            Group {
                switch popupElement {
                case let popupElement as AttachmentsPopupElement:
                    AttachmentsPopupElementView(popupElement: popupElement)
                case let popupElement as FieldsPopupElement:
                    FieldsPopupElementView(popupElement: popupElement)
                case let popupElement as MediaPopupElement:
                    MediaPopupElementView(popupElement: popupElement)
                case let popupElement as RelationshipPopupElement:
                    RelationshipPopupElementView(
                        popupElement: popupElement,
                        geoElement: popup.geoElement
                    )
                case let popupElement as TextPopupElement:
                    TextPopupElementView(popupElement: popupElement)
                default:
                    EmptyView()
                }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .listStyle(.plain)
    }
}

extension PopupView {
    /// Specifies whether a "close" button should be shown to the right of the popup title. If the "close"
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

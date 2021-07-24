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

struct Examples: View {
    /// The list of example lists.  Allows for a hierarchical navigation model for examples.
    let lists: [ExampleList] = [
        .geoview
    ]
    
    var body: some View {
        NavigationView {
            List(lists) { (list) in
                NavigationLink(list.name, destination: list)
            }
            .navigationBarTitle(Text("Examples"), displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

extension ExampleList {
    static let geoview = Self(
        name: "GeoView",
        examples: [
            AnyExample("Overview Map", content: OverviewMapExampleView())
        ]
    )
}
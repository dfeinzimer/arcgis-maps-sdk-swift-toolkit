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

import Foundation
import ArcGIS

/// An object that represents an ArcGIS OAuth challenge continuation.
@MainActor
final class OAuthChallengeContinuation: ValueContinuation<Result<ArcGISAuthenticationChallenge.Disposition, Error>>, ArcGISChallengeContinuation {
    /// The OAuth configuration to be used for this challenge.
    let configuration: OAuthConfiguration
    
    /// Creates a `OAuthChallengeContinuation`.
    /// - Parameter configuration: The OAuth configuration to be used for this challenge.
    init(configuration: OAuthConfiguration) {
        self.configuration = configuration
    }
    
    /// Presents the user with a prompt to login with OAuth. This is done by creating the OAuth
    /// credential.
    func presentPrompt() {
        Task {
            setValue(await Result {
                .useCredential(try await .oauth(configuration: configuration))
            })
        }
    }
}
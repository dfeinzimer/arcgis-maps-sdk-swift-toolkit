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
import Combine

public final class QueuedChallenge {
    let challenge: ArcGISAuthenticationChallenge
    
    init(challenge: ArcGISAuthenticationChallenge) {
        self.challenge = challenge
    }

    func resume(with result: Result<ArcGISAuthenticationChallenge.Disposition, Error>) {
        guard _result == nil else { return }
        _result = result
    }
    
    func cancel() {
        guard _result == nil else { return }
        _result = .failure(CancellationError())
    }
    
    /// Use a streamed property because we need to support multiple listeners
    /// to know when the challenge completed.
    @Streamed
    private var _result: Result<ArcGISAuthenticationChallenge.Disposition, Error>?
    
    var disposition: ArcGISAuthenticationChallenge.Disposition {
        get async throws {
            try await $_result
                .compactMap({ $0 })
                .first(where: { _ in true })!
                .get()
        }
    }
}

extension QueuedChallenge: Identifiable {}

@MainActor
public final class Authenticator: ObservableObject {
    public init() {
        Task { await observeChallengeQueue() }
    }
    
    private func observeChallengeQueue() async {
        for await queuedChallenge in challengeQueue {
            print("  -- handing challenge")
            // Set the current challenge, this should show the challenge view.
            currentChallenge = queuedChallenge
            // Wait for the queued challenge to finish.
            _ = try? await queuedChallenge.disposition
            // Set the current challenge to `nil`, this should dismiss the challenge view.
            currentChallenge = nil
        }
    }

    @Published
    public var currentChallenge: QueuedChallenge?
    
    private var subject = PassthroughSubject<QueuedChallenge, Never>()
    private var challengeQueue: AsyncPublisher<AnyPublisher<QueuedChallenge, Never>> {
        AsyncPublisher(
            subject
                .buffer(size: .max, prefetch: .byRequest, whenFull: .dropOldest)
                .eraseToAnyPublisher()
        )
    }
}

extension Authenticator: AuthenticationChallengeHandler {
    public func handleArcGISChallenge(
        _ challenge: ArcGISAuthenticationChallenge
    ) async throws -> ArcGISAuthenticationChallenge.Disposition {
        print("-- high level challenge receieved")
        await Task.yield()
        
        guard challenge.proposedCredential == nil else {
            print("  -- performing default handling")
            return .performDefaultHandling
        }
        
        // Queue up the challenge.
        let queuedChallenge = QueuedChallenge(challenge: challenge)
        subject.send(queuedChallenge)
        
        // Wait for it to complete and return the resulting disposition.
        return try await queuedChallenge.disposition
    }
    
    public func handleURLSessionChallenge(
        _ challenge: URLAuthenticationChallenge,
        scope: URLAuthenticationChallengeScope
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            // This will cause a self-signed certificate to be trusted.
            return (.useCredential, URLCredential(trust: trust))
        } else {
            return (.performDefaultHandling, nil)
        }
    }
}

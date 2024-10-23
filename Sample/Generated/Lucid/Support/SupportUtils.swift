//
// SupportUtils.swift
//
// Generated automatically.
// Copyright © Scribd. All rights reserved.
//

import Lucid
import Combine

// MARK: - Logger

enum Logger {

    static var shared: Logging? {
        get { return LucidConfiguration.logger }
        set { LucidConfiguration.logger = newValue }
    }

    static func log(_ type: LogType,
                    _ message: @autoclosure () -> String,
                    domain: String = "Sample",
                    assert: Bool = false,
                    file: String = #file,
                    function: String = #function,
                    line: UInt = #line) {

        shared?.log(type,
                    message(),
                    domain: domain,
                    assert: assert,
                    file: file,
                    function: function,
                    line: line)
    }
}

// MARK: - LocalStoreCleanupManager

public enum LocalStoreCleanupError: Error {
    case manager(name: String, error: ManagerError)
}

public protocol LocalStoreCleanupManaging {
    func removeAllLocalData() async -> [LocalStoreCleanupError]
}

public final class LocalStoreCleanupManager: LocalStoreCleanupManaging {

    private let coreManagerProvider: CoreManagerResolver

    // MARK: Initializers

    init(coreManagerProvider: CoreManagerResolver) {
        self.coreManagerProvider = coreManagerProvider
    }

    public convenience init(coreManagers: CoreManagerContainer) {
        self.init(coreManagerProvider: coreManagers)
    }

    // MARK: API

    public func removeAllLocalData() async -> [LocalStoreCleanupError] {
        return await withTaskGroup(of: LocalStoreCleanupResult.self, returning: [LocalStoreCleanupError].self) { group in
            group.addTask {
                return await Genre.eraseLocalStore(self.coreManagerProvider.genreManager)
            }
            group.addTask {
                return await Movie.eraseLocalStore(self.coreManagerProvider.movieManager)
            }

            var errors: [LocalStoreCleanupError] = []
            for await result in group {
                switch result {
                case .success:
                    break
                case .failure(let resultErrors):
                    errors.append(contentsOf: resultErrors)
                }
            }

            return errors
        }
    }
}

enum LocalStoreCleanupResult {
    case success
    case failure([LocalStoreCleanupError])

    func merged(with result: LocalStoreCleanupResult) -> LocalStoreCleanupResult {
        switch (self, result) {
        case (.success, .failure(let error)),
             (.failure(let error), .success):
            return .failure(error)
        case (.failure(let lhsError), .failure(let rhsError)):
            return .failure(lhsError + rhsError)
        case (.success, .success):
            return .success
        }
    }
}

extension LocalEntity {

    /// Manually add the function:
    /// `static func eraseLocalStore(_ manager: CoreManaging<Self, AppAnyEntity>) -> AnyPublisher<LocalStoreCleanupResult, Never>`
    /// to an individual class adopting the Entity protocol to provide custom functionality

    static func eraseLocalStore(_ manager: CoreManaging<Self, AppAnyEntity>) async -> LocalStoreCleanupResult {
        do {
            try await manager.removeAll(withQuery: .all, in: WriteContext<Self>(dataTarget: .local))
            return .success
        } catch let error as ManagerError {
            return .failure([LocalStoreCleanupError.manager(name: "\(manager.self)", error: error)])
        } catch {
            return .failure([])
        }
    }
}

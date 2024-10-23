//
//  ImageManager.swift
//  Sample
//
//  Created by Théophane Rupin on 6/18/20.
//  Copyright © 2020 Scribd. All rights reserved.
//

import Foundation
import Lucid
import Combine
import UIKit

final class ImageManager {
    private var movieDBClient: MovieDBClient

    @Combine.Published
    private var images = [String: UIImage]()

    private let dispatchQueue = DispatchQueue(label: "\(ImageManager.self)")
    
    init(movieDBClient: MovieDBClient) {
        self.movieDBClient = movieDBClient
    }

    func image(for path: String) -> AnyPublisher<UIImage, ManagerError> {

        return $images
            .collect(1)
            .setFailureType(to: ManagerError.self)
            .receive(on: dispatchQueue)
            .flatMap { images -> AnyPublisher<UIImage, ManagerError> in
                if let image = images.first?[path] {
                    return Just(image)
                        .setFailureType(to: ManagerError.self)
                        .eraseToAnyPublisher()
                } else {
                    let config = APIRequestConfig(
                        method: .get,
                        path: .path(path),
                        host: MovieDBClient.Constants.imageAPIHost
                    )
                    return self.movieDBClient
                        .send(request: APIRequest<Data>(config))
                        .mapError { ManagerError.store(.api($0)) }
                        .receive(on: self.dispatchQueue)
                        .flatMap { response -> AnyPublisher<UIImage, ManagerError> in
                            guard let image = UIImage(data: response.data) else {
                                return Fail(error: .logicalError(description: "Could not convert data to image."))
                                    .eraseToAnyPublisher()
                            }
                            self.images[path] = image
                            return Just(image)
                                .setFailureType(to: ManagerError.self)
                                .eraseToAnyPublisher()
                        }
                        .eraseToAnyPublisher()
                }
            }.eraseToAnyPublisher()
    }
}

// MARK: - Builders

extension ImageManager {
    static func makeMovieDBClient() -> MovieDBClient {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache?.diskCapacity = 1024 * 1024 * 50
        configuration.urlCache?.memoryCapacity = 1024 * 1024 * 5
        let session = URLSession(configuration: configuration)
        return MovieDBClient(networkClient: session)
    }
}

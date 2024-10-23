//
//  SceneDelegate.swift
//  Sample
//
//  Created by Théophane Rupin on 6/12/20.
//  Copyright © 2020 Scribd. All rights reserved.
//

import UIKit
import SwiftUI

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        UITableView.appearance().allowsSelection = false
        UITableViewCell.appearance().selectionStyle = .none

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            let client = ImageManager.makeMovieDBClient()
            let manager = MovieManager(coreManagers: CoreManagerContainer(
                cacheSize: .default,
                client: client,
                diskStoreConfig: .coreData,
                responseHandler: nil
            ))
            window.rootViewController = UIHostingController(rootView: MovieList(
                controller: MovieListController(
                    movieManager: manager,
                    imageManager: ImageManager(movieDBClient: client)
                ),
                movieDetail: { detail in
                    MovieDetail(
                        controller: MovieDetailController(movieManager: manager),
                        viewModel: MovieDetailViewModel(detail.movie)
                    )
                }))
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}


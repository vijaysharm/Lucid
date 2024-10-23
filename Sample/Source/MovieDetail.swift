//
//  MovieDetails.swift
//  Sample
//
//  Created by Théophane Rupin on 6/19/20.
//  Copyright © 2020 Scribd. All rights reserved.
//

import Foundation
import Lucid
import SwiftUI
import Combine

final class MovieDetailViewModel: ObservableObject {

    @Published
    fileprivate var movieGraph: MovieGraph?

    @Published
    public var movie: Movie

    fileprivate var cancellables = Set<AnyCancellable>()

    init(_ movie: Movie) {
        self.movie = movie
        $movieGraph
            .compactMap { $0?.movie }
            .assign(to: \.movie, on: self)
            .store(in: &cancellables)
    }

    fileprivate func cancel() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}

final class MovieDetailController {
    private var movieManager: MovieManager
    
    init(movieManager: MovieManager) {
        self.movieManager = movieManager
    }

    func load(in viewModel: MovieDetailViewModel) async {
        try? await movieManager
            .movie(for: viewModel.movie.identifier)
            .replaceError(with: nil)
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .assign(to: \.movieGraph, on: viewModel)
            .store(in: &viewModel.cancellables)
    }
}

struct MovieDetail: View {
    private var controller: MovieDetailController

    @ObservedObject
    private var viewModel: MovieDetailViewModel

    init(
        controller: MovieDetailController,
        viewModel: MovieDetailViewModel
    ) {
        self.controller = controller
        self.viewModel = viewModel
    }

    var body: some View {
        HStack {
            Divider()
            VStack {
                Text(viewModel.movie.title).bold().font(.system(size: 30))
                Divider()
                HStack {
                    Text("Overview").bold()
                    Spacer()
                }.padding(4)
                Text(viewModel.movie.overview).padding(.leading, 6)
                Spacer()
                Divider()
                if viewModel.movieGraph != nil {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(self.viewModel.movieGraph!.genres, id: \.name) { genre in
                                Text(genre.name)
                                    .padding(4)
                                    .background(Color.orange)
                                    .cornerRadius(10)
                            }
                        }
                    }.padding(8)
                } else {
                    Text("...")
                }
            }
            Divider()
        }.onAppear {
            Task {
                await self.controller.load(in: self.viewModel)
            }
        }.onDisappear {
            self.viewModel.cancel()
        }
    }
}

//
//  ViewModel.swift
//  RxGithubRepoSearch
//
//  Created by Sahil Behl on 1/25/23.
//

import Foundation
import RxSwift

protocol ReactiveViewModel {
    associatedtype InputType
    associatedtype OutputType

    func transform(inputs: InputType) -> OutputType
}

class SearchViewModel: ReactiveViewModel {
    struct Input {
        let searchQueries: Observable<String>
    }

    struct Output {
        let repos: Observable<[Repo]>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
    }

    func transform(inputs: Input) -> Output {
        let api = GithubAPI()
        let searchQuery: Observable<String> = inputs
            .searchQueries
            .filter { !$0.isEmpty }
            .debounce(RxTimeInterval.milliseconds(200), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .share()

        let searchResponse: Observable<Event<ReposResponse>> = searchQuery
                    .flatMapLatest { query in
                       api.searchRepos(for: query)
                            .asObservable()
                            .observe(on: MainScheduler.instance)
                            .materialize()
                            .filter { !$0.isCompleted }
                    }
                    .share(replay: 1)

        let startedLoading: Observable<Bool> = searchQuery.map { _ in true }
        let stopedLoading: Observable<Bool> = searchResponse.map { _ in false }

        let isLoading: Observable<Bool> = Observable
            .merge(startedLoading, stopedLoading)
            .startWith(false)
            .share(replay: 1)

        let error: Observable<Error> = searchResponse
                    .map { $0.error }
                    .unwrapped()
                    .share()

        let repos: Observable<[Repo]> = searchResponse
            .map { response in
                response.element?.items ?? []
            }
            .share(replay: 1)

        return Output(repos: repos, isLoading: isLoading, error: error)
    }

}

public protocol OptionalType {
    associatedtype WrappedType
    var wrapped: WrappedType? { get }
}

extension Optional: OptionalType {
    public typealias WrappedType = Wrapped
    public var wrapped: Wrapped? {
        return self
    }
}

extension ObservableType where Element: OptionalType {
    public func unwrapped() -> Observable<Element.WrappedType> {
        return flatMap { optionalType -> Observable<Element.WrappedType> in
            if let unwrapped = optionalType.wrapped {
                return .just(unwrapped)
            } else {
                return .never()
            }
        }
    }
}

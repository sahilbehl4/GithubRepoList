//
//  GithubAPI.swift
//  RxGithubRepoSearch
//
//  Created by Sahil Behl on 1/24/23.
//

import Foundation
import RxSwift

class GithubAPI {
    private let baseURLComponents = URLComponents(string: "https://api.github.com")!

    enum NetworkError: Error {
        case networkError
        case authenticationError
        case decodeError
        case unknownError
    }

    func searchRepos(for query: String) -> Single<ReposResponse> {
        return Single.create { [weak self] subscriber in
            guard let self = self else {
                subscriber(.failure(NetworkError.unknownError))
                return Disposables.create {
                }
            }
            let request = self.makeSearchRequest(query: query)
            let task = Task {
                do {
                    let data = try await self.makeRequest(with: request)

                    let repoResponse = try JSONDecoder().decode(ReposResponse.self, from: data)
                    subscriber(.success(repoResponse))

                } catch {
                    subscriber(.failure(error))
                }
            }
            return Disposables.create {
                task.cancel()
            }
        }
    }




    private func makeSearchRequest(query: String) -> URLRequest {
        let queryString = query.components(separatedBy: .whitespacesAndNewlines).joined(separator: "+")
        var components = baseURLComponents
        components.path = "/search/repositories"
        components.queryItems = [
            URLQueryItem(name: "q", value: queryString),
            URLQueryItem(name: "sort", value: "stars")
        ]
        var request = URLRequest(url: components.url!)
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        return request
    }


    private func makeRequest(with urlRequest: URLRequest) async throws -> Data  {
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        let httpResponse = response as? HTTPURLResponse

        if httpResponse?.statusCode == 200 {
            return data
        } else if httpResponse?.statusCode == 401 {
            throw NetworkError.authenticationError
        } else {
            throw NetworkError.unknownError
        }
    }

}

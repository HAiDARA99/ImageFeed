import UIKit

enum AuthServiceError: Error {
    case invalidRequest
}

struct OAuthTokenResponseBody: Decodable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let createdAt: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case createdAt = "created_at"
    }
}

final class OAuth2Service {
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    
    func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let baseURL = URL(string: "https://unsplash.com") else { return nil }
        
        var components = URLComponents()
        components.path = "/oauth/token"
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        
        guard let url = components.url(relativeTo: baseURL) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }
    
    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        if let currentTask = task {
            if lastCode == code {
                completion(.failure(AuthServiceError.invalidRequest))
                return
            } else {
                currentTask.cancel()
            }
        } else if lastCode == code {
            completion(.failure(AuthServiceError.invalidRequest))
        }
        
        lastCode = code
        
        guard let request = makeOAuthTokenRequest(code: code) else {
            completion(.failure(AuthServiceError.invalidRequest))
            lastCode = nil
            return
        }
        
        let newTask = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                OAuth2TokenStorage.shared.token = response.accessToken
                completion(.success(response.accessToken))
            case .failure(let error):
                print("[OAuth2Service.fetchOAuthToken]: NetworkError - ошибка для кода \(code): \(error.localizedDescription)")
                completion(.failure(error))
            }
            self.task = nil
            self.lastCode = nil
        }
        
        task = newTask
        newTask.resume()
    }
}

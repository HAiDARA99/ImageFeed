import UIKit

struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?
    let profileImageURL: String
}

struct ProfileResult: Codable {
    let username: String
    let firstName: String
    let lastName: String?
    let bio: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
    }
}

final class ProfileService {
    static let shared = ProfileService()
    private let urlSession = URLSession.shared
    private(set) var profile: Profile?
    private var task: URLSessionTask?
    
    private init() {}
    
    func fetchProfile(completion: @escaping (Result<Profile, Error>) -> Void) {
        task?.cancel()
        
        guard let token = OAuth2TokenStorage.shared.token else {
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        
        guard let profileRequest = makeProfileRequest(token: token) else {
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        
        let newTask = urlSession.objectTask(for: profileRequest) { [weak self] (result: Result<ProfileResult, Error>) in
            guard let self = self else { return }
            switch result {
            case .success(let profileResult):
                let name = "\(profileResult.firstName) \(profileResult.lastName ?? "")".trimmingCharacters(in: .whitespaces)
                let profile = Profile(
                    username: profileResult.username,
                    name: name,
                    loginName: "@\(profileResult.username)",
                    bio: profileResult.bio,
                    profileImageURL: ""
                )
                self.profile = profile
                completion(.success(profile))
            case .failure(let error):
                print("[ProfileService.fetchProfile]: NetworkError - ошибка: \(error.localizedDescription)")
                completion(.failure(error))
            }
            self.task = nil
        }
        
        task = newTask
        newTask.resume()
    }
    
    private func makeProfileRequest(token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/me") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}

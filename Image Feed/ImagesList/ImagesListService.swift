import UIKit
import Kingfisher


struct Photo {
    let id: String
    let size: CGSize
    let createdAt: String?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let isLiked: Bool
}

struct PhotoResult: Codable {
    let id: String
    let createdAt: String?
    let width: Int
    let height: Int
    let description: String?
    let likedByUser: Bool
    let urls: UrlsResult
    
    enum CodingKeys: String, CodingKey {
        case id, width, height, description, urls
        case createdAt = "created_at"
        case likedByUser = "liked_by_user"
    }
}

struct UrlsResult: Codable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

final class ImagesListService {
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    static let shared = ImagesListService()
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    
    private(set) var photos: [Photo] = []
    
    private var lastLoadedPage: Int?
    private init() {}
    
    func makePhotosRequest(page: Int, perPage: Int, token: String) -> URLRequest? {
        var urlComponents = URLComponents(url: Constants.defaultBaseURL.appendingPathComponent("photos"), resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
            
        ]
        
        guard let url = urlComponents?.url else {
            print("[ImagesListService]: Ошибка - не удалось создать URL для запроса")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    func fetchPhotosNextPage() {
        guard task == nil else {
            print("[ImagesListService]: Запрос уже выполняется, новый запрос не создается")
            return
        }
        
        let nextPage = (lastLoadedPage ?? 0) + 1
        
        guard let token = OAuth2TokenStorage.shared.token else {
            print("[ImagesListService]: Ошибка - токен авторизации отсутствует")
            return
        }
        
        guard let request = makePhotosRequest(page: nextPage, perPage: 10, token: token) else {
            print("[ImagesListService]: Ошибка - не удалось создать URLRequest")
            return
        }
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let photoResults):
                let newPhoto = photoResults.map { photoResult in
                    return Photo(
                        id: photoResult.id,
                        size: CGSize(width: CGFloat(photoResult.width), height: CGFloat(photoResult.height)),
                        createdAt: photoResult.createdAt,
                        welcomeDescription: photoResult.description,
                        thumbImageURL: photoResult.urls.thumb,
                        largeImageURL: photoResult.urls.full,
                        isLiked: photoResult.likedByUser
                    )
                }
                
                DispatchQueue.main.async {
                    self.photos.append(contentsOf: newPhoto)
                    self.lastLoadedPage = nextPage
                    NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: nil)
                    
                }
                
            case .failure(let error):
                print("[ImagesListService]: Ошибка загрузки фотографий: \(error.localizedDescription)")
            }
            
            self.task = nil
        }
        
        self.task = task
        task.resume()
    }
}

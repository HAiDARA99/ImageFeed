import UIKit
import Kingfisher


struct Photo {
    let id: String
    let size: CGSize
    let createdAt: String?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    var isLiked: Bool
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

struct LikePhotoResponse: Codable {
    let photo: PhotoResult
}

final class ImagesListService {
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    static let shared = ImagesListService()
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    
    private(set) var photos: [Photo] = []
    
    private var lastLoadedPage: Int?
    private init() {}
    
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        task?.cancel()
        
        guard let token = OAuth2TokenStorage.shared.token else {
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        
        guard let url = URL(string: "https://api.unsplash.com/photos/\(photoId)/like") else {
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let newTask = urlSession.objectTask(for: request) { [weak self] (result: Result<LikePhotoResponse, Error>) in
            guard let self else { return }
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                        let photo = self.photos[index]
                        let newPhoto = Photo(
                            id: photo.id,
                            size: photo.size,
                            createdAt: photo.createdAt,
                            welcomeDescription: photo.welcomeDescription,
                            thumbImageURL: photo.thumbImageURL,
                            largeImageURL: photo.largeImageURL,
                            isLiked: response.photo.likedByUser
                        )
                        self.photos[index] = newPhoto
                    }
                    completion(.success(()))
                    NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: nil)
                }
            case .failure(let error):
                print("[ImagesListService.changeLike]: NetworkError - ошибка для photoId \(photoId): \(error.localizedDescription)")
                completion(.failure(error))
            }
            self.task = nil
        }
        
        task = newTask
        newTask.resume()
    }
    
    
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
    
    func cleanImageList() {
        photos = []
        lastLoadedPage = nil
        task?.cancel()
        task = nil
    }
}


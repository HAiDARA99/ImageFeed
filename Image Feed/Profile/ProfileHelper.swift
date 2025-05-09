import UIKit
import Kingfisher

protocol ProfileHelperProtocol: AnyObject {
    func fetchProfile() -> Profile?
    func fetchAvatarURL() -> String?
    func updateAvatar(url: String?, completion: @escaping (Result<UIImage, Error>) -> Void)
    func logout()
}

final class ProfileHelper: ProfileHelperProtocol {
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared
    
    func fetchProfile() -> Profile? {
        return profileService.profile
    }
    
    func fetchAvatarURL() -> String? {
        return profileImageService.avatarURL
    }
    
    func updateAvatar(url: String?, completion: @escaping (Result<UIImage, any Error>) -> Void) {
        guard let urlString = url,
              let imageURL = URL(string: urlString) else { return }
        
        let processor = RoundCornerImageProcessor(cornerRadius: 35.0)
        KingfisherManager.shared.retrieveImage(
            with: imageURL,
            options: [.processor(processor), .cacheOriginalImage]
        ) { result in
            switch result {
            case .success(let value):
                print("[ProfileHelper.updateAvatar]: Аватар успешно загружен")
                completion(.success(value.image))
            case .failure(let error):
                print("[ProfileHelper.updateAvatar]: Ошибка загрузки аватара: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func logout() {
        ProfileLogoutService.shared.logout()
    }
}

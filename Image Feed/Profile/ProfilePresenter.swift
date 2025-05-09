import UIKit

protocol ProfilePresenterProtocol: AnyObject {
    var view: ProfileViewControllerProtocol? { get set }
    func viewDidLoad()
    func didTapLogoutButton()
}

final class ProfilePresenter: ProfilePresenterProtocol {
    weak var view: ProfileViewControllerProtocol?
    private let profileHelper: ProfileHelperProtocol
    private var profileImageServiceObserver: NSObjectProtocol?
    
    init(profileHelper: ProfileHelperProtocol) {
        self.profileHelper = profileHelper
    }
    
    func viewDidLoad() {
        if let profile = profileHelper.fetchProfile() {
            view?.updateProfileDetails(profile: profile)
        }
        
        updateAvatar()
        
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.updateAvatar()
        }
    }
    
    func updateAvatar() {
        profileHelper.updateAvatar(url: profileHelper.fetchAvatarURL()) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let image):
                self.view?.updateAvatar(image: image)
            case .failure:
                self.view?.updateAvatar(image: UIImage(named: "userAvatar"))
            }
        }
    }
    
    func didTapLogoutButton() {
            view?.showLogoutAlert(
                title: "Пока, пока!",
                message: "Уверены, что хотите выйти?",
                confirmAction: { [weak self] in
                    guard let self else { return }
                    UIBlockingProgressHUD.show()
                    self.profileHelper.logout()
                    UIBlockingProgressHUD.dismiss()
                }
            )
        }
}


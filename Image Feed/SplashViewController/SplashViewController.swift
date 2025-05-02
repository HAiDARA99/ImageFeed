import UIKit

final class SplashViewController: UIViewController {
    private let oAuthService = OAuth2Service()
    private let storage = OAuth2TokenStorage.shared
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared
    
    private var splashLogoImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkAuthentication()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    private func setupUI() {
        view.backgroundColor = IFbackgroundColor
        
        splashLogoImageView = UIImageView()
        splashLogoImageView.image = UIImage(named: "splash_screen_logo")
        splashLogoImageView.translatesAutoresizingMaskIntoConstraints = false
        splashLogoImageView.contentMode = .scaleAspectFit
        view.addSubview(splashLogoImageView)
        
        NSLayoutConstraint.activate([
            splashLogoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            splashLogoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            splashLogoImageView.widthAnchor.constraint(equalToConstant: 74),
            splashLogoImageView.heightAnchor.constraint(equalToConstant: 74)
        ])
    }
    
    private func checkAuthentication() {
        if let token = storage.token {
            fetchProfile(token)
        } else {
            showAuthViewController()
        }
    }
    
    private func showAuthViewController() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let authViewController = AuthViewController()
            authViewController.delegate = self
            let navigationController = UINavigationController(rootViewController: authViewController)
            navigationController.modalPresentationStyle = .fullScreen
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    private func switchToTabBarController() {
        guard let window = UIApplication.shared.windows.first else {
            fatalError("Invalid Configuration")
        }
        
        let tabBarController = TabBarController()
        tabBarController.tabBar.backgroundColor = IFbackgroundColor
        tabBarController.tabBar.isTranslucent = false
        window.rootViewController = tabBarController
    }
    
    private func fetchProfile(_ token: String) {
        UIBlockingProgressHUD.show()
        profileService.fetchProfile { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self = self else { return }
            switch result {
            case .success(let profile):
                print("Профиль загружен: \(profile.username)")
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { result in
                    switch result {
                    case .success(let url):
                        print("URL аватарки получен: \(url)")
                    case .failure(let error):
                        print("Ошибка получения URL аватарки: \(error)")
                    }
                }
                self.switchToTabBarController()
            case .failure(let error):
                print("Ошибка загрузки профиля: \(error)")
                self.showAuthViewController()
            }
        }
    }
}

extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        vc.dismiss(animated: true) {
            self.switchToTabBarController()
        }
    }
    
    func authViewController(_ vc: AuthViewController, didAuthenticatedWithCode code: String) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.fetchOAuthToken(code)
        }
    }
    
    func fetchOAuthToken(_ code: String) {
        UIBlockingProgressHUD.show()
        oAuthService.fetchOAuthToken(code: code) { [weak self] result in
            DispatchQueue.main.async {
                UIBlockingProgressHUD.dismiss()
                guard let self = self else { return }
                switch result {
                case .success:
                    guard let token = self.storage.token else { return }
                    self.fetchProfile(token)
                case .failure:
                    self.showAuthViewController()
                }
            }
        }
    }
}

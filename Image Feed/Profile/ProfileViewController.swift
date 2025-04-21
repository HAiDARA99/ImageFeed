import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {
    private var avatarImageView: UIImageView!
    private var nameLabel: UILabel!
    private var loginNameLabel: UILabel!
    private var descriptionLabel: UILabel!
    private var logoutButton: UIButton!
    
    private var profileImageServiceObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = IFbackgroundColor
        
        setupProfileImage()
        setupNameLabel()
        setupLoginNameLabel()
        setupDescriptionLabel()
        setupLogoutButton()
        
        profileImageServiceObserver = NotificationCenter.default
            .addObserver(
                forName: ProfileImageService.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                self.updateAvatar()
            }
        
        updateAvatar()
        
        if let profile = ProfileService.shared.profile {
            updateProfileDetails(profile: profile)
        }
    }
    
    private func updateAvatar() {
        guard
            let profileImageURL = ProfileImageService.shared.avatarURL,
            let url = URL(string: profileImageURL)
        else {
            avatarImageView.image = UIImage(named: "userAvatar")
            return
        }
        
        let processor = RoundCornerImageProcessor(cornerRadius: 35.0)
        avatarImageView.kf.setImage(
            with: url,
            placeholder: UIImage(named: "userAvatar"),
            options: [.processor(processor),
                      .cacheOriginalImage],
            completionHandler: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    print("[ProfileViewController.updateAvatar]: Аватарка успешно загружена")
                case .failure(let error):
                    print("[ProfileViewController.updateAvatar]: Ошибка загрузки аватарки: \(error.localizedDescription)")
                    self.avatarImageView.image = UIImage(named: "userAvatar")
                }
            }
        )
    }
    
    private func setupProfileImage() {
        let profileImage = UIImage(named: "userAvatar")
        let avatarImageView = UIImageView(image: profileImage)
        avatarImageView.contentMode = .scaleAspectFit
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 35
        avatarImageView.layer.masksToBounds = true
        
        self.avatarImageView = avatarImageView
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(avatarImageView)
        
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            avatarImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 70),
            avatarImageView.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    private func setupNameLabel() {
        let nameLabel = UILabel()
        nameLabel.text = ""
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 23, weight: .semibold)
        nameLabel.textColor = .white
        view.addSubview(nameLabel)
        self.nameLabel = nameLabel
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 16)
        ])
    }
    
    private func setupLoginNameLabel() {
        let loginNameLabel = UILabel()
        loginNameLabel.text = ""
        loginNameLabel.translatesAutoresizingMaskIntoConstraints = false
        loginNameLabel.font = .systemFont(ofSize: 13)
        loginNameLabel.textColor = .gray
        view.addSubview(loginNameLabel)
        self.loginNameLabel = loginNameLabel
        
        NSLayoutConstraint.activate([
            loginNameLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            loginNameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8)
        ])
    }
    
    private func setupDescriptionLabel() {
        let descriptionLabel = UILabel()
        descriptionLabel.text = ""
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = .systemFont(ofSize: 13)
        descriptionLabel.textColor = .white
        view.addSubview(descriptionLabel)
        self.descriptionLabel = descriptionLabel
        
        NSLayoutConstraint.activate([
            descriptionLabel.trailingAnchor.constraint(equalTo: loginNameLabel.trailingAnchor),
            descriptionLabel.leadingAnchor.constraint(equalTo: loginNameLabel.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8)
        ])
    }
    
    private func setupLogoutButton() {
        let logoutButton = UIButton(type: .custom)
        logoutButton.setImage(UIImage(named: "logout_button"), for: .normal)
        logoutButton.addTarget(self, action: #selector(didTapLogoutButton), for: .touchUpInside)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoutButton)
        self.logoutButton = logoutButton
        
        NSLayoutConstraint.activate([
            logoutButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: logoutButton.trailingAnchor, constant: 16)
        ])
    }
    
    private func updateProfileDetails(profile: Profile) {
        loginNameLabel.text = profile.loginName
        nameLabel.text = profile.name
        descriptionLabel.text = profile.bio ?? ""
    }
    
    @objc private func didTapLogoutButton() {
        print("Кнопка 'Выйти' нажата!")
    }
}

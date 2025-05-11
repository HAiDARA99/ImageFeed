import UIKit
import ProgressHUD

protocol AuthViewControllerDelegate: AnyObject {
    func authViewController(_ vc: AuthViewController, didAuthenticatedWithCode code: String)
    func didAuthenticate(_ vc: AuthViewController)
}

final class AuthViewController: UIViewController {
    private let oauthService = OAuth2Service()
    weak var delegate: AuthViewControllerDelegate?
    
    private let logoImageView = {
        let logoImageView = UIImageView()
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.image = UIImage(named: "auth_screen_logo")
        logoImageView.contentMode = .scaleAspectFit
        return logoImageView
    }()
    
    private let entryButton = {
        let entryButton = UIButton()
        entryButton.translatesAutoresizingMaskIntoConstraints = false
        entryButton.setTitle("Войти", for: .normal)
        entryButton.setTitleColor(IFbackgroundColor, for: .normal)
        entryButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        entryButton.contentMode = .scaleToFill
        entryButton.backgroundColor = .white
        entryButton.layer.cornerRadius = 16
        entryButton.layer.masksToBounds = true
        entryButton.accessibilityIdentifier = "Authenticate"
        return entryButton
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureBackButton()
    }
    
    private func setupUI() {
        view.backgroundColor = IFbackgroundColor
        
        view.addSubview(logoImageView)
        view.addSubview(entryButton)
        
        entryButton.addTarget(self, action: #selector(didTapLoginButton), for: .touchUpInside)
        NSLayoutConstraint.activate([
            logoImageView.widthAnchor.constraint(equalToConstant: 60),
            logoImageView.heightAnchor.constraint(equalToConstant: 60),
            logoImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            
            entryButton.heightAnchor.constraint(equalToConstant: 48),
            entryButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            entryButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            entryButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            entryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -124)
        ])
    }
    
    private func configureBackButton() {
        navigationController?.navigationBar.backIndicatorImage = UIImage(named: "nav_back_button")
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav_back_button")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
    }
    
    private func showErrorAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось войти в систему",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func didTapLoginButton() {
        let webViewViewController = WebViewViewController()
        let authHelper = AuthHelper()
        let webViewPresenter = WebViewPresenter(authHelper: authHelper)
        webViewViewController.presenter = webViewPresenter
        webViewPresenter.view = webViewViewController
        webViewViewController.delegate = self
        navigationController?.pushViewController(webViewViewController, animated: true)
    }
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        navigationController?.popViewController(animated: true)
        UIBlockingProgressHUD.show()
        
        oauthService.fetchOAuthToken(code: code) { [weak self] result in
            guard let self else { return }
            UIBlockingProgressHUD.dismiss()
            switch result {
            case .success:
                delegate?.didAuthenticate(self)
            case .failure:
                showErrorAlert()
            }
        }
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        navigationController?.popViewController(animated: true)
    }
}

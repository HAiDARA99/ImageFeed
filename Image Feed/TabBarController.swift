import UIKit

final class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        applyTabBarAppearance()
    }
    
    //    override func viewWillAppear(_ animated: Bool) {
    //        super.viewWillAppear(animated)
    //        applyTabBarAppearance()
    //    }
    //
    //    override func viewDidLayoutSubviews() {
    //        super.viewDidLayoutSubviews()
    //        applyTabBarAppearance()
    //    }
    
    private func setupTabBar() {
        let imageListPresenter = ImagesListPresenter()
        let imagesListViewController = ImagesListViewController()
        imagesListViewController.presenter = imageListPresenter
        imageListPresenter.view = imagesListViewController
        
        let profileHelper = ProfileHelper()
        let presenter = ProfilePresenter(profileHelper: profileHelper)
        let profileViewController = ProfileViewController()
        profileViewController.presenter = presenter
        presenter.view = profileViewController
        
        imagesListViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_editorial_active"),
            selectedImage: nil
        )
        
        profileViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_profile_active"),
            selectedImage: nil
        )
        
        self.viewControllers = [imagesListViewController, profileViewController]
    }
    
    private func applyTabBarAppearance() {
        tabBar.isTranslucent = false
        tabBar.backgroundColor = IFbackgroundColor
        tabBar.tintColor = .white
        tabBar.unselectedItemTintColor = .gray
        
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = IFbackgroundColor
        
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        } else {
            print("zalupa")
        }
    }
}

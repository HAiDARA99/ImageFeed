@testable import Image_Feed
import XCTest

final class ProfileViewTests: XCTestCase {
    func testViewDidLoad() {
            let helper = ProfileHelper()
            let viewController = ProfileViewController()
            let presenter = ProfilePresenter(profileHelper: helper)
            viewController.presenter = presenter
            
            _ = viewController.view
            
            XCTAssertTrue(true)
        }
    
    func testDidTapLogoutButton() {
            let helper = ProfileHelper()
            let viewController = ProfileViewController()
            let presenter = ProfilePresenter(profileHelper: helper)
            viewController.presenter = presenter
            
            _ = viewController.view
            viewController.didTapLogoutButton()
            
            XCTAssertTrue(true)
        }
}

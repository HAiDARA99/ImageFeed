@testable import Image_Feed
import XCTest

final class ImageListViewTests: XCTestCase {
    private class TestView: ImageListViewControllerProtocol {
            var oldCount: Int?
            var newCount: Int?
            
            func updateTableViewAnimated(oldCount: Int, newCount: Int) {
                self.oldCount = oldCount
                self.newCount = newCount
            }
        }
        
        func testUpdateTableViewAnimated() {
            let presenter = ImagesListPresenter()
            let testView = TestView()
            presenter.view = testView
            
            presenter.updateTableViewAnimated()
            
            XCTAssertNotNil(testView.oldCount)
            XCTAssertNotNil(testView.newCount)
        }
    
    func testViewDidLoadWithViewController() {
            let viewController = ImagesListViewController()
            let presenter = ImagesListPresenter()
            viewController.presenter = presenter
            
            _ = viewController.view
            
            XCTAssertTrue(true)
        }
}

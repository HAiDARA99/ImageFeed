@testable import Image_Feed
import XCTest

final class Image_FeedUITests: XCTestCase {
    private let app = XCUIApplication() // переменная приложения
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app.launch() // запускаем приложение перед каждым тестом
    }
    
    func testAuth() throws {
        app.buttons["Authenticate"].tap()
        
        let webView = app.webViews["UnsplashWebView"]
        
        XCTAssert(webView.waitForExistence(timeout: 5))
        
        let loginTextField = webView.descendants(matching: .textField).element
        XCTAssertTrue(loginTextField.waitForExistence(timeout: 5))
        
        loginTextField.tap()
        loginTextField.typeText("smaggy@mail.ru")
        XCUIApplication().toolbars.buttons["Done"].tap()
        
        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssert(passwordTextField.waitForExistence(timeout: 5))
        
        passwordTextField.tap()
        passwordTextField.typeText("splash-pass-52")
        XCUIApplication().toolbars.buttons["Done"].tap()
        
        webView.buttons["Login"].tap()
        
        let tableQuery = app.tables
        let cell = tableQuery.children(matching: .cell).element(boundBy: 0)
        
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
    }
    
    func testFeed() throws {
        let tableQuery = app.tables
        
        let cell = tableQuery.children(matching: .cell).element(boundBy: 0)
        cell.swipeUp()
        
        sleep(2)    
        
        let cellToLike = tableQuery.children(matching: .cell).element(boundBy: 1)
        
        cellToLike.buttons["like button"].tap()
        cellToLike.buttons["like button"].tap()
        
        sleep(2)
        
        cellToLike.tap()
        
        sleep(2)
        
        let image = app.scrollViews.images.element(boundBy: 0)
        
        image.pinch(withScale: 3, velocity: 1)
        image.pinch(withScale: 0.5, velocity: -1)
        
        let navButtonBack = app.buttons["nav back button"]
        navButtonBack.tap()
    }
    
    func testProfile() throws {
        sleep(2)
        
        app.tabBars.buttons["profileTab"].tap()
        
        XCTAssert(app.staticTexts["Rail Ismagov"].exists)
        XCTAssert(app.staticTexts["@purplejunng"].exists)
        
        app.buttons["logout button"].tap()
        
//        app.alerts["Alert"].scrollViews.otherElements.buttons["Yes"].tap()
//        app.alerts["Alert"].buttons["Yes"]
        app.alerts["Выйти?"].buttons["Да"].tap()
    }
    
}

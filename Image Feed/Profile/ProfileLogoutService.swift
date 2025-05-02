import Foundation
import WebKit
import Kingfisher

final class ProfileLogoutService {
    static let shared = ProfileLogoutService()
    
    private init() { }
    
    func logout() {
        OAuth2TokenStorage.shared.token = nil
        cleanCookies()
        resetServiceData()
        switchToSplashScreen()
    }
    
    private func cleanCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
    
    private func resetServiceData() {
        ProfileImageService.shared.cleanProfileImage()
        ProfileService.shared.cleanProfile()
        ImagesListService.shared.cleanImageList()
        
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache()
    }
    
    private func switchToSplashScreen() {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.windows.first else {
                fatalError("Invalid window configuration")
            }
            
            let splashVC = SplashViewController()
            window.rootViewController = splashVC
        }
    }
}


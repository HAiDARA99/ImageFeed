import UIKit

enum Constants {
    static let accessKey = "cvNi-HxZRTqF7KwhVTra-6sOpci2hXkOi9HQlsHUOmA"
    static let secretKey = "MMgeAZc7gHZrQUtFarAVHGgAc9tRr8K1PlPql2IfFsw"
    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope = "public+read_user+write_likes"
    
    static let defaultBaseURL = URL(string: "https://api.unsplash.com")!
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
}

struct AuthConfiguration {
    let accessKey: String
    let secretKey: String
    let redirectURI: String
    let accessScope: String
    let defaultBaseURL: URL
    let authURLString: String
    
    init(accessKey: String, secretKey: String, redirectURI: String, accessScope: String, defaultBaseURL: URL, authURLString: String) {
        self.accessKey = accessKey
        self.secretKey = secretKey
        self.redirectURI = redirectURI
        self.accessScope = accessScope
        self.defaultBaseURL = defaultBaseURL
        self.authURLString = authURLString
    }
    
    static var standart: AuthConfiguration {
        return AuthConfiguration(accessKey: Constants.accessKey,
                                 secretKey: Constants.secretKey,
                                 redirectURI: Constants.redirectURI,
                                 accessScope: Constants.accessScope,
                                 defaultBaseURL: Constants.defaultBaseURL,
                                 authURLString: Constants.unsplashAuthorizeURLString)
    }
}

let IFbackgroundColor: UIColor = {
    let red = CGFloat(0x1A) / 255.0
    let green = CGFloat(0x1B) / 255.0
    let blue = CGFloat(0x22) / 255.0
    return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
}()

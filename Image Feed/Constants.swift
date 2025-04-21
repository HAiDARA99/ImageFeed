import UIKit

enum Constants {
    static let accessKey = "cvNi-HxZRTqF7KwhVTra-6sOpci2hXkOi9HQlsHUOmA"
    static let secretKey = "MMgeAZc7gHZrQUtFarAVHGgAc9tRr8K1PlPql2IfFsw"
    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope = "public+read_user+write_likes"
    static let defaultBaseURL = URL(string: "https://api.unsplash.com")!
}

let IFbackgroundColor: UIColor = {
    let red = CGFloat(0x1A) / 255.0
    let green = CGFloat(0x1B) / 255.0
    let blue = CGFloat(0x22) / 255.0
    return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
}()

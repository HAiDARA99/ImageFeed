import UIKit

protocol ImagesListPresenterProtocol: AnyObject {
    var view: ImageListViewControllerProtocol? { get set }
    func viewDidLoad()
}

final class ImagesListPresenter: ImagesListPresenterProtocol {
    weak var view: ImageListViewControllerProtocol?
    private let imageListService = ImagesListService.shared
    private var notificationObserver: NSObjectProtocol?
    private var photos: [Photo] = []
    
    func viewDidLoad() {
        setupObservers()
    }
    
    private func setupObservers() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.updateTableViewAnimated()
            UIBlockingProgressHUD.dismiss()
        }
    }
    
    func updateTableViewAnimated() {
        let oldCount = photos.count
        photos = imageListService.photos
        let newCount = photos.count
        view?.updateTableViewAnimated(oldCount: oldCount, newCount: newCount)
    }
}

import UIKit
import Kingfisher

final class ImagesListViewController: UIViewController {
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    
    @IBOutlet private var tableView: UITableView!
    
    //    private let photosName = Array(0..<20).map { $0.description }
    private let imageListService = ImagesListService.shared
    private var notificationObserver: NSObjectProtocol?
    
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        
        notificationObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main,
        ) { [weak self] _ in
            guard let self = self else { return }
            self.tableView.reloadData()
        }
        
        imageListService.fetchPhotosNextPage()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let viewController = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else {
                assertionFailure("Invalid segue destination")
                return
            }
            
            let photo = imageListService.photos[indexPath.row]
            guard let url = URL(string: photo.largeImageURL) else {
                assertionFailure("Invalid Image")
                return
            }
            
            viewController.imageURL = url
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageListService.photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        
        configCell(for: imageListCell, with: indexPath)
        
        return imageListCell
    }
}

extension ImagesListViewController {
    func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        let image = imageListService.photos[indexPath.row]
        
        guard let url = URL(string: image.thumbImageURL) else {
            cell.cellImage.image = UIImage(named: "placeholder")
            return
        }
        
        cell.cellImage.kf.setImage(
            with: url,
            placeholder: UIImage(named: "userAvatar"),
            options: [.cacheOriginalImage]
        ) { result in
            switch result {
            case .success:
                print("[ImagesListViewController]: Изображение успешно загружено для indexPath: \(indexPath)")
            case .failure(let error):
                print("[ImagesListViewController]: Ошибка загрузки изображения: \(error.localizedDescription)")
            }
        }
        
        if let createdAtString = image.createdAt {
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: createdAtString) {
                cell.dateLabel.text = self.dateFormatter.string(from: date)
            } else {
                cell.dateLabel.text = "Дата неизвестна"
            }
        } else {
            cell.dateLabel.text = "Дата неизвестна"
        }
        
        // Настройка лайка
        let likeImage = image.isLiked ? UIImage(resource: .likeButtonOn) : UIImage(resource: .likeButtonOff)
        cell.likeButton.setImage(likeImage, for: .normal)
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = imageListService.photos[indexPath.row]
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let imageWidth = photo.size.width
        let scale = imageViewWidth / imageWidth
        let cellHeight = photo.size.height * scale + imageInsets.top + imageInsets.bottom
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == imageListService.photos.count {
            imageListService.fetchPhotosNextPage()
        }
    }
}

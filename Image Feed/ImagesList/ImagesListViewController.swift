import UIKit
import Kingfisher

final class ImagesListViewController: UIViewController {
    private let imageListService = ImagesListService.shared
    private var notificationObserver: NSObjectProtocol?
    private var photos: [Photo] = []
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
    
    private let tableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = IFbackgroundColor
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.register(ImagesListCell.self, forCellReuseIdentifier: ImagesListCell.reuseIdentifier)
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupObservers()
        imageListService.fetchPhotosNextPage()
    }
    
    private func setupUI() {
        view.backgroundColor = IFbackgroundColor
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
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
    
    private func updateTableViewAnimated() {
        let oldCount = photos.count
        let newCount = imageListService.photos.count
        
        photos = imageListService.photos
        
        tableView.performBatchUpdates() {
            let indexPaths = (oldCount..<newCount).map {
                IndexPath(row: $0, section: 0)
            }
            tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageListService.photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        ) as? ImagesListCell else {
            return UITableViewCell()
        }
        
        configCell(for: cell, with: indexPath)
        return cell
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
            placeholder: UIImage(named: "placeholder"),
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
        
        let likeImage = image.isLiked ? UIImage(resource: .likeButtonOn) : UIImage(resource: .likeButtonOff)
        cell.likeButton.setImage(likeImage, for: .normal)
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let singleImageVC = SingleImageViewController()
        let photo = imageListService.photos[indexPath.row]
        guard let url = URL(string: photo.largeImageURL) else {
            print("Invalid ImageURL")
            return
        }
        singleImageVC.imageURL = url
        
        present(singleImageVC, animated: true, completion: nil)
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

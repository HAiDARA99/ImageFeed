import UIKit
import Kingfisher

protocol ImageListViewControllerProtocol: AnyObject {
    func updateTableViewAnimated(oldCount: Int, newCount: Int)
}

final class ImagesListViewController: UIViewController, ImageListViewControllerProtocol {
    private let imageListService = ImagesListService.shared
    var presenter: ImagesListPresenterProtocol?
    
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
        presenter?.viewDidLoad()
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
    
    func updateTableViewAnimated(oldCount: Int, newCount: Int) {
            if oldCount == newCount {
                tableView.reloadData()
                return
            }
            tableView.performBatchUpdates {
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
        
        cell.delegate = self
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
        
        cell.cellImage.kf.indicatorType = .activity
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
        
        cell.setIsLiked(image.isLiked)
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

extension ImagesListViewController: ImageListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = imageListService.photos[indexPath.row]
        
        UIBlockingProgressHUD.show()
        
        imageListService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                UIBlockingProgressHUD.dismiss()
                switch result {
                case .success:
                    cell.setIsLiked(self.imageListService.photos[indexPath.row].isLiked)
                case .failure(let error):
                    print("[ImagesListViewController.imageListCellDidTapLike]: Ошибка изменения лайка: \(error.localizedDescription)")
                    let alert = UIAlertController(
                        title: "Ошибка",
                        message: "Не удалось поставить лайк( Попробуйте снова.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}

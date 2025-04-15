import UIKit

final class DetailScreenViewController: UIViewController {
    // MARK: - properties
    private let presenter: IDetailScreenPresenter
    
    private let photoImageView: UIImageView = {
        let item = UIImageView()
        item.translatesAutoresizingMaskIntoConstraints = false
        item.contentMode = .scaleAspectFit
        return item
    }()
    private let authorLabel: UILabel = {
        let item = UILabel()
        item.translatesAutoresizingMaskIntoConstraints = false
        item.textColor = Asset.textColor.color
        item.font = UIFont.boldSystemFont(ofSize: 17)
        return item
    }()
    private let dateLabel: UILabel = {
        let item = UILabel()
        item.translatesAutoresizingMaskIntoConstraints = false
        item.textColor = Asset.textColor.color
        item.font = UIFont.systemFont(ofSize: 15)
        return item
    }()
    private let numberOfDownloadsLabel: UILabel = {
        let item = UILabel()
        item.translatesAutoresizingMaskIntoConstraints = false
        item.textColor = Asset.accentColor.color
        item.font = UIFont.systemFont(ofSize: 15)
        return item
    }()
    private let addressLabel: UILabel = {
        let item = UILabel()
        item.translatesAutoresizingMaskIntoConstraints = false
        item.textColor = Asset.textColor.color
        item.font = UIFont.systemFont(ofSize: 14)
        return item
    }()
    private let labelsStackView: UIStackView = {
        let item = UIStackView()
        item.translatesAutoresizingMaskIntoConstraints = false
        item.alignment = .leading
        item.axis = .vertical
        item.distribution = .fillProportionally
        item.spacing = Spacing.standar / 2
        return item
    }()
    // MARK: - lifecycle
    init(presenter: IDetailScreenPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviews()
        createConstraints()
        view.backgroundColor = Asset.backgroundColor.color
        presenter.viewDidLoad(self)
        tuneNavItem()
        presenter.fetchDetailInformation()
    }
}
// MARK: - view output
extension DetailScreenViewController: IDetailScreenView {
    func performAnimation() {
        let heartImageView = UIImageView(image: UIImage(systemName: "heart.fill"))
        heartImageView.tintColor = Asset.accentColor.color
        heartImageView.contentMode = .scaleAspectFit
        heartImageView.alpha = 0.8
        
        let heartSize: CGFloat = 100
        heartImageView.frame = CGRect(x: 0, y: 0, width: heartSize, height: heartSize)
        heartImageView.center = view.center
        
        view.addSubview(heartImageView)
        
        UIView.animateKeyframes(withDuration: 0.6, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.3) {
                heartImageView.transform = CGAffineTransform(scaleX: 1.8, y: 1.8)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.3) {
                heartImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
        }) { _ in
            UIView.animate(withDuration: 0.3, animations: {
                heartImageView.alpha = 0
            }) { _ in
                heartImageView.removeFromSuperview()
            }
        }
    }
    
    func showErrorAlert(_ error: any Error) {
        let alertController = ModuleBuilder.createAlertController(with: error)
        DispatchQueue.main.async {
            self.navigationController?.present(alertController, animated: true)
        }
    }
    
    func popController() {
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func updateData(_ model: DetailScreenModel) {
        let url = URL(string: model.url ?? "")
        authorLabel.text = "\(model.authorName)" + " \(model.authorSurname)"
        numberOfDownloadsLabel.attributedText = createAttributesString(model: model)
        dateLabel.text = convertData(model.creationDate)
        addressLabel.text = "\(model.location.city ?? "") \(model.location.city ?? "")"
        if let coredataImage = model.image {
            photoImageView.image = coredataImage
        } else {
            photoImageView.kf.indicatorType = .activity
            photoImageView.kf.setImage(with: url) { [weak self] result in
                switch result {
                case .success(let retrivedImage):
                    DispatchQueue.main.async {
                        self?.photoImageView.image = retrivedImage.image
                    }
                case .failure(let kfError):
                    let alertController = ModuleBuilder.createAlertController(with: kfError)
                    DispatchQueue.main.async {
                        self?.present(alertController, animated: true)
                    }
                }
            }
        }
    }
}
// MARK: - private funcs
private extension DetailScreenViewController {
    @objc func addToFavorites() {
        guard let image = photoImageView.image else { return }
        if let title = navigationItem.rightBarButtonItem?.title {
            if title.contains("Add") {
                presenter.addToFavourites(image: image)
            } else {
                presenter.removeFromFavourites()
            }
        }
    }
    
    func tuneNavItem() {
        var title = "Add to favourite"
        if presenter.isModelInfavourite() {
            title = "Remove from favourite"
        }
        let rightBarButton = UIBarButtonItem(title: title, style: .done, target: self, action: #selector(addToFavorites))
        navigationItem.rightBarButtonItem = rightBarButton
    }
    
    func convertData(_ date: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        inputFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let dateString = inputFormatter.date(from: date) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "MMM d, yyyy"
            outputFormatter.locale = Locale.current
            return outputFormatter.string(from: dateString)
        } else {
            return "Invalid date"
        }
    }
    func createAttributesString(model: DetailScreenModel) -> NSAttributedString {
        let baseText = "Downloads: "
        let downloadsText = String(model.downloads)
        let attributedBaseString = NSMutableAttributedString(
            string: baseText,
            attributes: [.foregroundColor : UIColor.black]
        )
        let downloadsAttributedString = NSMutableAttributedString(
            string: downloadsText,
            attributes: [.foregroundColor : Asset.accentColor.color]
        )
        attributedBaseString.append(downloadsAttributedString)
        return attributedBaseString
    }
}
// MARK: - layout
extension DetailScreenViewController {
    func addSubviews() {
        view.addSubview(photoImageView)
        view.addSubview(labelsStackView)
        labelsStackView.addArrangedSubview(authorLabel)
        labelsStackView.addArrangedSubview(dateLabel)
        labelsStackView.addArrangedSubview(numberOfDownloadsLabel)
        labelsStackView.addArrangedSubview(addressLabel)
    }
    
    func createConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate(
            createConstraintsForImageView(safeArea) +
            createConstraintsForLabelsStackView(safeArea)
        )
    }
    
    func createConstraintsForImageView(_ safeArea: UILayoutGuide) -> [NSLayoutConstraint] {
        let heightAspect: CGFloat = (Constants.imageWidth / (UIScreen.main.bounds.width - Spacing.standar))
        return [
            photoImageView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            photoImageView.heightAnchor.constraint(equalTo: photoImageView.widthAnchor, multiplier: heightAspect),
            photoImageView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor)
        ]
    }
    
    func createConstraintsForLabelsStackView(_ safeArea: UILayoutGuide) -> [NSLayoutConstraint] {
        [
            labelsStackView.topAnchor.constraint(equalTo: photoImageView.bottomAnchor, constant: Spacing.standar / 2),
            labelsStackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: Spacing.standar),
            labelsStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -Spacing.standar),
            labelsStackView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ]
    }
}
// MARK: - constants
private extension DetailScreenViewController {
    enum Constants {
        static let imageWidth: CGFloat = 400
    }
}

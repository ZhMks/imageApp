import UIKit
import Kingfisher

final class MainCollectionCell: UICollectionViewCell {
    // MARK: - properties
    static let identifier = "MainCollectionCell"
    
    private let photoImageView: UIImageView = {
        let item = UIImageView()
        item.translatesAutoresizingMaskIntoConstraints = false
        item.layer.cornerRadius = Constants.cornerRadius
        item.clipsToBounds = true
        item.contentMode = .scaleAspectFill
        return item
    }()
    private let wrapperView: UIView = {
        let item = UIView()
        item.translatesAutoresizingMaskIntoConstraints = false
        return item
    }()
    // MARK: - lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews()
        createConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // MARK: - funcs
    func updateCell(model: MainScreenModel) {
        let url = URL(string: model.links.raw)
        photoImageView.kf.indicatorType = .activity
        photoImageView.kf.setImage(
            with: url,
            options: [
                .transition(.fade(0.1))
            ]
        ) { [weak self] result in
            switch result {
            case .success(let retrivedImage):
                DispatchQueue.main.async {
                    self?.photoImageView.image = retrivedImage.image
                }
                ImageCache.default.clearCache()
            case .failure(let kfError):
                print(kfError.localizedDescription)
            }
        }
    }
}
// MARK: - private funcs
private extension MainCollectionCell {
    func addSubviews() {
        contentView.addSubview(wrapperView)
        wrapperView.addSubview(photoImageView)
    }
    func createConstraints() {
        let safeArea = contentView.safeAreaLayoutGuide
        NSLayoutConstraint.activate(
            createConstraintsForWrapperView(safeArea) +
            createConstraintsForImageView()
        )
    }
    func createConstraintsForImageView() -> [NSLayoutConstraint] {
        let heightAspect: CGFloat = (Constants.imageWidth / (UIScreen.main.bounds.width - Spacing.standar * 2))
        return [
            photoImageView.topAnchor.constraint(equalTo: wrapperView.topAnchor),
            photoImageView.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor),
            photoImageView.heightAnchor.constraint(equalTo: photoImageView.widthAnchor, multiplier: heightAspect),
            photoImageView.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor)
        ]
    }
    func createConstraintsForWrapperView(_ safeArea: UILayoutGuide) -> [NSLayoutConstraint] {
        let widthConstraint = wrapperView.widthAnchor
            .constraint(
                equalToConstant: UIScreen.main.bounds.width - Spacing.standar
            )
        widthConstraint.priority = UILayoutPriority(rawValue: 999)
        let heightConstraint = wrapperView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        heightConstraint.priority = UILayoutPriority(rawValue: 999)
        return  [
            wrapperView.topAnchor
                .constraint(
                    equalTo: contentView.topAnchor
                ),
            widthConstraint,
            wrapperView.leftAnchor
                .constraint(
                    equalTo: safeArea.leftAnchor
                ),
            wrapperView.rightAnchor
                .constraint(
                    equalTo: safeArea.rightAnchor
                ),
            heightConstraint
        ]
    }
}
// MARK: - constants
private extension MainCollectionCell {
    enum Constants {
        static let imageHeight: CGFloat = 200.0
        static let imageWidth: CGFloat = 200.0
        static let cornerRadius: CGFloat = 10.0
    }
}

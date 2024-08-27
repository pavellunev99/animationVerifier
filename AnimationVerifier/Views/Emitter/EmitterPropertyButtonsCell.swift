import Foundation
import INCR_UIExtensions

protocol EmitterPropertyButtonsCellDelegate: AnyObject {
    func colorSelectorDidTapped()
    func imageSelectorDidTapped()
}

final class EmitterPropertyButtonsCellItem: TableViewCellItem {
    
    let color: UIColor
    let image: UIImage?
    
    init(color: UIColor, image: UIImage?) {
        self.color = color
        self.image = image
        super.init(reuseIdentifier: "EmitterPropertyButtonsCell", cellType: EmitterPropertyButtonsCell.self)
    }
}

final class EmitterPropertyButtonsCell: TableViewCell {
    
    weak var delegate: EmitterPropertyButtonsCellDelegate?
    
    override var item: TableViewCellItem? {
        didSet {
            if let _item = self.item as? EmitterPropertyButtonsCellItem {
                colorView.backgroundColor = _item.color
                iconImageView.image = _item.image
            }
        }
    }
    
    let stackView = UIStackView()
    
    let colorButton = View()
    let colorLabel = UILabel()
    let colorView = UIView()
    
    let iconButton = View()
    let iconLabel = UILabel()
    let iconImageView = UIImageView()
    
    override func setup() {
        contentView.addSubview(stackView)
        stackView.axis = .horizontal
        stackView.spacing = 10
        
        stackView.addArrangedSubview(colorButton)
        colorButton.addTarget(self, action: #selector(tapColor), for: .touchUpInside)
        
        colorButton.addSubview(colorLabel)
        colorLabel.font = .boldSystemFont(ofSize: 12)
        colorLabel.textColor = .lightGray
        colorLabel.text = "BG"
        
        colorButton.addSubview(colorView)
        colorView.layer.borderColor = UIColor.black.cgColor
        colorView.layer.borderWidth = 1
        colorView.isUserInteractionEnabled = false
        
        colorButton.addSubview(colorView)
        
        stackView.addArrangedSubview(iconButton)
        iconButton.addTarget(self, action: #selector(tapIcon), for: .touchUpInside)
        
        iconButton.addSubview(iconLabel)
        iconLabel.font = .boldSystemFont(ofSize: 12)
        iconLabel.textColor = .lightGray
        iconLabel.text = "IMAGE"
        
        iconButton.addSubview(iconImageView)
        iconImageView.layer.borderColor = UIColor.black.cgColor
        iconImageView.layer.borderWidth = 1
        iconImageView.isUserInteractionEnabled = false
        iconImageView.contentMode = .scaleAspectFit
    }
    
    override func setupSizes() {
        stackView.autoPinEdgesToSuperviewEdges(with: .init(top: 4, left: 12, bottom: 4, right: 12), excludingEdge: .left)
        
        colorLabel.autoAlignAxis(toSuperviewAxis: .horizontal)
        colorLabel.autoPinEdge(toSuperviewEdge: .left)
        
        colorView.autoPinEdge(.left, to: .right, of: colorLabel, withOffset: 12)
        colorView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .left)
        colorView.autoSetDimensions(to: .init(width: 24, height: 24))
        
        iconLabel.autoAlignAxis(toSuperviewAxis: .horizontal)
        iconLabel.autoPinEdge(toSuperviewEdge: .left)
        
        iconImageView.autoPinEdge(.left, to: .right, of: iconLabel, withOffset: 12)
        iconImageView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .left)
        iconImageView.autoSetDimensions(to: .init(width: 24, height: 24))
    }
    
    @objc
    func tapColor() {
        delegate?.colorSelectorDidTapped()
    }
    
    @objc
    func tapIcon() {
        delegate?.imageSelectorDidTapped()
    }
}

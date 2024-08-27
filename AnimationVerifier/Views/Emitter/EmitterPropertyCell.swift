import Foundation
import INCR_UIExtensions

protocol EmitterPropertyCellDelegate: AnyObject {
    func emitterPropertyDidChanged(property: EmitterProperty, newValue: Float)
}

final class EmitterPropertyCellItem: TableViewCellItem {
    
    let property: EmitterProperty
    let values: (initial: Float, min: Float, max: Float)
    
    init(property: EmitterProperty, values: (initial: Float, min: Float, max: Float)) {
        self.property = property
        self.values = values
        super.init(reuseIdentifier: "EmitterPropertyCell", cellType: EmitterPropertyCell.self)
    }
}

final class EmitterPropertyCell: TableViewCell {
    
    weak var delegate: EmitterPropertyCellDelegate?
    
    let titleLabel = UILabel()
    let valueLabel = UILabel()
    let slider = UISlider()
    
    override var item: TableViewCellItem? {
        didSet {
            if let _item = self.item as? EmitterPropertyCellItem {
                switch _item.property {
                case .birthRate:
                    titleLabel.text = "Количество частиц в секунду (birthRate)"
                case .lifetime:
                    titleLabel.text = "Время жизни частиц (lifetime)"
                case .velocity:
                    titleLabel.text = "Скорость частиц (velocity)"
                case .velocityRange:
                    titleLabel.text = "Диапазон изменения скорости (velocityRange)"
                case .emissionLongitude:
                    titleLabel.text = "Угол направления частиц (emissionLongitude)"
                case .emissionRange:
                    titleLabel.text = "Диапазон изменения угла направления (emissionRange)"
                case .scale:
                    titleLabel.text = "Начальный размер частиц (scale)"
                case .scaleRange:
                    titleLabel.text = "Диапазон изменения размера (scaleRange)"
                case .alphaSpeed:
                    titleLabel.text = "Скорость изменения альфы (alphaSpeed)"
                }
                
                valueLabel.text = "\(_item.values.initial)"
                slider.value = _item.values.initial
                slider.minimumValue = _item.values.min
                slider.maximumValue = _item.values.max
            }
        }
    }
    
    override func setup() {
        selectionStyle = .none
        
        contentView.addSubview(titleLabel)
        titleLabel.textAlignment = .left
        titleLabel.font = .boldSystemFont(ofSize: 12)
        titleLabel.textColor = .black
        
        addSubview(valueLabel)
        valueLabel.textAlignment = .left
        valueLabel.font = .boldSystemFont(ofSize: 12)
        valueLabel.textColor = .systemBlue
        
        contentView.addSubview(slider)
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
    }
    
    override func setupSizes() {
        titleLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 4)
        titleLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 12)
        
        valueLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 4)
        valueLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 12)
        
        slider.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: 4)
        slider.autoPinEdgesToSuperviewEdges(with: .init(top: 0, left: 12, bottom: 4, right: 12), excludingEdge: .top)
    }
    
    @objc
    func sliderValueChanged(_ slider: UISlider) {
        guard let property = (item as? EmitterPropertyCellItem)?.property else { return }
        
        slider.value = round(10 * slider.value) / 10
        valueLabel.text = "\(slider.value)"
        delegate?.emitterPropertyDidChanged(property: property, newValue: slider.value)
    }
}

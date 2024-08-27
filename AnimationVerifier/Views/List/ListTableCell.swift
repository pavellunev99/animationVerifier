import Foundation
import INCR_UIExtensions

final class ListCellItem: TableViewCellItem {
    
    let itemType: ListItemType
    
    init(itemType: ListItemType) {
        self.itemType = itemType
        super.init(reuseIdentifier: "ListCellCell", cellType: ListCell.self)
    }
}

final class ListCell: TableViewCell {
    
    let icon = UIImageView()
    let label = UILabel()
    
    override var item: TableViewCellItem? {
        didSet {
            if let _item = self.item as? ListCellItem {
                switch _item.itemType {
                case .lottie:
                    icon.image = .init(systemName: "doc")
                    label.text = "JSON"
                case .emitter:
                    icon.image = .init(systemName: "party.popper")
                    label.text = "Emitter"
                }
            }
        }
    }
    
    override func setup() {
        selectionStyle = .none
        accessoryType = .disclosureIndicator
        
        contentView.addSubview(icon)
        icon.contentMode = .scaleAspectFit
        
        contentView.addSubview(label)
        label.textColor = .black
        label.textAlignment = .left
        label.font = .boldSystemFont(ofSize: 16)
    }
    
    override func setupSizes() {
        icon.autoPinEdge(toSuperviewEdge: .left, withInset: 24)
        icon.autoPinEdge(toSuperviewEdge: .top, withInset: 16)
        icon.autoPinEdge(toSuperviewEdge: .bottom, withInset: 16)
        icon.autoSetDimensions(to: .init(width: 32, height: 32))
        
        label.autoAlignAxis(.horizontal, toSameAxisOf: icon)
        label.autoPinEdge(.left, to: .right, of: icon, withOffset: 16)
    }
}

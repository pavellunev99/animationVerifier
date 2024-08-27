import UIKit
import INCR_UIExtensions

enum ListItemType {
    case lottie
    case emitter
}

final class ListViewController: ViewController {
    
    let tableView = TableView()
    
    override func setup() {
        super.setup()
        
        view.backgroundColor = .white
        
        view.addSubview(tableView)
        tableView.sections = [.init(number: 0, items: [ListCellItem(itemType: .lottie), ListCellItem(itemType: .emitter)])]
        tableView.selectItemCallback = { [weak self] item in
            guard let self else { return }
            if let item = item as? ListCellItem {
                self.itemDidSelected(item.itemType)
            }
        }
    }
    
    override func setupSizes() {
        super.setupSizes()
        tableView.autoPinEdgesToSuperviewSafeArea()
    }
    
    private func itemDidSelected(_ type: ListItemType) {
        
        let controller: UIViewController
        
        switch type {
        case .lottie:
            controller = DocumentBrowserViewController()
        case .emitter:
            controller = EmitterViewController()
        }
        
        present(controller, animated: true)
    }
}

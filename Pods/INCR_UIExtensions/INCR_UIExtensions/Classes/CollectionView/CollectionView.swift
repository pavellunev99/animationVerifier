import Foundation

open class CollectionViewCellItem {
    public let reuseIdentifier: String
    public let cellType: AnyClass
    
    public init(reuseIdentifier: String, cellType: AnyClass) {
        self.reuseIdentifier = reuseIdentifier
        self.cellType = cellType
    }
}

open class CollectionViewCell: UICollectionViewCell {
    open var item: CollectionViewCellItem?
    open var sizeSet = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    public init() {
        super.init(frame: CGRect.zero)
        setup()
    }
    
    open func setup() {
        
    }
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if !sizeSet {
            sizeSet = true
            setupSizes()
        }
    }
    
    open func setupSizes() {
        
    }
}

open class CollectionViewSection {
    public let items: [CollectionViewCellItem]
    public let number: Int
    
    public init(number: Int, items: [CollectionViewCellItem]) {
        self.number = number
        self.items = items
    }
}

public typealias CollectionViewCallback = (_ item: Any) -> Void
public typealias CollectionViewCellConfigCallback = (_ cell: CollectionViewCell) -> Void
public typealias CollectionViewStartScrollCallback = () -> Void
public typealias CollectionViewStartDidScrollCallback = () -> Void
public typealias CollectionViewWasReloadedCallback = () -> Void

open class CollectionView: UICollectionView {
    public var registredCellIdentifiers: [String] = []
    
    public var selectItemCallback: CollectionViewCallback?
    public var configCellCallback: CollectionViewCellConfigCallback?
    public var startScrollCallback: CollectionViewStartScrollCallback?
    public var scrollCallback: CollectionViewStartDidScrollCallback?
    public var reloadCallback: CollectionViewWasReloadedCallback?
    
    public var sections: [CollectionViewSection] = [] {
        didSet {
            
            for section in self.sections {
                for item in section.items {
                    if !registredCellIdentifiers.contains(item.reuseIdentifier) {
                        register(item.cellType, forCellWithReuseIdentifier: item.reuseIdentifier)
                        registredCellIdentifiers.append(item.reuseIdentifier)
                    }
                }
            }
            
            _throttledReloadData()
        }
    }
    
    private var _nextPossibleReloadTS: TimeInterval = 0
    private var _reloadDelay: TimeInterval = 0.3
    
    @objc
    private func _throttledReloadData() {
        let currentTS = INCR_UISystemUptime.uptime()
        if currentTS >= _nextPossibleReloadTS {
            _nextPossibleReloadTS = currentTS + _reloadDelay
            reloadData()
        }else{
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_throttledReloadData), object: nil)
            perform(#selector(_throttledReloadData), with: nil, afterDelay: _nextPossibleReloadTS - currentTS)
        }
    }
    
    public override func reloadData() {
        super.reloadData()
        perform(#selector(_reloaded), with: nil, afterDelay: 0)
    }
    
    @objc
    private func _reloaded() {
        reloadCallback?()
    }
    
    public init() {
        super.init(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        delegate = self
        dataSource = self
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        delegate = self
        dataSource = self
    }
    
    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        delegate = self
        dataSource = self
    }
    
    public init(sections: [CollectionViewSection], collectionViewLayout layout: UICollectionViewFlowLayout) {
        
        layout.estimatedItemSize = .init(width: 1, height: 1)
        
        super.init(frame: .zero, collectionViewLayout: layout)
        delegate = self
        dataSource = self
        self.sections = sections
        
    }
    
    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_throttledReloadData), object: nil)
    }
}

extension CollectionView: UICollectionViewDelegate,UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let section = sections[indexPath.section]
        let item = section.items[indexPath.row]
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: item.reuseIdentifier, for: indexPath) as? CollectionViewCell {
            cell.item = item
            if let configCellCallback = configCellCallback {
                configCellCallback(cell)
            }
            return cell
        }else{
            fatalError("cell is not registred")
        }

    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCell {
            selectItemCallback?(cell)
        }
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        startScrollCallback?()
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollCallback?()
    }
}


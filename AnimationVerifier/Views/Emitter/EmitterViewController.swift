import Foundation
import INCR_UIExtensions
import PhotosUI

struct EmitterProperties {
    var birthRate: Float = 10
    var lifetime: Float = 10
    var velocity: Float = 15
    var velocityRange: Float = 50
    var emissionLongitude: Float = Float.pi
    var emissionRange: Float = 2 * Float.pi
    var scale: Float = 1.0
    var scaleRange: Float = 0.5
    var alphaSpeed: Float = 1
    
    func value(for property: EmitterProperty) -> Float {
        switch property {
        case .birthRate:
            birthRate
        case .lifetime:
            lifetime
        case .velocity:
            velocity
        case .velocityRange:
            velocityRange
        case .emissionLongitude:
            emissionLongitude
        case .emissionRange:
            emissionRange
        case .scale:
            scale
        case .scaleRange:
            scaleRange
        case .alphaSpeed:
            alphaSpeed
        }
    }
    
    static func maxValue(for property: EmitterProperty) -> Float {
        switch property {
        case .birthRate:
            400
        case .lifetime:
            50
        case .velocity:
            500
        case .velocityRange:
            200
        case .emissionLongitude:
            Float.pi
        case .emissionRange:
            2 * Float.pi
        case .scale:
            10
        case .scaleRange:
            10
        case .alphaSpeed:
            100
        }
    }
}

enum EmitterProperty: CaseIterable {
    case birthRate
    case lifetime
    case velocity
    case velocityRange
    case emissionLongitude
    case emissionRange
    case scale
    case scaleRange
    case alphaSpeed
}

final class EmitterViewController: ViewController {
    
    let emitterContainer = UIView()
    let emitterLayer = CAEmitterLayer()
    let emitterCell = CAEmitterCell()
    let tableView = TableView()
    let shareButton = UIButton()
    let closeButton = UIButton()
    
    var emitterProperties: EmitterProperties = .init() {
        didSet {
            emitterLayer.setValue(emitterProperties.birthRate, forKeyPath: "emitterCells.cell.birthRate")
            emitterLayer.setValue(emitterProperties.lifetime, forKeyPath: "emitterCells.cell.lifetime")
            emitterLayer.setValue(emitterProperties.velocity, forKeyPath: "emitterCells.cell.velocity")
            emitterLayer.setValue(emitterProperties.velocityRange, forKeyPath: "emitterCells.cell.velocityRange")
            emitterLayer.setValue(emitterProperties.emissionLongitude, forKeyPath: "emitterCells.cell.emissionLongitude")
            emitterLayer.setValue(emitterProperties.emissionRange, forKeyPath: "emitterCells.cell.emissionRange")
            emitterLayer.setValue(emitterProperties.scale, forKeyPath: "emitterCells.cell.scale")
            emitterLayer.setValue(emitterProperties.scaleRange, forKeyPath: "emitterCells.cell.scaleRange")
            emitterLayer.setValue(emitterProperties.alphaSpeed, forKeyPath: "emitterCells.cell.alphaSpeed")
        }
    }
    
    var emitterBackgroundColor: UIColor = .black {
        didSet {
            emitterContainer.backgroundColor = emitterBackgroundColor
        }
    }
    
    var cellContents: UIImage? = UIImage(named: "particle") {
        didSet {
            emitterLayer.setValue(cellContents?.cgImage, forKeyPath: "emitterCells.cell.contents")
        }
    }

    override func setup() {
        super.setup()
        
        view.backgroundColor = .white

        navigationItem.backButtonTitle = "Close"
        
        view.addSubview(closeButton)
        closeButton.setTitle("Close", for: .normal)
        closeButton.setTitleColor(.systemBlue, for: .normal)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        
        view.addSubview(shareButton)
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.tintColor = .systemBlue
        shareButton.addTarget(self, action: #selector(share), for: .touchUpInside)

        view.addSubview(emitterContainer)
        emitterContainer.layer.masksToBounds = true
        
        emitterContainer.layer.addSublayer(emitterLayer)
        emitterLayer.emitterShape = .point
        
        emitterCell.name = "cell"
        emitterCell.contents = cellContents?.cgImage
        emitterCell.birthRate = emitterProperties.birthRate
        emitterCell.lifetime = emitterProperties.lifetime
        emitterCell.velocity = CGFloat(emitterProperties.velocity)
        emitterCell.velocityRange = CGFloat(emitterProperties.velocityRange)
        emitterCell.emissionLongitude = CGFloat(emitterProperties.emissionLongitude)
        emitterCell.emissionRange = CGFloat(emitterProperties.emissionRange)
        emitterCell.scale = CGFloat(emitterProperties.scale)
        emitterCell.scaleRange = CGFloat(emitterProperties.scaleRange)
        emitterCell.alphaSpeed = emitterProperties.alphaSpeed
        
        emitterLayer.emitterCells = [emitterCell]
        
        emitterContainer.backgroundColor = emitterBackgroundColor
        
        view.addSubview(tableView)
        tableView.allowsSelection = false
        tableView.contentInset = .init(top: 0, left: 0, bottom: 12, right: 0)
        
        tableView.configCellCallback = { [weak self] cell in
            (cell as? EmitterPropertyCell)?.delegate = self
            (cell as? EmitterPropertyButtonsCell)?.delegate = self
        }
       
        updateTable()
    }
    
    func updateTable() {
        tableView.sections = [
            TableViewSection(number: 0, items: [EmitterPropertyButtonsCellItem(color: emitterBackgroundColor, image: cellContents)]),
            TableViewSection(number: 1, items: EmitterProperty.allCases.map({
                EmitterPropertyCellItem(property: $0, values: (initial: emitterProperties.value(for: $0),
                                                               min: 0,
                                                               max: EmitterProperties.maxValue(for: $0)))
            }))]
    }

    @objc 
    func close() {
        dismiss(animated: true)
    }
    
    @objc
    func share() {
        let shareText = """
        cell.birthRate = \(emitterProperties.birthRate)
        cell.lifetime = \(emitterProperties.lifetime)
        cell.velocity = \(emitterProperties.velocity)
        cell.velocityRange = \(emitterProperties.velocityRange)
        cell.emissionLongitude = \(emitterProperties.emissionLongitude)
        cell.emissionRange = \(emitterProperties.emissionRange)
        cell.scale = \(emitterProperties.scale)
        cell.scaleRange = \(emitterProperties.scaleRange)
        cell.alphaSpeed = \(emitterProperties.alphaSpeed)
        """
        
        let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        emitterLayer.emitterPosition = CGPoint(x: emitterContainer.bounds.width/2, y: emitterContainer.bounds.height/2)
    }

    override func setupSizes() {
        super.setupSizes()
        
        closeButton.autoPinEdge(toSuperviewEdge: .leading, withInset: 8)
        closeButton.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
        closeButton.autoSetDimensions(to: .init(width: 100, height: 40))
        
        shareButton.autoPinEdge(toSuperviewEdge: .trailing, withInset: 8)
        shareButton.autoPinEdge(toSuperviewEdge: .top, withInset: 8)
        shareButton.autoSetDimensions(to: .init(width: 44, height: 44))
        
        emitterContainer.autoPinEdge(.top, to: .bottom, of: closeButton, withOffset: 4)
        emitterContainer.autoPinEdge(toSuperviewEdge: .left)
        emitterContainer.autoPinEdge(toSuperviewEdge: .right)
        emitterContainer.autoMatch(.height, to: .width, of: view)
        
        tableView.autoPinEdge(.top, to: .bottom, of: emitterContainer)
        tableView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
    }
}

extension EmitterViewController: EmitterPropertyCellDelegate {
    
    func emitterPropertyDidChanged(property: EmitterProperty, newValue: Float) {
        switch property {
        case .birthRate:
            emitterProperties.birthRate = newValue
        case .lifetime:
            emitterProperties.lifetime = newValue
        case .velocity:
            emitterProperties.velocity = newValue
        case .velocityRange:
            emitterProperties.velocityRange = newValue
        case .emissionLongitude:
            emitterProperties.emissionLongitude = newValue
        case .emissionRange:
            emitterProperties.emissionRange = newValue
        case .scale:
            emitterProperties.scale = newValue
        case .scaleRange:
            emitterProperties.scaleRange = newValue
        case .alphaSpeed:
            emitterProperties.alphaSpeed = newValue
        }
    }
}

extension EmitterViewController: EmitterPropertyButtonsCellDelegate {
    
    func colorSelectorDidTapped() {
        let picker = UIColorPickerViewController()
        picker.selectedColor = self.emitterBackgroundColor
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    func imageSelectorDidTapped() {
        let alert = UIAlertController()
        alert.addAction(.init(title: "Файлы", style: .default, handler: { action in
            let browser = UIDocumentBrowserViewController(forOpening: [.image])
            browser.allowsDocumentCreation = false
            browser.allowsPickingMultipleItems = false
            browser.delegate = self
            self.present(browser, animated: true, completion: nil)
        }))
        alert.addAction(.init(title: "Медиатека", style: .default, handler: { action in
            var configuration = PHPickerConfiguration(photoLibrary: .shared())
            configuration.selectionLimit = 1
            configuration.filter = .images
            
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
}

extension EmitterViewController: UIColorPickerViewControllerDelegate {
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        self.emitterBackgroundColor = viewController.selectedColor
        self.updateTable()
        
    }
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        self.emitterBackgroundColor = viewController.selectedColor
        self.updateTable()
    }
}

extension EmitterViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        results.first?.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
            DispatchQueue.main.async {
                if let image = image as? UIImage {
                    self.cellContents = image
                    self.updateTable()
                }
            }
        }
    }
}

extension EmitterViewController: UIDocumentBrowserViewControllerDelegate {
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        let newDocumentURL: URL? = nil

        if newDocumentURL != nil {
            importHandler(newDocumentURL, .move)
        } else {
            importHandler(nil, .none)
        }
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        presentDocument(at: sourceURL)
        controller.dismiss(animated: true)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        presentDocument(at: destinationURL)
        controller.dismiss(animated: true)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    func presentDocument(at documentURL: URL) {
        guard documentURL.startAccessingSecurityScopedResource() else { return }
        defer { documentURL.stopAccessingSecurityScopedResource() }
        
        guard let data = try? Data(contentsOf: documentURL), let image = UIImage(data: data) else { return }
        cellContents = image
        updateTable()
    }
}

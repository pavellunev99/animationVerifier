//
//  DocumentBrowserViewController.swift
//  docTest
//
//  Created by Антон Красильников on 27.12.2022.
//

import UIKit
import ZIPFoundation

class AnimationDocument: UIDocument {

    var animationURL: URL?

    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        let sourceURL = fileURL

        let fileManager = FileManager.default

        let currentWorkingPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!

        var destinationURL = URL(fileURLWithPath: currentWorkingPath)
        destinationURL.appendPathComponent("unzipped")
        try? fileManager.removeItem(at: destinationURL)

        do {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: sourceURL, to: destinationURL)

            let files = try fileManager.contentsOfDirectory(atPath: destinationURL.path)
            if let json = files.first(where: { $0.hasSuffix(".json") }) {
                self.animationURL = destinationURL.appendingPathComponent(json)
            }
        } catch {

        }
    }
}

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        allowsDocumentCreation = false
        allowsPickingMultipleItems = false
    }
    
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
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
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {

    }
    
    // MARK: Document Presentation
    
    func presentDocument(at documentURL: URL) {
        let document = AnimationDocument(fileURL: documentURL)
        document.open { [weak document] success in
            defer { document?.close() }
            guard let unzippedURL = document?.animationURL else { return }
            self.present(AnimationViewController(url: unzippedURL), animated: true)
        }
    }
}


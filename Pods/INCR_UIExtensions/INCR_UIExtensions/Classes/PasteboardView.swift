import Foundation

public class PasteboardView: AlertPopover {
    
    public class func copy(text: String, message: String = "Copied", above view: UIView) {
        UIPasteboard.general.string = text

        showMessage(message: message, above: view)
    }
}

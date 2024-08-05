import Foundation

public extension String {
    subscript(i: Int) -> String {
        return String(self[index(startIndex, offsetBy: i)])
    }
}

public extension NumberFormatter {
    private static var numberFormatter: NumberFormatter?
    private static func _numberFormatter() -> NumberFormatter {
        if numberFormatter == nil {
            numberFormatter = NumberFormatter()
            numberFormatter!.usesGroupingSeparator = true
            numberFormatter!.groupingSeparator = " "
            numberFormatter!.groupingSize = 3
            numberFormatter!.minimumFractionDigits = 0
            numberFormatter!.maximumFractionDigits = 2
        }
        return numberFormatter!
    }
    
    private static var fructionNumberFormatter: NumberFormatter?
    fileprivate static func _fructionNumberFormatter() -> NumberFormatter {
        if fructionNumberFormatter == nil {
            fructionNumberFormatter = NumberFormatter()
            fructionNumberFormatter!.minimumFractionDigits = 0
            fructionNumberFormatter!.maximumFractionDigits = 2
        }
        return fructionNumberFormatter!
    }
    
    static func thousandFormattedNumber(number: Int) -> String {
        return _numberFormatter().string(from: NSNumber(integerLiteral: number)) ?? "\(number)"
    }
    
    static func thousandFormattedNumber(number: Int64) -> String {
        return _numberFormatter().string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    static func thousandFormattedNumber(number: Double) -> String {
        return _numberFormatter().string(from: NSNumber(floatLiteral: number)) ?? "\(number)"
    }
}

public extension String {
    
    func localize() -> String {
        return NSLocalizedString(self, comment: "")
    }
    
}

public extension String {
    init(number: Int, thousandFormatted: Bool = true) {
        if thousandFormatted {
            self = NumberFormatter.thousandFormattedNumber(number: number)
        }else{
            self = "\(number)"
        }
    }
    
    init(number: Int64, thousandFormatted: Bool = true) {
        if thousandFormatted {
            self = NumberFormatter.thousandFormattedNumber(number: number)
        }else{
            self = "\(number)"
        }
    }
    
    init(number: Double, thousandFormatted: Bool = true) {
        if thousandFormatted {
            self = NumberFormatter.thousandFormattedNumber(number: number)
        }else{
            self = "\(number)"
        }
    }
}

public extension String {
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }

    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }

    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }

    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
}

public extension Float {
    var twoFructionString: String {
        NumberFormatter._fructionNumberFormatter().string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

public extension Double {
    var twoFructionString: String {
        NumberFormatter._fructionNumberFormatter().string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

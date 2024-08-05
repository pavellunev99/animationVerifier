import Foundation

public class DispatchTimer {
    public class func perform(after seconds: TimeInterval, queue: DispatchQueue = .main, completion: @escaping () -> Void) {
        let deadlineTime = DispatchTime.now() + .milliseconds(Int(seconds*1000.0))
        
        queue.asyncAfter(deadline: deadlineTime) {
            completion()
        }
    }
}

#if os(iOS)
    import Foundation
    import UIKit

    enum ViewLayoutTracker {
        // nonisolated because its manually locked with setupLock
        nonisolated(unsafe) static var hasChanges = false
        private nonisolated(unsafe) static var hasSwizzled = false

        static func viewDidLayout(view _: UIView) {
            hasChanges = true
        }

        static func clear() {
            hasChanges = false
        }

        static func swizzleLayoutSubviews() {
            if hasSwizzled {
                return
            }
            swizzle(forClass: UIView.self,
                    original: #selector(UIView.layoutSubviews),
                    new: #selector(UIView.layoutSubviewsOverride))
            hasSwizzled = true
        }

        static func unSwizzleLayoutSubviews() {
            if !hasSwizzled {
                return
            }
            swizzle(forClass: UIView.self,
                    original: #selector(UIView.layoutSubviewsOverride),
                    new: #selector(UIView.layoutSubviews))
            hasSwizzled = false
        }
    }

    extension UIView {
        @objc func layoutSubviewsOverride() {
            guard Thread.isMainThread else {
                return
            }
            layoutSubviewsOverride()
            ViewLayoutTracker.viewDidLayout(view: self)
        }
    }

#endif

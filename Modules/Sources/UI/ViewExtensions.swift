import SwiftUI

// origin: https://gist.github.com/Amzd/cb8ba40625aeb6a015101d357acaad88
public extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        return self.onContinuousHover { phase in
            switch phase {
            case .active(_):
                guard NSCursor.current != cursor else { return }
                cursor.push()
            case .ended:
                NSCursor.pop()
            }
        }
    }
}

public extension View {
    func logChanges() {
#if DEBUG
        if #available(macOS 14.1, *) {
            Self._logChanges()
        }
#endif
    }
}

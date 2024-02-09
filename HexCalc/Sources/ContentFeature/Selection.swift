import Foundation
import Utils

public struct Selection: Equatable {
    var bounds: Range<Int>
    var cursorIndex: Int
    var selectedIndexes: Range<Int>?

    public init(bitWidth: Bits, cursorIndex: Int? = nil, selectedIndexes: Range<Int>? = nil) {
        bounds = 0 ..< bitWidth.rawValue
        self.cursorIndex = cursorIndex ?? selectedIndexes?.mid(rounding: .down) ?? bounds.last!
        self.selectedIndexes = selectedIndexes
    }

    mutating
    func setBitWidth(_ bitWidth: Bits) {
        bounds = 0 ..< bitWidth.rawValue
    }

    mutating
    func moveCursor(_ direction: CursorDirection) {
        let newIndex = switch direction {
        case .left: cursorIndex - 1
        case .right: cursorIndex + 1
        }
        setCursor(newIndex)
    }

    mutating
    func setCursor(_ index: Int) {
        selectedIndexes = nil
        cursorIndex = index.clamped(to: bounds)
    }

    mutating
    func select(towards direction: CursorDirection) {
        guard let selectedIndexes else {
            switch direction {
            case .left: if cursorIndex == bounds.first { return }
            case .right: if cursorIndex == bounds.last { return }
            }

            select(cursorIndex)
            return
        }

        guard let first = selectedIndexes.first, let last = selectedIndexes.last else { return }

        // If the cursor is not already at a selection bound, move it to the appropriate selection bound
        if cursorIndex != first && cursorIndex != last {
            return switch direction {
            case .left: cursorIndex = first
            case .right: cursorIndex = last
            }
        }

        let newIndex = switch direction {
        case .left: cursorIndex - 1
        case .right: cursorIndex + 1
        }

        select(newIndex)
    }

    mutating
    func clickSelect(_ index: Int) {
        if let selectedIndexes {
            cursorIndex = selectedIndexes.mid(rounding: .down)
        }

        select(index)
    }

    mutating
    private func select(_ index: Int) {
        let selectionIndex = index.clamped(to: bounds)

        if selectedIndexes == nil {
            if selectionIndex > cursorIndex {
                selectedIndexes = cursorIndex ..< selectionIndex + 1
            } else {
                selectedIndexes = selectionIndex ..< cursorIndex + 1
            }
        } else {
            if let last = selectedIndexes?.last, let first = selectedIndexes?.first {
                if cursorIndex == first && cursorIndex == last {
                    if selectionIndex > cursorIndex {
                        selectedIndexes = cursorIndex ..< selectionIndex + 1
                    } else {
                        selectedIndexes = selectionIndex ..< cursorIndex + 1
                    }
                } else if cursorIndex == first {
                    selectedIndexes = selectionIndex ..< last + 1
                } else if cursorIndex == last {
                    selectedIndexes = first ..< selectionIndex + 1
                } else {
                    if selectionIndex > cursorIndex {
                        selectedIndexes = first ..< selectionIndex + 1
                    } else {
                        selectedIndexes = selectionIndex ..< last + 1
                    }
                }
            }
        }
        
        cursorIndex = selectionIndex
    }

    mutating
    func selectAll() {
        selectedIndexes = bounds
        cursorIndex = bounds.mid(rounding: .down)
    }

    mutating
    func clear() {
        selectedIndexes = nil
    }
}

public enum CursorDirection {
    case left
    case right
}

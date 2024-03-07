import Foundation
import Utils

public struct Selection: Equatable {
    var bounds: Range<Int>
    var cursorIndex: Int
    var selectedIndexes: Range<Int>?

    public init(bounds: Range<Int>, cursorIndex: Int? = nil, selectedIndexes: Range<Int>? = nil) {
        precondition(selectedIndexes == nil || bounds.contains(selectedIndexes!))
        precondition(cursorIndex == nil || bounds.contains(cursorIndex!))
        self.bounds = bounds
        self.cursorIndex = cursorIndex ?? selectedIndexes?.last ?? bounds.last!
        self.selectedIndexes = selectedIndexes
    }

    mutating
    func setBounds(_ bounds: Range<Int>) {
        self.bounds = bounds
        cursorIndex = cursorIndex.clamped(to: bounds)
        selectedIndexes = selectedIndexes?.clamped(to: bounds)
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
        guard bounds.contains(index) else { return }
        if let selectedIndexes {
            cursorIndex = selectedIndexes.mid(rounding: .down)
        }

        select(index)
    }

    mutating
    func dragSelect(_ index: Int) {
        guard bounds.contains(index) else { return }
        if selectedIndexes == nil {
            cursorIndex = index
        }
        select(index)
    }

    private mutating func select(_ index: Int) {
        precondition(selectedIndexes?.contains(cursorIndex) ?? true)

        let selectionIndex = index.clamped(to: bounds)
        defer { cursorIndex = selectionIndex }

        guard let selectedIndexes else {
            // When there's no current selection
            selectedIndexes = min(cursorIndex, selectionIndex) ..< max(cursorIndex, selectionIndex) + 1
            return
        }

        let first = selectedIndexes.lowerBound
        let last = selectedIndexes.upperBound - 1 // Adjust because upperBound is exclusive

        // New selection before existing selection: Expand selection left
        if selectionIndex < first {
            self.selectedIndexes = selectionIndex ..< last + 1
            return
        }

        // New selection after existing selection: Expand selection right
        if selectionIndex > last {
            self.selectedIndexes = first ..< selectionIndex + 1
            return
        }

        // New selection within existing selection

        // Cursor at left boundary: shrink selection from left
        if cursorIndex == first {
            self.selectedIndexes = selectionIndex ..< last + 1
            return
        }

        // Cursor at right boundary: shrink selection from right
        if cursorIndex == last {
            self.selectedIndexes = first ..< selectionIndex + 1
            return
        }

        // Cursor is inside the selection but not at selection boundaries,
        // shrink or expand depending on which side of the cursor the
        // new selection lies

        // New selection before cursor: shrink or expand from left
        if selectionIndex <= cursorIndex {
            self.selectedIndexes = selectionIndex ..< last + 1
            return
        }

        // New selection after cursor: shrink or expand from right
        self.selectedIndexes = first ..< selectionIndex + 1
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

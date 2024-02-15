@testable import ContentFeature
import CustomDump
import XCTest

final class SelectionTests: XCTestCase {
    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    // MARK: - ⌘-A selection

    func testStartsWithNoSelectionAndCursorOnLSB() {
        let selection = Selection(bounds: Bits._8.selectionBounds(within: ._8))

        XCTAssertNoDifference(selection.selectedIndexes, nil)
        XCTAssertNoDifference(selection.cursorIndex, 7)
    }

    func testSelectAll_SelectsAll_MovesCursorToMidpoint() throws {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8))
        XCTAssertNoDifference(selection.cursorIndex, 7)

        selection.selectAll()

        XCTAssertNoDifference(selection.selectedIndexes?.lowerBound, 0)
        XCTAssertNoDifference(selection.selectedIndexes?.upperBound, 8)
        XCTAssertNoDifference(selection.cursorIndex, 3)
    }

    func testSelectLeftAfterSelectAll_MovesCursorToStart_DoesNotChangeSelection() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8))
        selection.selectAll()
        XCTAssertNoDifference(selection.selectedIndexes, selection.bounds)
        XCTAssertNoDifference(selection.cursorIndex, 3)

        selection.select(towards: .left)
        XCTAssertNoDifference(selection.selectedIndexes, selection.bounds)
        XCTAssertNoDifference(selection.cursorIndex, 0)
    }

    func testSelectRightAfterSelectAll_MovesCursorToEnd_DoesNotChangeSelection() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8))
        selection.selectAll()
        XCTAssertNoDifference(selection.selectedIndexes, selection.bounds)
        XCTAssertNoDifference(selection.cursorIndex, 3)

        selection.select(towards: .right)
        XCTAssertNoDifference(selection.selectedIndexes, selection.bounds)
        XCTAssertNoDifference(selection.cursorIndex, 7)
    }

    // MARK: - ⇧-arrow key selection

    func testWithNoSelection_CursorOn0_SelectLeft_ChangesNothing() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8))
        selection.setCursor(0)
        XCTAssertNoDifference(selection.selectedIndexes, nil)
        XCTAssertNoDifference(selection.cursorIndex, 0)

        selection.select(towards: .left)
        XCTAssertNoDifference(selection.selectedIndexes, nil)
        XCTAssertNoDifference(selection.cursorIndex, 0)
    }

    func testWithNoSelection_CursorOn0_SelectRight_Selects0_DoesNotMoveCursor() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8))
        selection.setCursor(0)
        XCTAssertNoDifference(selection.selectedIndexes, nil)
        XCTAssertNoDifference(selection.cursorIndex, 0)

        selection.select(towards: .right)
        XCTAssertNoDifference(selection.selectedIndexes, 0 ..< 1)
        XCTAssertNoDifference(selection.cursorIndex, 0)
    }

    func testWith0Selected_CursorOn0_SelectRight_Selects01_MovesCursorRight() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 0, selectedIndexes: 0 ..< 1)
        XCTAssertNoDifference(selection.selectedIndexes, 0 ..< 1)
        XCTAssertNoDifference(selection.cursorIndex, 0)

        selection.select(towards: .right)
        XCTAssertNoDifference(selection.selectedIndexes, 0 ..< 2)
        XCTAssertNoDifference(selection.cursorIndex, 1)
    }

    func testWith0123456Selected_CursorOn6_SelectRight_Selectst01234567_MovesCursorRight() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 6, selectedIndexes: 0 ..< 7)
        XCTAssertNoDifference(selection.selectedIndexes, 0 ..< 7)
        XCTAssertNoDifference(selection.cursorIndex, 6)

        selection.select(towards: .right)
        XCTAssertNoDifference(selection.selectedIndexes, 0 ..< 8)
        XCTAssertNoDifference(selection.cursorIndex, 7)
    }

    func testWith01234567Selected_CursorOn7_SelectLeft_Deselects7_MovesCursorLeft() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 7, selectedIndexes: 0 ..< 8)
        XCTAssertNoDifference(selection.selectedIndexes, 0 ..< 8)
        XCTAssertNoDifference(selection.cursorIndex, 7)

        selection.select(towards: .left)
        XCTAssertNoDifference(selection.selectedIndexes, 0 ..< 7)
        XCTAssertNoDifference(selection.cursorIndex, 6)
    }

    // MARK: Keyboard selection from 7

    func testWithNoSelection_CursorOn7_SelectRight_ChangesNothing() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8))
        XCTAssertNoDifference(selection.selectedIndexes, nil)
        XCTAssertNoDifference(selection.cursorIndex, 7)

        selection.select(towards: .right)
        XCTAssertNoDifference(selection.selectedIndexes, nil)
        XCTAssertNoDifference(selection.cursorIndex, 7)
    }

    func testWithNoSelection_CursorOn7_SelectLeft_Selects7_DoesNotMoveCursor() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8))
        selection.setCursor(7)
        XCTAssertNoDifference(selection.selectedIndexes, nil)
        XCTAssertNoDifference(selection.cursorIndex, 7)

        selection.select(towards: .left)
        XCTAssertNoDifference(selection.selectedIndexes, 7 ..< 8)
        XCTAssertNoDifference(selection.cursorIndex, 7)
    }

    func testWith7Selected_CursorOn7_SelectLeft_Selects67_MovesCursorLeft() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 7, selectedIndexes: 7 ..< 8)
        XCTAssertNoDifference(selection.selectedIndexes, 7 ..< 8)
        XCTAssertNoDifference(selection.cursorIndex, 7)

        selection.select(towards: .left)
        XCTAssertNoDifference(selection.selectedIndexes, 6 ..< 8)
        XCTAssertNoDifference(selection.cursorIndex, 6)
    }

    func testWith1234567Selected_CursorOn1_SelectLeft_Selects01234567_MovesCursorLeft() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 1, selectedIndexes: 1 ..< 8)
        XCTAssertNoDifference(selection.selectedIndexes, 1 ..< 8)
        XCTAssertNoDifference(selection.cursorIndex, 1)

        selection.select(towards: .left)
        XCTAssertNoDifference(selection.selectedIndexes, 0 ..< 8)
        XCTAssertNoDifference(selection.cursorIndex, 0)
    }

    // MARK:

    func testWith01234567Selected_CursorOn0_SelectRight_Deselects0_MovesCursorRight() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 0, selectedIndexes: 0 ..< 8)
        XCTAssertNoDifference(selection.selectedIndexes, 0 ..< 8)
        XCTAssertNoDifference(selection.cursorIndex, 0)

        selection.select(towards: .right)
        XCTAssertNoDifference(selection.selectedIndexes, 1 ..< 8)
        XCTAssertNoDifference(selection.cursorIndex, 1)
    }

    func testWith01234Selected_CursorOn0_SelectRight_Deselects0_MovesCursorRight() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 0, selectedIndexes: 0 ..< 5)
        XCTAssertNoDifference(selection.selectedIndexes, 0 ..< 5)
        XCTAssertNoDifference(selection.cursorIndex, 0)

        selection.select(towards: .right)
        XCTAssertNoDifference(selection.selectedIndexes, 1 ..< 5)
        XCTAssertNoDifference(selection.cursorIndex, 1)
    }

    func testWith0123Selected_CursorOn0_SelectRight_Deselects0_MovesCursorRight() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 0, selectedIndexes: 0 ..< 4)
        XCTAssertNoDifference(selection.selectedIndexes, 0 ..< 4)
        XCTAssertNoDifference(selection.cursorIndex, 0)

        selection.select(towards: .right)
        XCTAssertNoDifference(selection.selectedIndexes, 1 ..< 4)
        XCTAssertNoDifference(selection.cursorIndex, 1)
    }

    func testWith012Selected_CursorOn0_SelectRight_Deselects0_MovesCursorRight() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 0, selectedIndexes: 0 ..< 3)
        XCTAssertNoDifference(selection.selectedIndexes, 0 ..< 3)
        XCTAssertNoDifference(selection.cursorIndex, 0)

        selection.select(towards: .right)
        XCTAssertNoDifference(selection.selectedIndexes, 1 ..< 3)
        XCTAssertNoDifference(selection.cursorIndex, 1)
    }

    func testWith01Selected_CursorOn0_SelectRight_Deselects0_MovesCursorRight() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 0, selectedIndexes: 0 ..< 2)
        XCTAssertNoDifference(selection.selectedIndexes, 0 ..< 2)
        XCTAssertNoDifference(selection.cursorIndex, 0)

        selection.select(towards: .right)
        XCTAssertNoDifference(selection.selectedIndexes, 1 ..< 2)
        XCTAssertNoDifference(selection.cursorIndex, 1)
    }

    // MARK: ⇧-Click selection

    func testWithNoSelection_CursorOn0_Click1_Selects01_MovesCursorTo1() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 0)
        XCTAssertNoDifference(selection.selectedIndexes, nil)
        XCTAssertNoDifference(selection.cursorIndex, 0)

        selection.clickSelect(1)
        XCTAssertNoDifference(selection.selectedIndexes, 0 ..< 2)
        XCTAssertNoDifference(selection.cursorIndex, 1)
    }

    func testWithNoSelection_CursorOn0_Click7_Selects01234567_MovesCursorTo7() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 0)
        XCTAssertNoDifference(selection.selectedIndexes, nil)
        XCTAssertNoDifference(selection.cursorIndex, 0)

        selection.clickSelect(7)
        XCTAssertNoDifference(selection.selectedIndexes, 0 ..< 8)
        XCTAssertNoDifference(selection.cursorIndex, 7)
    }

    func testWithNoSelection_CursorOn7_Click6_Selects67_MovesCursorTo6() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 7)
        XCTAssertNoDifference(selection.selectedIndexes, nil)
        XCTAssertNoDifference(selection.cursorIndex, 7)

        selection.clickSelect(6)
        XCTAssertNoDifference(selection.selectedIndexes, 6 ..< 8)
        XCTAssertNoDifference(selection.cursorIndex, 6)
    }

    func testWithNoSelection_CursorOn7_Click0_Selects01234567_MovesCursorTo0() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 7)
        XCTAssertNoDifference(selection.selectedIndexes, nil)
        XCTAssertNoDifference(selection.cursorIndex, 7)

        selection.clickSelect(0)
        XCTAssertNoDifference(selection.selectedIndexes, 0 ..< 8)
        XCTAssertNoDifference(selection.cursorIndex, 0)
    }

    func test345Selected_CursorOn5_Click7_Selects34567_MovesCursorTo7() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 5, selectedIndexes: 3 ..< 6)
        XCTAssertNoDifference(selection.selectedIndexes, 3 ..< 6)
        XCTAssertNoDifference(selection.cursorIndex, 5)

        selection.clickSelect(7)
        XCTAssertNoDifference(selection.selectedIndexes, 3 ..< 8)
        XCTAssertNoDifference(selection.cursorIndex, 7)
    }

    func test3456Selected_CursorOn6_Click5_Selects345_MovesCursorTo5() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 6, selectedIndexes: 3 ..< 7)
        XCTAssertNoDifference(selection.selectedIndexes, 3 ..< 7)
        XCTAssertNoDifference(selection.cursorIndex, 6)

        selection.clickSelect(5)
        XCTAssertNoDifference(selection.selectedIndexes, 3 ..< 6)
        XCTAssertNoDifference(selection.cursorIndex, 5)
    }

    func test3456Selected_CursorOn6_Click4_Selects456_MovesCursorTo4() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 6, selectedIndexes: 3 ..< 7)
        XCTAssertNoDifference(selection.selectedIndexes, 3 ..< 7)
        XCTAssertNoDifference(selection.cursorIndex, 6)

        selection.clickSelect(4)
        XCTAssertNoDifference(selection.selectedIndexes, 4 ..< 7)
        XCTAssertNoDifference(selection.cursorIndex, 4)
    }

    func test3456Selected_CursorOn6_Click1_Selects123456_MovesCursorTo1() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 6, selectedIndexes: 3 ..< 7)
        XCTAssertNoDifference(selection.selectedIndexes, 3 ..< 7)
        XCTAssertNoDifference(selection.cursorIndex, 6)

        selection.clickSelect(1)
        XCTAssertNoDifference(selection.selectedIndexes, 1 ..< 7)
        XCTAssertNoDifference(selection.cursorIndex, 1)
    }

    func test12Selected_CursorOn1_Click6_Selects123456_MovesCursorTo6() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 1, selectedIndexes: 1 ..< 3)
        XCTAssertNoDifference(selection.selectedIndexes, 1 ..< 3)
        XCTAssertNoDifference(selection.cursorIndex, 1)

        selection.clickSelect(6)
        XCTAssertNoDifference(selection.selectedIndexes, 1 ..< 7)
        XCTAssertNoDifference(selection.cursorIndex, 6)
    }

    func test56Selected_CursorOn6_Click1_Selects123456_MovesCursorTo1() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 6, selectedIndexes: 5 ..< 7)
        XCTAssertNoDifference(selection.selectedIndexes, 5 ..< 7)
        XCTAssertNoDifference(selection.cursorIndex, 6)

        selection.clickSelect(1)
        XCTAssertNoDifference(selection.selectedIndexes, 1 ..< 7)
        XCTAssertNoDifference(selection.cursorIndex, 1)
    }

    func test34Selected_CursorOn4_Click1_Selects1234_MovesCursorTo1() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 4, selectedIndexes: 3 ..< 5)
        XCTAssertNoDifference(selection.selectedIndexes, 3 ..< 5)
        XCTAssertNoDifference(selection.cursorIndex, 4)

        selection.clickSelect(1)
        XCTAssertNoDifference(selection.selectedIndexes, 1 ..< 5)
        XCTAssertNoDifference(selection.cursorIndex, 1)
    }

    // MARK: - Drag selection

    func testNoSelection_CursorOn0_DragFrom4_Selects4_MovesCursorTo4() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 0, selectedIndexes: nil)
        XCTAssertNoDifference(selection.selectedIndexes, nil)
        XCTAssertNoDifference(selection.cursorIndex, 0)

        selection.dragSelect(4)
        XCTAssertNoDifference(selection.selectedIndexes, 4 ..< 5)
        XCTAssertNoDifference(selection.cursorIndex, 4)
    }

    func testNoSelection_CursorOn7_DragFrom4_Selects4_MovesCursorTo4() {
        var selection = Selection(bounds: Bits._8.selectionBounds(within: ._8), cursorIndex: 7, selectedIndexes: nil)
        XCTAssertNoDifference(selection.selectedIndexes, nil)
        XCTAssertNoDifference(selection.cursorIndex, 7)

        selection.dragSelect(4)
        XCTAssertNoDifference(selection.selectedIndexes, 4 ..< 5)
        XCTAssertNoDifference(selection.cursorIndex, 4)
    }
}

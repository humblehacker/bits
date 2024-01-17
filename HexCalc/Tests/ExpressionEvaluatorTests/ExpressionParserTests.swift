@testable import ExpressionEvaluator
import XCTest

final class ExpressionParserTests: XCTestCase {
    func testDecimalValue() throws {
        var input = "15"[...].utf8
        let actual = try ExpressionParser().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(15, actual)
    }

    func testHexValue() throws {
        var input = "0xf"[...].utf8
        let actual = try ExpressionParser().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(15, actual)
    }

    func testBinValue() throws {
        var input = "0b1111"[...].utf8
        let actual = try ExpressionParser().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(15, actual)
    }

    func testAddition() throws {
        var input = "0b1111+15+0xf"[...].utf8
        let actual = try ExpressionParser().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(45, actual)
    }

    func testSubtraction() throws {
        var input = "0b1111-15-0xf"[...].utf8
        let actual = try ExpressionParser().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(-15, actual)
    }

    func testMultiplication() throws {
        var input = "0b1111*15"[...].utf8
        let actual = try ExpressionParser().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(225, actual)
    }

    func testDivision() throws {
        var input = "0b1111/15"[...].utf8
        let actual = try ExpressionParser().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(1, actual)
    }

    func testParenthesisedExpressions() throws {
        var input = "(5+2)*2"[...].utf8
        let actual = try ExpressionParser().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(14, actual)
    }

    func testBitwiseOr() throws {
        var input = "0b1100|0b0111"[...].utf8
        let actual = try ExpressionParser().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(15, actual)
    }

    func testBitwiseXor() throws {
        var input = "0b01^0b11"[...].utf8
        let actual = try ExpressionParser().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(2, actual)
    }

    func testBitwiseAnd() throws {
        var input = "0b0100&0b1111"[...].utf8
        let actual = try ExpressionParser().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(4, actual)
    }
}


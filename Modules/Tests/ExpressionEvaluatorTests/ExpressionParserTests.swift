@testable import ExpressionEvaluator
import XCTest

final class ExpressionParserTests: XCTestCase {
    func testDecimalValue() throws {
        var input = "15"[...].utf8
        let actual = try ExpressionParser<Int8>().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(15, actual)
    }

    func testHexValue() throws {
        var input = "0xf"[...].utf8
        let actual = try ExpressionParser<Int8>().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(15, actual)
    }

    func testBinValue() throws {
        var input = "0b1111"[...].utf8
        let actual = try ExpressionParser<Int8>().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(15, actual)
    }

    func testAddition() throws {
        var input = "0b1111+15+0xf"[...].utf8
        let actual = try ExpressionParser<Int8>().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(45, actual)
    }

    func testSubtraction() throws {
        var input = "0b1111-15-0xf"[...].utf8
        let actual = try ExpressionParser<Int8>().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(-15, actual)
    }

    func testMultiplication() throws {
        var input = "0b1111*15"[...].utf8
        let actual = try ExpressionParser<Int16>().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(225, actual)
    }

    func testDivision() throws {
        var input = "0b1111/15"[...].utf8
        let actual = try ExpressionParser<Int8>().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(1, actual)
    }

    func testParenthesisedExpressions() throws {
        var input = "(5+2)*2"[...].utf8
        let actual = try ExpressionParser<Int8>().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(14, actual)
    }

    func testParenthesisedExpressions2() throws {
        var input = "(-127 >> 1) + 64"[...].utf8
        let actual = try ExpressionParser<Int8>().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(0, actual)
    }

    func testBitwiseOr() throws {
        var input = "0b1100|0b0111"[...].utf8
        let actual = try ExpressionParser<Int8>().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(15, actual)
    }

    func testBitwiseXor() throws {
        var input = "0b01^0b11"[...].utf8
        let actual = try ExpressionParser<Int8>().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(2, actual)
    }

    func testBitwiseAnd() throws {
        var input = "0b0100&0b1111"[...].utf8
        let actual = try ExpressionParser<Int8>().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(4, actual)
    }

    func testInt8_AdditionWraps() throws {
        var input = "127 + 1"[...].utf8
        let actual = try ExpressionParser<Int8>().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(-128, actual)
    }

    func testInt8_SubtractionWraps() throws {
        var input = "-128 - 1"[...].utf8
        let actual = try ExpressionParser<Int8>().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(127, actual)
    }

    func testInt8_MultiplicationWraps() throws {
        var input = "64 * 2"[...].utf8
        let actual = try ExpressionParser<Int8>().parse(&input)
        XCTAssertNotNil(actual)
        XCTAssertEqual(-128, actual)
    }
}

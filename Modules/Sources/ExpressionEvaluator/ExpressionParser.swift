import Foundation
import Parsing

struct ExpressionParser: Parser {
    var body: some Parser<Substring.UTF8View, Int> {
        BitwiseOr()
    }
}

struct BitwiseOr: Parser {
    var body: some Parser<Substring.UTF8View, Int> {
        InfixOperator(associativity: .left) {
            "|".utf8.map { (|) as (Int, Int) -> Int }
        } follows: {
            BitwiseXor()
        }
    }
}

struct BitwiseXor: Parser {
    var body: some Parser<Substring.UTF8View, Int> {
        InfixOperator(associativity: .left) {
            "^".utf8.map { (^) as (Int, Int) -> Int }
        } follows: {
            BitwiseAnd()
        }
    }
}

struct BitwiseAnd: Parser {
    var body: some Parser<Substring.UTF8View, Int> {
        InfixOperator(associativity: .left) {
            "&".utf8.map { (&) as (Int, Int) -> Int }
        } follows: {
            Shifts()
        }
    }
}

struct Shifts: Parser {
    var body: some Parser<Substring.UTF8View, Int> {
        InfixOperator(associativity: .left) {
            OneOf {
                "<<".utf8.map { (<<) as (Int, Int) -> Int }
                ">>".utf8.map { (>>) }
            }
        } follows: {
            AdditionAndSubtraction()
        }
    }
}

struct AdditionAndSubtraction: Parser {
    var body: some Parser<Substring.UTF8View, Int> {
        InfixOperator(associativity: .left) {
            OneOf {
                "+".utf8.map { (+) as (Int, Int) -> Int }
                "-".utf8.map { (-) }
            }
        } follows: {
            MultiplicationAndDivision()
        }
    }
}

struct MultiplicationAndDivision: Parser {
    var body: some Parser<Substring.UTF8View, Int> {
        InfixOperator(associativity: .left) {
            OneOf {
                "*".utf8.map { (*) as (Int, Int) -> Int }
                "/".utf8.map { (/) }
                "%".utf8.map { (%) }
            }
        } follows: {
            Factor()
        }
    }
}

struct Factor: Parser {
    var body: some Parser<Substring.UTF8View, Int> {
        OneOf {
            Parse {
                Skip { Whitespace() }
                "(".utf8
                Skip { Whitespace() }
                ExpressionParser()
                Skip { Whitespace() }
                ")".utf8
                Skip { Whitespace() }
            }

            Parse {
                Skip { Whitespace() }
                Value()
                Skip { Whitespace() }
            }
        }
    }
}

public struct InfixOperator<Input, Operator: Parser, Operand: Parser>: Parser
    where
    Operator.Input == Input,
    Operand.Input == Input,
    Operator.Output == (Operand.Output, Operand.Output) -> Operand.Output
{
    public let associativity: Associativity
    public let operand: Operand
    public let `operator`: Operator

    @inlinable
    public init(
        associativity: Associativity,
        @ParserBuilder<Input> _ operator: () -> Operator,
        @ParserBuilder<Input> follows operand: () -> Operand
    ) {
        self.associativity = associativity
        self.operand = operand()
        self.operator = `operator`()
    }

    @inlinable
    public func parse(_ input: inout Input) rethrows -> Operand.Output {
        switch associativity {
        case .left:
            var lhs = try operand.parse(&input)
            var rest = input
            while true {
                do {
                    let operation = try self.operator.parse(&input)
                    let rhs = try operand.parse(&input)
                    rest = input
                    lhs = operation(lhs, rhs)
                } catch {
                    input = rest
                    return lhs
                }
            }
        case .right:
            var lhs: [(Operand.Output, Operator.Output)] = []
            while true {
                let rhs = try operand.parse(&input)
                do {
                    let operation = try self.operator.parse(&input)
                    lhs.append((rhs, operation))
                } catch {
                    return lhs.reversed().reduce(rhs) { rhs, pair in
                        let (lhs, operation) = pair
                        return operation(lhs, rhs)
                    }
                }
            }
        }
    }
}

public enum Associativity {
    case left
    case right
}

struct Value: Parser {
    var body: some Parser<Substring.UTF8View, Int> {
        OneOf {
            HexInt()
            BinaryInt()
            DecimalInt()
        }
    }
}

struct DecimalInt: Parser {
    var body: some Parser<Substring.UTF8View, Int> {
        Int.parser(radix: 10)
    }
}

struct HexInt: Parser {
    var body: some Parser<Substring.UTF8View, Int> {
        "0x".utf8
        Int.parser(radix: 16)
    }
}

struct BinaryInt: Parser {
    var body: some Parser<Substring.UTF8View, Int> {
        "0b".utf8
        Int.parser(radix: 2)
    }
}

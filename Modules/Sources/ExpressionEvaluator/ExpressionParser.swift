import Foundation
import Parsing

struct ExpressionParser<Output: FixedWidthInteger>: Parser {
    var body: some Parser<Substring.UTF8View, Output> {
        BitwiseOr<Output>()
    }
}

struct BitwiseOr<Output: FixedWidthInteger>: Parser {
    var body: some Parser<Substring.UTF8View, Output> {
        InfixOperator(associativity: .left) {
            "|".utf8.map { (|) as (Output, Output) -> Output }
        } follows: {
            BitwiseXor<Output>()
        }
    }
}

struct BitwiseXor<Output: FixedWidthInteger>: Parser {
    var body: some Parser<Substring.UTF8View, Output> {
        InfixOperator(associativity: .left) {
            "^".utf8.map { (^) as (Output, Output) -> Output }
        } follows: {
            BitwiseAnd<Output>()
        }
    }
}

struct BitwiseAnd<Output: FixedWidthInteger>: Parser {
    var body: some Parser<Substring.UTF8View, Output> {
        InfixOperator(associativity: .left) {
            "&".utf8.map { (&) as (Output, Output) -> Output }
        } follows: {
            Shifts<Output>()
        }
    }
}

struct Shifts<Output: FixedWidthInteger>: Parser {
    var body: some Parser<Substring.UTF8View, Output> {
        InfixOperator(associativity: .left) {
            OneOf {
                "<<".utf8.map { (<<) as (Output, Output) -> Output }
                ">>".utf8.map { (>>) }
            }
        } follows: {
            AdditionAndSubtraction<Output>()
        }
    }
}

struct AdditionAndSubtraction<Output: FixedWidthInteger>: Parser {
    var body: some Parser<Substring.UTF8View, Output> {
        InfixOperator(associativity: .left) {
            OneOf {
                "+".utf8.map { (+) as (Output, Output) -> Output }
                "-".utf8.map { (-) }
            }
        } follows: {
            MultiplicationAndDivision<Output>()
        }
    }
}

struct MultiplicationAndDivision<Output: FixedWidthInteger>: Parser {
    var body: some Parser<Substring.UTF8View, Output> {
        InfixOperator(associativity: .left) {
            OneOf {
                "*".utf8.map { (*) as (Output, Output) -> Output }
                "/".utf8.map { (/) }
                "%".utf8.map { (%) }
            }
        } follows: {
            Factor<Output>()
        }
    }
}

struct Factor<Output: FixedWidthInteger>: Parser {
    var body: some Parser<Substring.UTF8View, Output> {
        OneOf {
            Parse {
                Skip { Whitespace() }
                "(".utf8
                Skip { Whitespace() }
                ExpressionParser<Output>()
                Skip { Whitespace() }
                ")".utf8
                Skip { Whitespace() }
            }

            Parse {
                Skip { Whitespace() }
                Value<Output>()
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

struct Value<Output: FixedWidthInteger>: Parser {
    var body: some Parser<Substring.UTF8View, Output> {
        OneOf {
            HexInt<Output>()
            BinaryInt<Output>()
            DecimalInt<Output>()
        }
    }
}

struct DecimalInt<Output: FixedWidthInteger>: Parser {
    var body: some Parser<Substring.UTF8View, Output> {
        Output.parser(radix: 10)
    }
}

struct HexInt<Output: FixedWidthInteger>: Parser {
    var body: some Parser<Substring.UTF8View, Output> {
        "0x".utf8
        Output.parser(radix: 16)
    }
}

struct BinaryInt<Output: FixedWidthInteger>: Parser {
    var body: some Parser<Substring.UTF8View, Output> {
        "0b".utf8
        Output.parser(radix: 2)
    }
}

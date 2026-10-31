protocol SchemeLib {
    var lib: [NativeProcedure] { get }
}

struct SchemeStdlib: SchemeLib {
    var lib: [NativeProcedure] {
        [plus, multiply, subtract, lessThan, car, cdr, null]
    }

    private let plus = NativeProcedure(
        name: "+",
        params: [],
        remainingParams: "xs",
        invoke: { env in
            var sum = 0
            if var list = try env.value(name: "xs").value {
                while case .pair(let car, let cdr) = list {
                    guard case .number(let number) = car else {
                        throw SchemeRuntimeError.expectedNumber(procedure: "+")
                    }
                    sum += number
                    list = cdr
                }
            }
            return .number(value: sum)
        }
    )

    private let multiply = NativeProcedure(
        name: "*",
        params: [],
        remainingParams: "xs",
        invoke: { env in
            var product = 1
            if var list = try env.value(name: "xs").value {
                while case .pair(let car, let cdr) = list {
                    guard case .number(let number) = car else {
                        throw SchemeRuntimeError.expectedNumber(procedure: "*")
                    }
                    product *= number
                    list = cdr
                }
            }
            return .number(value: product)
        }
    )

    private let subtract = NativeProcedure(
        name: "-",
        params: [],
        remainingParams: "xs",
        invoke: { env in
            guard var list = try env.value(name: "xs").value,
                  case .pair(let first, let rest) = list else {
                throw SchemeRuntimeError.incorrectArgumentCount(
                    procedure: "-",
                    expected: "at least 1",
                    actual: 0
                )
            }
            guard case .number(let firstNumber) = first else {
                throw SchemeRuntimeError.expectedNumber(procedure: "-")
            }
            var result = firstNumber
            var hasSubsequentOperand = false
            list = rest
            while case .pair(let car, let cdr) = list {
                guard case .number(let number) = car else {
                    throw SchemeRuntimeError.expectedNumber(procedure: "-")
                }
                result -= number
                hasSubsequentOperand = true
                list = cdr
            }
            if !hasSubsequentOperand {
                result = -result
            }
            return .number(value: result)
        }
    )

    private let lessThan = NativeProcedure(
        name: "<",
        params: [],
        remainingParams: "xs",
        invoke: { env in
            guard var list = try env.value(name: "xs").value,
                  case .pair(let first, let rest) = list else {
                throw SchemeRuntimeError.incorrectArgumentCount(
                    procedure: "<",
                    expected: "at least 2",
                    actual: 0
                )
            }
            guard case .pair = rest else {
                throw SchemeRuntimeError.incorrectArgumentCount(
                    procedure: "<",
                    expected: "at least 2",
                    actual: 1
                )
            }
            guard case .number(let previous) = first else {
                throw SchemeRuntimeError.expectedNumber(procedure: "<")
            }

            list = rest
            var previousNumber = previous
            while case .pair(let car, let cdr) = list {
                guard case .number(let number) = car else {
                    throw SchemeRuntimeError.expectedNumber(procedure: "<")
                }
                if previousNumber >= number {
                    return .boolean(value: false)
                }
                previousNumber = number
                list = cdr
            }
            return .boolean(value: true)
        }
    )

    private let car = NativeProcedure(
        name: "car",
        params: ["pair"],
        remainingParams: nil,
        invoke: { env in
            guard case .pair(let car, _) = try env.value(name: "pair").value else {
                throw SchemeRuntimeError.expectedPair(procedure: "car")
            }
            return car
        }
    )

    private let cdr = NativeProcedure(
        name: "cdr",
        params: ["pair"],
        remainingParams: nil,
        invoke: { env in
            guard case .pair(_, let cdr) = try env.value(name: "pair").value else {
                throw SchemeRuntimeError.expectedPair(procedure: "cdr")
            }
            return cdr
        }
    )

    private let null = NativeProcedure(
        name: "null?",
        params: ["value"],
        remainingParams: nil,
        invoke: { env in
            if case .emptyList = try env.value(name: "value").value {
                return .boolean(value: true)
            }
            return .boolean(value: false)
        }
    )
}

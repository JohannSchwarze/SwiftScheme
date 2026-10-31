



import Foundation


public enum SchemeRuntimeError: LocalizedError {
    case expectedNumber(procedure: String)
    case expectedPair(procedure: String)
    case expectedProcedure
    case incorrectArgumentCount(procedure: String, expected: String, actual: Int)
    case uninitializedVariable(name: String)
    case invalidDefinition
    case emptyProcedureBody

    public var errorDescription: String? {
        switch self {
        case .expectedNumber(let procedure):
            "Expected a number in procedure \(procedure)"
        case .expectedPair(let procedure):
            "Expected a pair in procedure \(procedure)"
        case .expectedProcedure:
            "Expected a procedure"
        case .incorrectArgumentCount(let procedure, let expected, let actual):
            "Procedure \(procedure) expected \(expected) arguments, received \(actual)"
        case .uninitializedVariable(let name):
            "Variable \(name) was used before it was initialized"
        case .invalidDefinition:
            "Definition must define a variable"
        case .emptyProcedureBody:
            "Procedure body must not be empty"
        }
    }
}

struct SchemeRuntime {
    var environment: SchemeEnvironment<SchemeEnvironmentLocation<SchemeValue>>





    func print(value: SchemeValue) -> String {
        switch value {
        case .boolean(let value):
            return value ? "#t" : "#f"
        case .number(let value):
            return String(value)
        case .emptyList:
            return "'()"
        case .symbol(let value):
            return "'\(value)"
        case .pair(let car, let cdr):
            return "(cons \(print(value: car)) \(print(value: cdr)))"
        case .procedure(_, _, _, _):
            return "#procedure"
        case .nativeProcedure(_, _):
            return "#nativeProcedure"
        }
    }




    func eqv(e1: SchemeValue, e2: SchemeValue) -> Bool {
        return true
    }




    mutating func loadLibrary(_ lib: SchemeLib) throws {
        for value in lib.lib {
            environment.bind(
                name: value.name,
                value: SchemeEnvironmentLocation(
                    value: .nativeProcedure(env: environment, callable: value)
                )
            )
        }
    }


    mutating func loadProgram(program: Program) throws {
        for definition in program.definitions {
            guard case .variable(let name) = definition.variable.kind else {
                throw SchemeRuntimeError.invalidDefinition
            }
            let location = SchemeEnvironmentLocation<SchemeValue>(value: nil)
            environment.bind(name: name, value: location)
            let value = try evaluate(expr: definition.expr, env: environment)
            location.value = value
        }
    }


    func evaluate(datum: Datum) throws -> SchemeValue {
        switch datum.kind {
        case .boolean(let value):
            return .boolean(value: value)
        case .number(let value):
            return .number(value: value)
        case .symbol(let value):
            return .symbol(value: value)
        case .list(let value):
            var result: SchemeValue = .emptyList
            for datum in value.reversed() {
                let datumValue = try evaluate(datum: datum)
                result = .pair(car: datumValue, cdr: result)
            }
            return result
        }
    }


    func evaluate(_ str: String, env: SchemeEnvironment<SchemeEnvironmentLocation<SchemeValue>>) throws -> SchemeValue {
        var parser = Parser(lexer: Lexer(data: str))
        let expr = try parser.parseExpression()
        return try evaluate(expr: expr, env: env)
    }

    func evaluate(expr: Expr, env: SchemeEnvironment<SchemeEnvironmentLocation<SchemeValue>>) throws -> SchemeValue {
        switch expr.kind {
        case .boolean(let value):
            return .boolean(value: value)

        case .number(let value):
            return .number(value: value)

        case .asssignment(let variable, let expr):
            let location = try env.value(name: variable)
            let value = try evaluate(expr: expr, env: env)
            location.value = value
            return value

        case .conditional(let test, let consequence, let alternate):
            let testValue = try evaluate(expr: test, env: env)
            if case .boolean(false) = testValue {
                if let alternate {
                    return try evaluate(expr: alternate, env: env)
                } else {
                    return .emptyList
                }
            } else {
                return try evaluate(expr: consequence, env: env)
            }
        
        case .variable(let name):
            let location = try env.value(name: name)
            guard let value = location.value else {
                throw SchemeRuntimeError.uninitializedVariable(name: name)
            }
            return value
        
        case .quotation(let datum):
            return try evaluate(datum: datum)

        case .procedureCall(let op, let operands):
            let proc = try evaluate(expr: op, env: env)

            if case .procedure(var procEnv, let params, let remainingParams, let body) = proc {
                if remainingParams == nil, operands.count != params.count {
                    throw SchemeRuntimeError.incorrectArgumentCount(
                        procedure: "procedure",
                        expected: "\(params.count)",
                        actual: operands.count
                    )
                }
                if remainingParams != nil, operands.count < params.count {
                    throw SchemeRuntimeError.incorrectArgumentCount(
                        procedure: "procedure",
                        expected: "at least \(params.count)",
                        actual: operands.count
                    )
                }
                procEnv.pushRegion()
                defer {
                    procEnv.popRegion()
                }
                for (operand, param) in zip(operands, params) {
                    let location = SchemeEnvironmentLocation<SchemeValue>(value: nil)
                    procEnv.bind(name: param, value: location)
                    let operandValue = try evaluate(expr: operand, env: env)
                    location.value = operandValue
                }

                let remainingOperandsCount = max(0, operands.count - params.count)
                if let remainingParams {
                    let location = SchemeEnvironmentLocation<SchemeValue>(value: nil)
                    procEnv.bind(name: remainingParams, value: location)

                    var remainingOperandsValue = SchemeValue.emptyList
                    for i in 0..<remainingOperandsCount {
                        let k = operands.count - i - 1
                        let operandValue = try evaluate(expr: operands[k], env: env)
                        remainingOperandsValue = .pair(car: operandValue, cdr: remainingOperandsValue)
                    }

                    location.value = remainingOperandsValue
                }

                var last: SchemeValue? = nil
                for expr in body {
                    last = try evaluate(expr: expr, env: procEnv)
                }
                guard let last else { throw SchemeRuntimeError.emptyProcedureBody }
                return last

            } else if case .nativeProcedure(var procEnv, let callable) = proc {
                let params = callable.params
                let remainingParams = callable.remainingParams
                if remainingParams == nil, operands.count != params.count {
                    throw SchemeRuntimeError.incorrectArgumentCount(
                        procedure: callable.name,
                        expected: "\(params.count)",
                        actual: operands.count
                    )
                }
                if remainingParams != nil, operands.count < params.count {
                    throw SchemeRuntimeError.incorrectArgumentCount(
                        procedure: callable.name,
                        expected: "at least \(params.count)",
                        actual: operands.count
                    )
                }
                procEnv.pushRegion()
                defer {
                    procEnv.popRegion()
                }
                for (operand, param) in zip(operands, params) {
                    let location = SchemeEnvironmentLocation<SchemeValue>(value: nil)
                    procEnv.bind(name: param, value: location)
                    let operandValue = try evaluate(expr: operand, env: env)
                    location.value = operandValue
                }

                let remainingOperandsCount = max(0, operands.count - params.count)
                if let remainingParams {
                    let location = SchemeEnvironmentLocation<SchemeValue>(value: nil)
                    procEnv.bind(name: remainingParams, value: location)

                    var remainingOperandsValue = SchemeValue.emptyList
                    for i in 0..<remainingOperandsCount {
                        let k = operands.count - i - 1
                        let operandValue = try evaluate(expr: operands[k], env: env)
                        remainingOperandsValue = .pair(car: operandValue, cdr: remainingOperandsValue)
                    }

                    location.value = remainingOperandsValue
                }

                let result = try callable.invoke(procEnv)
                return result
            } else {
                throw SchemeRuntimeError.expectedProcedure
            }

        case .procedure(let params, let remainingParams, let body):
            return .procedure(env: env, params: params, remainingParams: remainingParams, body: body)
        }
    }
}




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
        case .nativeProcedure(_, _, _):
            return "#nativeProcedure"
        }
    }




    func eqv(e1: SchemeValue, e2: SchemeValue) -> Bool {
        return true
    }




    mutating func loadNativeProcedures() throws {
        environment.bind(
            name: "+", 
            value: SchemeEnvironmentLocation(value: .nativeProcedure(
                env: SchemeEnvironment<SchemeEnvironmentLocation<SchemeValue>>(), 
                params: ["a", "b"], 
                callable: NativeProcedure(
                    name: "+", 
                    arity: 2,
                    invoke: { values in
            guard case .number(let a) = values[0] else {
                throw ParserError.init(pos: 0, kind: .unexpectedEOF)
            }
            guard case .number(let b) = values[1] else {
                throw ParserError.init(pos: 0, kind: .unexpectedEOF)
            }
            return .number(value: a + b)
        }))))

        environment.bind(
            name: "*",
            value: SchemeEnvironmentLocation(value: .nativeProcedure(
                env: SchemeEnvironment<SchemeEnvironmentLocation<SchemeValue>>(),
                params: ["a", "b"],
                callable: NativeProcedure(
                    name: "*",
                    arity: 2,
                    invoke: { values in
                        guard case .number(let a) = values[0] else {
                            throw ParserError.init(pos: 0, kind: .unexpectedEOF)
                        }
                        guard case .number(let b) = values[1] else {
                            throw ParserError.init(pos: 0, kind: .unexpectedEOF)
                        }
                        return .number(value: a * b)
                    }))))

        environment.bind(
            name: "-",
            value: SchemeEnvironmentLocation(value: .nativeProcedure(
                env: SchemeEnvironment<SchemeEnvironmentLocation<SchemeValue>>(),
                params: ["a", "b"],
                callable: NativeProcedure(
                    name: "-",
                    arity: 2,
                    invoke: { values in
                        guard case .number(let a) = values[0] else {
                            throw ParserError.init(pos: 0, kind: .unexpectedEOF)
                        }
                        guard case .number(let b) = values[1] else {
                            throw ParserError.init(pos: 0, kind: .unexpectedEOF)
                        }
                        return .number(value: a - b)
                    }))))

        environment.bind(
            name: "<",
            value: SchemeEnvironmentLocation(value: .nativeProcedure(
                env: SchemeEnvironment<SchemeEnvironmentLocation<SchemeValue>>(),
                params: ["a", "b"],
                callable: NativeProcedure(
                    name: "<",
                    arity: 2,
                    invoke: { values in
                        guard case .number(let a) = values[0] else {
                            throw ParserError.init(pos: 0, kind: .unexpectedEOF)
                        }
                        guard case .number(let b) = values[1] else {
                            throw ParserError.init(pos: 0, kind: .unexpectedEOF)
                        }
                        return .boolean(value: a < b)
                    }))))
    }


    mutating func loadProgram(program: Program) throws {
        for definition in program.definitions {
            guard case .variable(let name) = definition.variable.kind else {
                throw ParserError.init(pos: 0, kind: .unexpectedEOF)
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
            guard let value = location.value else { throw SchemeEnvironmentError.unboundVariable(name: name) }
            return value
        
        case .quotation(let datum):
            return try evaluate(datum: datum)

        case .procedureCall(let op, let operands):
            let proc = try evaluate(expr: op, env: env)

            if case .procedure(var procEnv, let params, let remainingParams, let body) = proc {
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

                let remainingOperandsCount = min(0, operands.count - params.count)
                if let remainingParams {
                    let location = SchemeEnvironmentLocation<SchemeValue>(value: nil)
                    procEnv.bind(name: remainingParams, value: location)

                    var remainingOperandsValue = SchemeValue.emptyList
                    for i in 0..<remainingOperandsCount {
                        let k = operands.count - i - 1
                        let operandValue = try evaluate(expr: operands[i], env: env)
                        remainingOperandsValue = .pair(car: operandValue, cdr: remainingOperandsValue)
                    }

                    location.value = remainingOperandsValue
                }

                var last: SchemeValue? = nil
                for expr in body {
                    last = try evaluate(expr: expr, env: procEnv)
                }
                return last!

            } else if case .nativeProcedure(var procEnv, let params, let callable) = proc {
                procEnv.pushRegion()
                defer {
                    procEnv.popRegion()
                }
                var operandValues: [SchemeValue] = []
                for (operand, param) in zip(operands, params) {
                    let location = SchemeEnvironmentLocation<SchemeValue>(value: nil)
                    procEnv.bind(name: param, value: location)
                    let operandValue = try evaluate(expr: operand, env: env)
                    location.value = operandValue
                    operandValues.append(operandValue)
                }

                let result = try callable.invoke(operandValues)
                return result
            } else {
                throw ParserError.init(pos: 0, kind: .unexpectedEOF)
            }

        case .procedure(let params, let remainingParams, let body):
            return .procedure(env: env, params: params, remainingParams: remainingParams, body: body)
        }
    }
}




struct SchemeRuntime {
    var environment: SchemeEnvironment<SchemeValue>





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
        case .procedure(let env, let params, let body):
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
            value: .nativeProcedure(
                env: SchemeEnvironment(), 
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
        })))

        environment.bind(
            name: "*",
            value: .nativeProcedure(
                env: SchemeEnvironment(),
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
                    })))

        environment.bind(
            name: "-",
            value: .nativeProcedure(
                env: SchemeEnvironment(),
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
                    })))

        environment.bind(
            name: "<",
            value: .nativeProcedure(
                env: SchemeEnvironment(),
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
                    })))
    }


    mutating func loadProgram(program: Program) throws {
        for definition in program.definitions {
            guard case .variable(let name) = definition.variable.kind else {
                throw ParserError.init(pos: 0, kind: .unexpectedEOF)
            }
            let value = try evaluate(expr: definition.expr, env: environment)
            environment.bind(name: name, value: value)
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


    func evaluate(_ str: String, env: SchemeEnvironment<SchemeValue>) throws -> SchemeValue {
        var parser = Parser(lexer: Lexer(data: str))
        let expr = try parser.parseExpression()
        return try evaluate(expr: expr, env: env)
    }

    func evaluate(expr: Expr, env: SchemeEnvironment<SchemeValue>) throws -> SchemeValue {
        switch expr.kind {
        case .boolean(let value):
            return .boolean(value: value)

        case .number(let value):
            return .number(value: value)

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
            return try env.value(name: name)
        
        case .quotation(let datum):
            return try evaluate(datum: datum)

        case .procedureCall(let op, let operands):
            let proc = try evaluate(expr: op, env: env)

            if case .procedure(var procEnv, let params, let body) = proc {
                procEnv.pushRegion()
                defer {
                    procEnv.popRegion()
                }
                for (operand, param) in zip(operands, params) {
                    let operandValue = try evaluate(expr: operand, env: env)
                    procEnv.bind(name: param, value: operandValue)
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
                    let operandValue = try evaluate(expr: operand, env: env)
                    operandValues.append(operandValue)
                    procEnv.bind(name: param, value: operandValue)
                }

                let result = try callable.invoke(operandValues)
                return result
            } else {
                throw ParserError.init(pos: 0, kind: .unexpectedEOF)
            }

        case .procedure(let params, let body):
            return .procedure(env: env, params: params, body: body)
        }
    }
}
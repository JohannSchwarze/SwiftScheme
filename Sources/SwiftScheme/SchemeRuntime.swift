



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
        case .nativeProcedure(_, _, _, _):
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
                params: [],
                remainingParams: "xs", 
                callable: NativeProcedure(
                    name: "+", 
                    arity: nil,
                    invoke: { env in

                    var sum: Int = 0
                    if var list = try env.value(name: "xs").value {
                        while case .pair(let car, let cdr) = list {
                            guard case .number(let num) = car else {
                                throw ParserError.init(pos: 0, kind: .unexpectedEOF)
                            }
                            sum += num
                            list = cdr
                        }
                    }
                    return .number(value: sum)
        }))))

        environment.bind(
            name: "*",
            value: SchemeEnvironmentLocation(value: .nativeProcedure(
                env: SchemeEnvironment<SchemeEnvironmentLocation<SchemeValue>>(),
                params: [],
                remainingParams: "xs",
                callable: NativeProcedure(
                    name: "*",
                    arity: nil,
                    invoke: { env in
                        var product = 1
                        if var list = try env.value(name: "xs").value {
                            while case .pair(let car, let cdr) = list {
                                guard case .number(let num) = car else {
                                    throw ParserError.init(pos: 0, kind: .unexpectedEOF)
                                }
                                product *= num
                                list = cdr
                            }
                        }
                        return .number(value: product)
                    }))))

        environment.bind(
            name: "-",
            value: SchemeEnvironmentLocation(value: .nativeProcedure(
                env: SchemeEnvironment<SchemeEnvironmentLocation<SchemeValue>>(),
                params: [],
                remainingParams: "xs",
                callable: NativeProcedure(
                    name: "-",
                    arity: nil,
                    invoke: { env in
                        guard var list = try env.value(name: "xs").value,
                              case .pair(let first, let rest) = list,
                              case .number(let firstNumber) = first else {
                            throw ParserError.init(pos: 0, kind: .unexpectedEOF)
                        }
                        var result = firstNumber
                        var hasSubsequentOperand = false
                        list = rest
                        while case .pair(let car, let cdr) = list {
                            guard case .number(let num) = car else {
                                throw ParserError.init(pos: 0, kind: .unexpectedEOF)
                            }
                            result -= num
                            hasSubsequentOperand = true
                            list = cdr
                        }
                        if !hasSubsequentOperand {
                            result = -result
                        }
                        return .number(value: result)
                    }))))

        environment.bind(
            name: "<",
            value: SchemeEnvironmentLocation(value: .nativeProcedure(
                env: SchemeEnvironment<SchemeEnvironmentLocation<SchemeValue>>(),
                params: [],
                remainingParams: "xs",
                callable: NativeProcedure(
                    name: "<",
                    arity: nil,
                    invoke: { env in
                        guard var list = try env.value(name: "xs").value,
                              case .pair(let first, let rest) = list,
                              case .number(let previous) = first,
                              case .pair = rest else {
                            throw ParserError.init(pos: 0, kind: .unexpectedEOF)
                        }

                        list = rest
                        var previousNumber = previous
                        while case .pair(let car, let cdr) = list {
                            guard case .number(let num) = car else {
                                throw ParserError.init(pos: 0, kind: .unexpectedEOF)
                            }
                            if previousNumber >= num {
                                return .boolean(value: false)
                            }
                            previousNumber = num
                            list = cdr
                        }
                        return .boolean(value: true)
                    }))))

        environment.bind(
            name: "car",
            value: SchemeEnvironmentLocation(value: .nativeProcedure(
                env: SchemeEnvironment<SchemeEnvironmentLocation<SchemeValue>>(),
                params: ["pair"],
                remainingParams: nil,
                callable: NativeProcedure(
                    name: "car",
                    arity: 1,
                    invoke: { env in
                        guard case .pair(let car, _) = try env.value(name: "pair").value else {
                            throw ParserError.init(pos: 0, kind: .unexpectedEOF)
                        }
                        return car
                    }))))

        environment.bind(
            name: "cdr",
            value: SchemeEnvironmentLocation(value: .nativeProcedure(
                env: SchemeEnvironment<SchemeEnvironmentLocation<SchemeValue>>(),
                params: ["pair"],
                remainingParams: nil,
                callable: NativeProcedure(
                    name: "cdr",
                    arity: 1,
                    invoke: { env in
                        guard case .pair(_, let cdr) = try env.value(name: "pair").value else {
                            throw ParserError.init(pos: 0, kind: .unexpectedEOF)
                        }
                        return cdr
                    }))))

        environment.bind(
            name: "null?",
            value: SchemeEnvironmentLocation(value: .nativeProcedure(
                env: SchemeEnvironment<SchemeEnvironmentLocation<SchemeValue>>(),
                params: ["value"],
                remainingParams: nil,
                callable: NativeProcedure(
                    name: "null?",
                    arity: 1,
                    invoke: { env in
                        if case .emptyList = try env.value(name: "value").value {
                            return .boolean(value: true)
                        }
                        return .boolean(value: false)
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
                return last!

            } else if case .nativeProcedure(var procEnv, let params, let remainingParams, let callable) = proc {
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
                throw ParserError.init(pos: 0, kind: .unexpectedEOF)
            }

        case .procedure(let params, let remainingParams, let body):
            return .procedure(env: env, params: params, remainingParams: remainingParams, body: body)
        }
    }
}
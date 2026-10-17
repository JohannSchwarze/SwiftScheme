




enum ParserErrorKind: Error {
    case unexpectedEOF
    case unsupportedVariableName
    case unexpectedTokenKind(exp: TokenValue, act: TokenValue)
}

struct ParserError: Error {
    let pos: Int
    let kind: ParserErrorKind
}












struct Parser {
    var lexer: Lexer






    mutating func parseProgram() throws -> Program {
        var defs: [Definition] = []
        while let token = try lexer.peek() {
            let def = try parseDefinition()
            defs.append(def)
        }
        return Program(definitions: defs)
    }


    mutating func parseDefinition() throws -> Definition {
        guard let lparenToken = try lexer.next() else { 
            throw ParserError(pos: lexer.pos, kind: .unexpectedEOF) 
        }
        guard case .lparen = lparenToken.value else { 
            throw ParserError(pos: lparenToken.start, kind: .unexpectedTokenKind(exp: .lparen, act: lparenToken.value)) 
        }

        guard let defKeywordToken = try lexer.next() else {
            throw ParserError(pos: lexer.pos, kind: .unexpectedEOF) 
        }
        guard case .identifier("define") = defKeywordToken.value else {
            throw ParserError(pos: lparenToken.start, kind: .unexpectedTokenKind(exp: .identifier(name: "define"), act: lparenToken.value)) 
        }

        let variable = try self.parseVariable()
        let expr = try self.parseExpression()

        guard let rparenToken = try lexer.next() else { 
            throw ParserError(pos: lexer.pos, kind: .unexpectedEOF) 
        }
        guard case .rparen = rparenToken.value else { 
            throw ParserError(pos: rparenToken.start, kind: .unexpectedTokenKind(exp: .rparen, act: rparenToken.value)) 
        }

        return Definition(variable: variable, expr: expr, start: lparenToken.start, end: rparenToken.end)
    }


    mutating func parseExpression() throws -> Expr {
        let token = try lexer.peek()

        if let token, case .boolean(let value) = token.value {
            let _ = try lexer.next()
            return Expr(start: token.start, end: token.end, kind: .boolean(value))
        }

        if let token, case .number(let value) = token.value {
            let _ = try lexer.next()
            return Expr(start: token.start, end: token.end, kind: .number(value))
        }

        if let token, case .quoteAbbr = token.value {
            let _ = try lexer.next()
            let datum = try self.parseDatum()
            return Expr(start: token.start, end: datum.end, kind: .quotation(datum))
        }

        if let token, case .lparen = token.value {
            if let ifToken = try lexer.peek2(), ifToken.value == .identifier(name: "if") {
                return try parseConditional()
            } else if let lambdaToken = try lexer.peek2(), lambdaToken.value == .identifier(name: "lambda") {
                return try parseProcedure()
            } else {
                return try parseProcedureCall()
            }
        }

        if let token, case .identifier(let name) = token.value {
            let _ = try lexer.next()
            return Expr(start: token.start, end: token.end, kind: .variable(name))
        }

        throw ParserError(pos: 0, kind: .unexpectedEOF)
    }

    mutating func parseProcedure() throws -> Expr {
        guard let lparenToken = try lexer.next() else { 
            throw ParserError(pos: lexer.pos, kind: .unexpectedEOF) 
        }
        guard case .lparen = lparenToken.value else { 
            throw ParserError(pos: lparenToken.start, kind: .unexpectedTokenKind(exp: .lparen, act: lparenToken.value)) 
        }

        guard let lambdaToken = try lexer.next() else { throw ParserError(pos: lparenToken.end, kind: .unexpectedEOF) }
        guard case .identifier("lambda") = lambdaToken.value else { throw ParserError(pos: lambdaToken.start, kind: .unexpectedTokenKind(exp: .identifier(name: "lambda"), act: lambdaToken.value)) }

        let params = try parseFormals()

        var body: [Expr] = []
        while let token = try lexer.peek(), token.value != .rparen {
            let expr = try parseExpression()
            body.append(expr)
        }

        guard let rparenToken = try lexer.next() else { 
            throw ParserError(pos: lexer.pos, kind: .unexpectedEOF) 
        }
        guard case .rparen = rparenToken.value else { 
            throw ParserError(pos: rparenToken.start, kind: .unexpectedTokenKind(exp: .rparen, act: rparenToken.value)) 
        }

        return Expr(start: lparenToken.start, end: rparenToken.end, kind: .procedure(params: params, body: body))
    }

    mutating func parseFormals() throws -> [String] {
        guard let lparenToken = try lexer.next() else { 
            throw ParserError(pos: lexer.pos, kind: .unexpectedEOF) 
        }
        guard case .lparen = lparenToken.value else { 
            throw ParserError(pos: lparenToken.start, kind: .unexpectedTokenKind(exp: .lparen, act: lparenToken.value)) 
        }

        var params: [String] = []
        while let token = try lexer.peek(), token.value != .rparen {
            let variable = try parseVariable()
            guard case .variable(let name) = variable.kind else {
                throw ParserError(pos: lexer.pos, kind: .unexpectedEOF) 
            }
            params.append(name)
        }

        guard let rparenToken = try lexer.next() else { 
            throw ParserError(pos: lexer.pos, kind: .unexpectedEOF) 
        }
        guard case .rparen = rparenToken.value else { 
            throw ParserError(pos: rparenToken.start, kind: .unexpectedTokenKind(exp: .rparen, act: rparenToken.value)) 
        }

        return params
    }

    mutating func parseConditional() throws -> Expr {
        guard let lparenToken = try lexer.next() else { throw ParserError(pos: 0, kind: .unexpectedEOF) }
        guard case .lparen = lparenToken.value else { throw ParserError(pos: lparenToken.start, kind: .unexpectedTokenKind(exp: .lparen, act: lparenToken.value)) }

        guard let ifToken = try lexer.next() else { throw ParserError(pos: lparenToken.end, kind: .unexpectedEOF) }
        guard case .identifier("if") = ifToken.value else { throw ParserError(pos: ifToken.start, kind: .unexpectedTokenKind(exp: .identifier(name: "if"), act: ifToken.value)) }

        let test = try self.parseExpression()
        let consequence = try self.parseExpression()
        
        guard let nextToken = try lexer.peek() else { throw ParserError(pos: 0, kind: .unexpectedEOF) }
        var alternate: Expr? = nil
        if nextToken.value != .rparen {
            alternate = try self.parseExpression()
        }

        guard let rparenToken = try lexer.next() else { throw ParserError(pos: 0, kind: .unexpectedEOF) }
        guard case .rparen = rparenToken.value else { throw ParserError(pos: 0, kind: .unexpectedEOF) }

        return Expr(start: lparenToken.start, end: rparenToken.end, kind: .conditional(test: test, consequence: consequence, alternate: alternate))
    }

    mutating func parseProcedureCall() throws -> Expr {
        guard let lparenToken = try lexer.next() else { throw ParserError(pos: 0, kind: .unexpectedEOF) }
        guard case .lparen = lparenToken.value else { throw ParserError(pos: 0, kind: .unexpectedEOF) }

        let op = try self.parseExpression()

        var operands: [Expr] = []
        while let token = try lexer.peek(), token.value != .rparen {
            let operand = try self.parseExpression()
            operands.append(operand)
        }

        guard let rparenToken = try lexer.next() else { throw ParserError(pos: 0, kind: .unexpectedEOF) }
        guard case .rparen = rparenToken.value else { throw ParserError(pos: 0, kind: .unexpectedEOF) }
        return Expr(start: lparenToken.start, end: rparenToken.end, kind: .procedureCall(operator: op, operands: operands))
    }

    mutating func parseVariable() throws -> Expr {
        guard let idToken = try lexer.next() else { 
            throw ParserError(pos: lexer.pos, kind: .unexpectedEOF)
        }
        guard case .identifier(let id) = idToken.value else { 
            throw ParserError(pos: idToken.start, kind: .unexpectedTokenKind(exp: .identifier(name: ""), act: idToken.value))
        }
        guard !isSyntacticKeyword(id) else {
            throw ParserError(pos: idToken.start, kind: .unsupportedVariableName)
        }

        return Expr(start: idToken.start, end: idToken.end, kind: .variable(id))
    }

    mutating func parseDatum() throws -> Datum {
        let token = try lexer.peek()

        if let token, case .boolean(let value) = token.value {
            let _ = try lexer.next()
            return Datum(start: token.start, end: token.end, kind: .boolean(value: value))
        }

        if let token, case .number(let value) = token.value {
            let _ = try lexer.next()
            return Datum(start: token.start, end: token.end, kind: .number(value: value))
        }

        if let token, case .identifier(let name) = token.value {
            let _ = try lexer.next()
            return Datum(start: token.start, end: token.end, kind: .symbol(value: name))
        }

        if let token, case .lparen = token.value {
            let list = try parseDatumList()
            return list
        }
        
        throw ParserError(pos: lexer.pos, kind: .unexpectedEOF)
    }


    mutating func parseDatumList() throws -> Datum {
        guard let lparenToken = try lexer.next() else { 
            throw ParserError(pos: lexer.pos, kind: .unexpectedEOF) 
        }
        guard case .lparen = lparenToken.value else { 
            throw ParserError(pos: lparenToken.start, kind: .unexpectedTokenKind(exp: .lparen, act: lparenToken.value)) 
        }

        var elements: [Datum] = []
        while let token = try lexer.peek(), token.value != .rparen {
            let datum = try parseDatum()
            elements.append(datum)
        }

        guard let rparenToken = try lexer.next() else { 
            throw ParserError(pos: lexer.pos, kind: .unexpectedEOF) 
        }
        guard case .rparen = rparenToken.value else { 
            throw ParserError(pos: rparenToken.start, kind: .unexpectedTokenKind(exp: .rparen, act: rparenToken.value)) 
        }

        return Datum(start: lparenToken.start, end: rparenToken.end, kind: .list(value: elements))
    }











    private func isSyntacticKeyword(_ str: String) -> Bool {
        return str == "if" ||
                str == "lambda" ||
                str == "define"
    }
}





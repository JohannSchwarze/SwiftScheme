




enum ParserErrorKind: Error {
    case unexpectedEOF
    case unexpectedTokenKind(exp: TokenValue, act: TokenValue)
}

struct ParserError: Error {
    let pos: Int
    let kind: ParserErrorKind
}












struct Parser {
    var lexer: Lexer






    mutating func parseExpression() throws -> Expr? {
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
            } else {
                return try parseProcedureCall()
            }
        }

        if let token, case .identifier(let name) = token.value {
            let _ = try lexer.next()
            return Expr(start: token.start, end: token.end, kind: .variable(name))
        }

        return nil
    }

    mutating func parseConditional() throws -> Expr {
        guard let lparenToken = try lexer.next() else { throw ParserError(pos: 0, kind: .unexpectedEOF) }
        guard case .lparen = lparenToken.value else { throw ParserError(pos: lparenToken.start, kind: .unexpectedTokenKind(exp: .lparen, act: lparenToken.value)) }

        guard let ifToken = try lexer.next() else { throw ParserError(pos: lparenToken.end, kind: .unexpectedEOF) }
        guard case .identifier("if") = ifToken.value else { throw ParserError(pos: ifToken.start, kind: .unexpectedTokenKind(exp: .identifier(name: "if"), act: ifToken.value)) }

        guard let test = try self.parseExpression() else { throw ParserError(pos: 0, kind: .unexpectedEOF) }
        guard let consequence = try self.parseExpression() else { throw ParserError(pos: 0, kind: .unexpectedEOF) }
        
        guard let nextToken = try lexer.peek() else { throw ParserError(pos: 0, kind: .unexpectedEOF) }
        var alternate: Expr? = nil
        if nextToken.value != .rparen {
            alternate = try self.parseExpression()
        }

        guard let rparenToken = try lexer.next() else { throw ParserError(pos: 0, kind: .unexpectedEOF) }
        guard case .rparen = rparenToken.value else { throw ParserError(pos: 0, kind: .unexpectedEOF) }

        return Expr(start: lparenToken.start, end: rparenToken.end, kind: .conditional(test: test, consequence: consequence, alternate: alternate))
    }

    mutating func parseProcedureCall() throws -> Expr? {
        guard let lparenToken = try lexer.next() else { return nil }
        guard case .lparen = lparenToken.value else { return nil }

        guard let op = try self.parseExpression() else { return nil }

        var operands: [Expr] = []
        while let token = try lexer.peek(), token.value != .rparen {
            guard let operand = try self.parseExpression() else { return nil }
            operands.append(operand)
        }

        guard let rparenToken = try lexer.next() else { return nil }
        guard case .rparen = rparenToken.value else { return nil }
        return Expr(start: lparenToken.start, end: rparenToken.end, kind: .procedureCall(operator: op, operands: operands))
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
        
        throw ParserError(pos: 0, kind: .unexpectedEOF)
    }


    mutating func parseDatumList() throws -> Datum {
        guard let lparenToken = try lexer.next() else { throw ParserError(pos: 0, kind: .unexpectedEOF) }
        guard case .lparen = lparenToken.value else { throw ParserError(pos: 0, kind: .unexpectedEOF) }

        var elements: [Datum] = []
        while let token = try lexer.peek(), token.value != .rparen {
            let datum = try parseDatum()
            elements.append(datum)
        }

        guard let rparenToken = try lexer.next() else { throw ParserError(pos: 0, kind: .unexpectedEOF) }
        guard case .rparen = rparenToken.value else { throw ParserError(pos: 0, kind: .unexpectedEOF) }

        return Datum(start: lparenToken.start, end: rparenToken.end, kind: .list(value: elements))
    }
}





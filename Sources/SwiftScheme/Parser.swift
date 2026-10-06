









struct Parser {
    var lexer: PeekableLexer






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
            if let datum {
                return Expr(start: token.start, end: datum.end, kind: .quotation(datum))
            }
        }

        if let token, case .lparen = token.value {
            return try parseProcedureCall()
        }

        if let token, case .identifier(let name) = token.value {
            let _ = try lexer.next()
            return Expr(start: token.start, end: token.end, kind: .variable(name))
        }

        return nil
    }

    mutating func parseConditional() throws -> Expr? {
        guard let lparenToken = try lexer.next() else { return nil }
        guard case .lparen = lparenToken.value else { return nil }

        guard let ifToken = try lexer.next() else { return nil }
        guard case .identifier("if") = ifToken.value else { return nil }

        guard let test = try self.parseExpression() else { return nil }
        guard let consequence = try self.parseExpression() else { return nil }
        
        var alternate: Expr? = nil
        do {
            alternate = try self.parseExpression()
        } catch {
            
        }

        guard let rparenToken = try lexer.next() else { return nil }
        guard case .rparen = rparenToken.value else { return nil }

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

    mutating func parseDatum() throws -> Datum? {
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
        return nil
    }


    mutating func parseDatumList() throws -> Datum? {
        guard let lparenToken = try lexer.next() else { return nil }
        guard case .lparen = lparenToken.value else { return nil }

        var elements: [Datum] = []
        while let datum = try self.parseDatum() {
            elements.append(datum)
        }

        guard let rparenToken = try lexer.next() else { return nil }
        guard case .rparen = rparenToken.value else { return nil }

        return Datum(start: lparenToken.start, end: rparenToken.end, kind: .list(value: elements))
    }
}





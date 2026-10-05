









struct Parser {
    var lexer: PeekableLexer




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
            return try parseList()
        }

        return nil
    }


    mutating func parseList() throws -> Datum? {
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





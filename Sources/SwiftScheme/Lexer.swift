







struct Lexer {
    let data: String
    var pos: Int
    var endPos: Int

    var positionStack: [Int] = []

    init(data: String) {
        self.data = data
        self.pos = 0
        self.endPos = data.count
    }



    mutating func pushPosition() {
        positionStack.append(pos)
    }

    mutating func popPosition() {
        self.pos = positionStack.removeLast()
    }

    mutating func forgetPosition() {
        let _ = positionStack.removeLast()
    }



    mutating func next() throws -> Token? {
        guard pos < endPos else { return nil }

        skipWhitespace()

        if let boolean = peekBoolean() {
            self.pos = boolean.end
            return boolean
        }

        if let number = peekNumber() {
            self.pos = number.end
            return number
        }

        if let identifier = peekIdentifier() {
            self.pos = identifier.end
            return identifier
        }

        if let lparen = peekLParen() {
            self.pos = lparen.end
            return lparen
        }

        if let rparen = peekRParen() {
            self.pos = rparen.end
            return rparen
        }

        return nil
    }


    private func char(at index: Int) -> Character? {
        guard 0 <= index, index < endPos else { return nil }
        return data[data.index(data.startIndex, offsetBy: index)]
    }





    mutating func skipWhitespace() {
        var index = pos
        var updatedIndex: Bool = true
        while updatedIndex {
            updatedIndex = false
            while let ch = char(at: index), ch.isWhitespace {
                index += 1
                updatedIndex = true
            }
            if let ch = char(at: index), ch == ";" {
                while let ch = char(at: index), !ch.isNewline {
                    index += 1
                    updatedIndex = true
                }
            }
        }
        self.pos = index
    }






    private func peekChar(exp: Character, value: TokenValue) -> Token? {
        guard let ch = char(at: pos) else { return nil }
        guard ch == exp else { return nil }
        return Token(start: pos, end: pos + 1, value: value)
    }

    func peekBoolean() -> Token? {
        guard pos < endPos else { return nil }
        let startPos = pos
        guard let hashChar = char(at: startPos) else {
            return nil
        }
        guard let valueChar = char(at: startPos + 1) else {
            return nil
        }
        guard hashChar == "#" else { return nil }
        if valueChar == "t" {
            return Token(start: startPos, end: startPos + 2, value: .boolean(value: true))
        } else if valueChar == "f" {
            return Token(start: startPos, end: startPos + 2, value: .boolean(value: false))
        } else {
            return nil
        }
    }

    func peekNumber() -> Token? {
        guard pos < endPos else { return nil }
        let startPos = pos
        var index = pos

        if let sign = char(at: index), sign == "+" || sign == "-" {
            index += 1
        }

        guard index < endPos else { return nil }
        guard let current = char(at: index), current.isNumber else { return nil }

        while let nextChar = char(at: index), nextChar.isNumber {
            index += 1
        }

        let startIndex = data.index(data.startIndex, offsetBy: startPos)
        let endIndex = data.index(data.startIndex, offsetBy: index)
        let numberString = String(data[startIndex..<endIndex])

        guard let numberValue = Int(numberString) else { return nil }
        return Token(start: startPos, end: index, value: .number(value: numberValue))
    }

    func peekIdentifier() -> Token? {
        guard pos < endPos else { return nil }
        let startPos = pos
        var index = startPos

        guard let initial = char(at: index) else { return nil }
        guard isInitial(initial) else { return nil }

        while let nextChar = char(at: index), isSubsequent(nextChar) {
            index += 1
        }

        let startIndex = data.index(data.startIndex, offsetBy: startPos)
        let endIndex = data.index(data.startIndex, offsetBy: index)
        let identifier = String(data[startIndex..<endIndex])
        return Token(start: startPos, end: index, value: .identifier(name: identifier))
    }
    
    func peekLParen() -> Token? {
        return peekChar(exp: "(", value: .lparen)
    }

    func peekRParen() -> Token? {
        return peekChar(exp: ")", value: .rparen)
    }

    func peekQuoteAbbr() -> Token? {
        return peekChar(exp: "'", value: .quoteAbbr)
    }










    func isSpecialInitial(_ ch: Character) -> Bool {
        return ch == "!" ||
                ch == "$" ||
                ch == "%" ||
                ch == "&" ||
                ch == "*" ||
                ch == "/" ||
                ch == ":" ||
                ch == "<" ||
                ch == ">" ||
                ch == "=" ||
                ch == "?" ||
                ch == "^" ||
                ch == "_" ||
                ch == "~"
    }

    func isInitial(_ ch: Character) -> Bool {
        return ch.isLetter || isSpecialInitial(ch)
    }

    func isSpecialSubsequent(_ ch: Character) -> Bool {
        return ch == "+" || 
                ch == "-" ||
                ch == "." ||
                ch == "@"
    }

    func isSubsequent(_ ch: Character) -> Bool {
        return ch.isLetter || 
                isSpecialInitial(ch) || 
                ch.isNumber || 
                isSpecialSubsequent(ch)
    }
}





























struct PeekableLexer {
    var lexer: Lexer
    var buffer: [Token?] = []

    init(data: String) {
        self.lexer = Lexer(data: data)
    }


    mutating func peek() throws -> Token? {
        if buffer.isEmpty {
            buffer.append(try lexer.next())
        }
        return buffer.last!
    }

    mutating func next() throws -> Token? {
        if buffer.isEmpty {
            buffer.append(try lexer.next())
        }
        if let token = buffer.removeFirst() {
            buffer.append(try lexer.next())
            return token
        }
        return nil
    }

    mutating func pushPosition() {
        self.lexer.pushPosition()
    }

    mutating func popPosition() {
        self.lexer.popPosition()
    }

    mutating func forgetPosition() {
        self.lexer.forgetPosition()
    }
}


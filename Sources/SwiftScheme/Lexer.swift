






struct FilePos {
    let pos: Int
    let col: Int
    let line: Int

    init(pos: Int, col: Int, line: Int) {
        self.pos = pos
        self.col = col
        self.line = line
    }
}





struct CharacterSource {
    let data: String
    private(set) var pos: Int
    private(set) var endPos: Int

    private(set) var col: Int
    private(set) var line: Int

    var filePos: FilePos {
        FilePos(pos: pos, col: col, line: line)
    }

    private var posStack: [FilePos] 

    init(data: String) {
        self.data = data
        self.pos = 0
        self.endPos = data.count

        self.col = 0
        self.line = 0

        self.posStack = []
    }




    private func char(at index: Int) -> Character? {
        guard 0 <= index, index < endPos else { return nil }
        return data[data.index(data.startIndex, offsetBy: index)]
    }

    mutating func pushPosition() {
        posStack.append(FilePos(pos: pos, col: col, line: line))
    }

    mutating func popPosition() {
        let filePos = posStack.removeLast()
        self.pos = filePos.pos
        self.col = filePos.col
        self.line = filePos.line
    }

    mutating func forgetPosition() {
        let _ = posStack.removeLast()
    }

    func peekChar() -> Character? {
        return char(at: pos)
    }

    mutating func nextChar() -> Character? {
        let char = char(at: pos)
        self.pos += 1
        self.pos = min(pos, endPos)

        if char == "\n" {
            line += 1
            col = 0
        } else {
            col += 1
        }

        return char
    }

    mutating func skipWhitespace() {
        var consumedWhitespace: Bool = true
        while consumedWhitespace {
            consumedWhitespace = false
            while let char = peekChar(), char.isWhitespace {
                let _ = self.nextChar()
                consumedWhitespace = true
            }
            if let char = peekChar(), char == ";" {
                while let char = peekChar(), !char.isNewline {
                    let _ = self.nextChar()
                    consumedWhitespace = true
                }
            }
        }
    }
}


















enum LexerErrorKind: Error, Equatable {
    case unrecognizedToken
}

struct LexerError: Error, Equatable {
    let pos: Int
    let kind: LexerErrorKind
}









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


    mutating func peek() throws -> Token? {
        self.pushPosition()
        let token = try self.next()
        self.popPosition()
        return token
    }

    mutating func peek2() throws -> Token? {
        self.pushPosition()
        let _ = try self.next()
        let token = try self.next()
        self.popPosition()
        return token
    }

    mutating func next() throws -> Token? {
        guard pos < endPos else { return nil }
        skipWhitespace()
        guard pos < endPos else { return nil }

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

        if let identifier = peekPeculiarIdentifier() {
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

        if let quoteAbbr = peekQuoteAbbr() {
            self.pos = quoteAbbr.end
            return quoteAbbr
        }

        if let period = peekPeriod() {
            self.pos = period.end
            return period
        }

        throw LexerError(pos: pos, kind: .unrecognizedToken)
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

    func peekPeculiarIdentifier() -> Token? {
        guard pos < endPos else { return nil }
        let startPos = pos
        var index = startPos

        guard let initial = char(at: index) else { return nil}
        if initial == "+" ||
            initial == "*" ||
            initial == "<" ||
            initial == "-" {
                let endPos = startPos + 1
                return Token(start: startPos, end: endPos, value: .identifier(name: String(initial)))
            }
        
        return nil
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

    func peekPeriod() -> Token? {
        return peekChar(exp: ".", value: .period)
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



























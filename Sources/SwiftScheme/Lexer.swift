






struct FilePos: Equatable {
    let pos: Int
    let col: Int
    let line: Int

    init(pos: Int, col: Int, line: Int) {
        self.pos = pos
        self.col = col
        self.line = line
    }

    var localizedDescription: String {
        "Line: \(line), Col: \(col)"
    }
}





struct CharacterSource {
    let data: String
    private(set) var pos: Int
    private(set) var endPos: Int

    private(set) var col: Int
    private(set) var line: Int

    var filePos: FilePos {
        get {
            FilePos(pos: pos, col: col, line: line)
        }
        set {
            self.pos = newValue.pos
            self.col = newValue.col
            self.line = newValue.line
        }
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

public struct LexerError: Error, Equatable {
    let pos: FilePos
    let kind: LexerErrorKind

    var localizedDescription: String {
        let t1 = pos.localizedDescription
        let t2 = switch kind {
            case .unrecognizedToken:
                "Unrecognized token"
        }
        return "\(t1) - \(t2)"
    }
}









struct Lexer {
    var source: CharacterSource
    var pos: FilePos {
        source.filePos
    }

    init(data: String) {
        self.source = CharacterSource(data: data)
    }



    mutating func peek() throws -> Token? {
        source.pushPosition()
        let token = try self.next()
        source.popPosition()
        return token
    }

    mutating func peek2() throws -> Token? {
        source.pushPosition()
        let _ = try self.next()
        let token = try self.next()
        source.popPosition()
        return token
    }

    mutating func next() throws -> Token? {
        guard let _ = source.peekChar() else { return nil }
        source.skipWhitespace()
        guard let _ = source.peekChar() else { return nil }

        if let boolean = peekBoolean() {
            source.filePos = boolean.end
            return boolean
        }

        if let number = peekNumber() {
            source.filePos = number.end
            return number
        }

        if let identifier = peekIdentifier() {
            source.filePos = identifier.end
            return identifier
        }

        if let identifier = peekPeculiarIdentifier() {
            source.filePos = identifier.end
            return identifier
        }

        if let lparen = peekLParen() {
            source.filePos = lparen.end
            return lparen
        }

        if let rparen = peekRParen() {
            source.filePos = rparen.end
            return rparen
        }

        if let quoteAbbr = peekQuoteAbbr() {
            source.filePos = quoteAbbr.end
            return quoteAbbr
        }

        if let period = peekPeriod() {
            source.filePos = period.end
            return period
        }

        throw LexerError(pos: source.filePos, kind: .unrecognizedToken)
    }












    private mutating func peekChar(exp: Character, value: TokenValue) -> Token? {
        let startPos = source.filePos
        source.pushPosition()
        defer {
            source.popPosition()
        }
        guard let ch = source.nextChar() else { return nil }
        guard ch == exp else { return nil }
        let endPos = source.filePos
        return Token(start: startPos, end: endPos, value: value)
    }

    mutating func peekBoolean() -> Token? {
        let startPos = source.filePos
        source.pushPosition()
        defer {
            source.popPosition()
        }
        guard let hashChar = source.nextChar() else {
            return nil
        }
        guard let valueChar = source.nextChar() else {
            return nil
        }
        let endPos = source.filePos
        guard hashChar == "#" else { return nil }
        if valueChar == "t" {
            return Token(start: startPos, end: endPos, value: .boolean(value: true))
        } else if valueChar == "f" {
            return Token(start: startPos, end: endPos, value: .boolean(value: false))
        } else {
            return nil
        }
    }

    mutating func peekNumber() -> Token? {
        let startPos = source.filePos
        source.pushPosition()
        defer { source.popPosition() }

        if let sign = source.peekChar(), sign == "+" || sign == "-" {
            let _ = source.nextChar()
        }

        guard let current = source.nextChar(), current.isNumber else { return nil }

        while let nextChar = source.peekChar(), nextChar.isNumber {
            let _ = self.source.nextChar()
        }

        let endPos = source.filePos

        let startIndex = source.data.index(source.data.startIndex, offsetBy: startPos.pos)
        let endIndex = source.data.index(source.data.startIndex, offsetBy: endPos.pos)
        let numberString = String(source.data[startIndex..<endIndex])

        guard let numberValue = Int(numberString) else { return nil }
        return Token(start: startPos, end: endPos, value: .number(value: numberValue))
    }

    mutating func peekPeculiarIdentifier() -> Token? {
        let startPos = source.filePos
        source.pushPosition()
        defer { source.popPosition() }

        guard let initial = source.nextChar() else { return nil }
        if initial == "+" ||
            initial == "*" ||
            initial == "<" ||
            initial == "-" {
                let endPos = source.filePos
                return Token(start: startPos, end: endPos, value: .identifier(name: String(initial)))
            }
        
        return nil
    }

    mutating func peekIdentifier() -> Token? {
        let startPos = source.filePos
        source.pushPosition()
        defer { source.popPosition() }

        guard let initial = source.nextChar() else { return nil }
        guard isInitial(initial) else { return nil }

        while let nextChar = source.peekChar(), isSubsequent(nextChar) {
            let _ = source.nextChar()
        }
        let endPos = source.filePos

        let startIndex = source.data.index(source.data.startIndex, offsetBy: startPos.pos)
        let endIndex = source.data.index(source.data.startIndex, offsetBy: endPos.pos)
        let identifier = String(source.data[startIndex..<endIndex])
        return Token(start: startPos, end: endPos, value: .identifier(name: identifier))
    }
    
    mutating func peekLParen() -> Token? {
        return peekChar(exp: "(", value: .lparen)
    }

    mutating func peekRParen() -> Token? {
        return peekChar(exp: ")", value: .rparen)
    }

    mutating func peekQuoteAbbr() -> Token? {
        return peekChar(exp: "'", value: .quoteAbbr)
    }

    mutating func peekPeriod() -> Token? {
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



























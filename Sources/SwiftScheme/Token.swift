
enum TokenValue: Equatable {
    case identifier(name: String)
    case boolean(value: Bool)
    case number(value: Int)
    case character(value: Character)
    case string(value: String)
    case lparen
    case rparen
    case lparenHash
    case quoteAbbr
    case period
}

struct Token: Equatable {
    let start: FilePos
    let end: FilePos
    let value: TokenValue

    init(start: FilePos, end: FilePos, value: TokenValue) {
        self.start = start
        self.end = end
        self.value = value
    }
}




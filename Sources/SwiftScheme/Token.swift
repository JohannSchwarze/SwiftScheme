
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
}

struct Token: Equatable {
    let start: Int
    let end: Int
    let value: TokenValue

    init(start: Int, end: Int, value: TokenValue) {
        self.start = start
        self.end = end
        self.value = value
    }
}




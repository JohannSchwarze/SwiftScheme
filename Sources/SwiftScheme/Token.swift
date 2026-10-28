
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

    var localizedDescription: String {
        return switch self {
        case .boolean(let value):
            "BOOLEAN \(value)"
        case .identifier(let name):
            "IDENTIFIER \(name)"
        case .character(let value):
            "CHARACTER \(value)"
        case .number(let value):
            "NUMBER \(value)"
        case .string(let value):
            "STRING \(value)"
        case .lparen:
            "LPAREN"
        case .rparen:
            "RPAREN"
        case .lparenHash:
            "LPARENHASH"
        case .period:
            "PERIOD"
        case .quoteAbbr:
            "QUOTEABBR"
        }
    }
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




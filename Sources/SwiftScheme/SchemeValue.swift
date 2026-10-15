






indirect enum SchemeValue: Equatable {
    case boolean(value: Bool)
    case number(value: Int)
    case symbol(value: String)
    case emptyList
    case pair(car: SchemeValue, cdr: SchemeValue)
    case procedure(env: SchemeEnvironment<SchemeValue>, params: [String], body: [Expr])
}




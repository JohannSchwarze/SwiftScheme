







final class NativeProcedure: Equatable {
    let name: String
    let arity: Int? // nil means variadic
    let invoke: (SchemeEnvironment<SchemeEnvironmentLocation<SchemeValue>>) throws -> SchemeValue

    init(
        name: String,
        arity: Int? = nil,
        invoke: @escaping (SchemeEnvironment<SchemeEnvironmentLocation<SchemeValue>>) throws -> SchemeValue
    ) {
        self.name = name
        self.arity = arity
        self.invoke = invoke
    }

    static func == (lhs: NativeProcedure, rhs: NativeProcedure) -> Bool {
        lhs === rhs
    }
}




indirect enum SchemeValue: Equatable {
    case boolean(value: Bool)
    case number(value: Int)
    case symbol(value: String)
    case emptyList
    case pair(car: SchemeValue, cdr: SchemeValue)
    case procedure(env: SchemeEnvironment<SchemeEnvironmentLocation<SchemeValue>>, params: [String], remainingParams: String?, body: [Expr])
    case nativeProcedure(env: SchemeEnvironment<SchemeEnvironmentLocation<SchemeValue>>, params: [String], remainingParams: String?, callable: NativeProcedure)
}




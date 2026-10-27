




indirect enum ExprKind: Equatable {
    case variable(String)
    case boolean(Bool)
    case number(Int)
    case quotation(Datum)
    case procedureCall(operator: Expr, operands: [Expr])
    case procedure(params: [String], remainingParams: String?, body: [Expr])
    case conditional(test: Expr, consequence: Expr, alternate: Expr?)
    case asssignment(variable: String, expr: Expr)
}


struct Expr: Equatable {
    let start: FilePos
    let end: FilePos
    let kind: ExprKind
}
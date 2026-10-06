




indirect enum ExprKind: Equatable {
    case variable(String)
    case boolean(Bool)
    case number(Int)
    case quotation(Datum)
    case procedureCall(operator: Expr, operands: [Expr])
    case conditional(test: Expr, consequence: Expr, alternate: Expr?)
}


struct Expr: Equatable {
    let start: Int
    let end: Int
    let kind: ExprKind
}
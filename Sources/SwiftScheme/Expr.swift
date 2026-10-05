




indirect enum ExprKind {
    case variable(String)
    case boolean(Bool)
    case number(Int)
    case procedureCall(operator: Expr, operands: [Expr])
    case conditional(test: Expr, consequence: Expr, alternate: Expr?)
}


struct Expr {
    let kind: ExprKind
}
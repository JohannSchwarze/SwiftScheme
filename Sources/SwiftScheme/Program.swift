


struct Definition {
    let variable: Expr
    let expr: Expr

    let start: FilePos
    let end: FilePos
}






struct Program {
    let definitions: [Definition]
}
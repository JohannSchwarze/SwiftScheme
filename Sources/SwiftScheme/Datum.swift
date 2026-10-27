



indirect enum DatumKind: Equatable {
    case boolean(value: Bool)
    case number(value: Int)
    case symbol(value: String)
    case list(value: [Datum])
}


struct Datum: Equatable {
    let start: FilePos
    let end: FilePos
    let kind: DatumKind
}











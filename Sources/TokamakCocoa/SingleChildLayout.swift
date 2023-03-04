import TokamakCore

extension ModifiedContent: CocoaPrimitive where Content: View, Modifier == _FrameLayout {
    var renderedBody: AnyView {
        fatalError()
    }
}

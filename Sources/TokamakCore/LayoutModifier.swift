public protocol LayoutModifier {
    associatedtype LayoutType: Layout

    func toLayout() -> LayoutType
}

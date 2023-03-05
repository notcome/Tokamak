import UIKit

class Node {
    var id: ObjectIdentifier

    var frame: CGRect = .zero
    var opacity: CGFloat = 1
    var zIndex: CGFloat = 0

    var children: [Node] = []

    var mask: Node?

    required init(id: ObjectIdentifier) {
        self.id = id
    }

    func makeCopy() -> Self {
        let node = Self(id: id)
        copy(to: node)
        return node
    }

    func copy(to other: Node) {
        other.frame = frame
        other.opacity = opacity
        other.zIndex = zIndex
        other.children = children
        other.mask = mask
    }
}

final class ShapeNode: Node {
    var path: CGPath = CGPath(rect: .zero, transform: nil)
    var color: CGColor = .init(red: 0, green: 0, blue: 0, alpha: 1)

    override func copy(to other: Node) {
        super.copy(to: other)
        let other = other as! ShapeNode
        other.path = path
        other.color = color
    }
}

final class TextNode: Node {
    var text: String = ""

    override func copy(to other: Node) {
        super.copy(to: other)
        let other = other as! TextNode
        other.text = text
    }
}

public struct Element: Equatable, Identifiable {
    fileprivate var node: Node

    fileprivate init(_ node: Node) {
        self.node = node
    }

    public init(id: ObjectIdentifier = .random()) {
        node = .init(id: id)
    }

    public var id: ObjectIdentifier {
        node.id
    }

    public var frame: CGRect {
        get {
            node.frame
        }
        set {
            copyIfNeeded()
            node.frame = newValue
        }
    }
    public var size: CGSize {
        get { frame.size }
        set { frame.size = newValue }
    }
    public var origin: CGPoint {
        get { frame.origin }
        set { frame.origin = newValue }
    }

    public var opacity: CGFloat {
        get {
            node.opacity
        }
        set {
            copyIfNeeded()
            node.opacity = newValue
        }
    }
    public var zIndex: CGFloat {
        get {
            node.zIndex
        }
        set {
            copyIfNeeded()
            node.zIndex = newValue
        }
    }

    public var children: [Element] {
        get {
            node.children.map { Element($0) }
        }
        set {
            copyIfNeeded()
            node.children = newValue.map(\.node)
        }
    }

    public var mask: Element? {
        get {
            node.mask.map { Element($0) }
        }
        set {
            copyIfNeeded()
            node.mask = newValue?.node
        }
    }

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.node === rhs.node
    }

    fileprivate mutating func copyIfNeeded() {
        if !isKnownUniquelyReferenced(&node) {
            node = node.makeCopy()
        }
    }
}

public extension Element {
    func asShape() -> ShapeElement? {
        .init(untyped: self)
    }

    func asText() -> TextElement? {
        .init(untyped: self)
    }
}

@dynamicMemberLookup
public struct ShapeElement: Equatable, Identifiable {
    public private(set) var untyped: Element

    private var node: ShapeNode {
        untyped.node as! ShapeNode
    }

    public init?(untyped: Element) {
        guard untyped.node is ShapeNode else { return nil }
        self.untyped = untyped
    }

    public init(id: ObjectIdentifier = .random()) {
        untyped = Element(ShapeNode(id: id))
    }

    public subscript<Value>(dynamicMember keyPath: KeyPath<Element, Value>) -> Value {
        untyped[keyPath: keyPath]
    }

    public subscript<Value>(dynamicMember keyPath: WritableKeyPath<Element, Value>) -> Value {
        get { untyped[keyPath: keyPath] }
        set { untyped[keyPath: keyPath] = newValue }
    }

    public var id: ObjectIdentifier {
        node.id
    }

    public var path: CGPath {
        get {
            node.path
        }
        set {
            untyped.copyIfNeeded()
            node.path = newValue
        }
    }

    public var color: CGColor {
        get {
            node.color
        }
        set {
            untyped.copyIfNeeded()
            node.color = newValue
        }
    }
}

@dynamicMemberLookup
public struct TextElement: Equatable, Identifiable {
    public private(set) var untyped: Element

    private var node: TextNode {
        untyped.node as! TextNode
    }

    public init?(untyped: Element) {
        guard untyped.node is TextNode else { return nil }
        self.untyped = untyped
    }

    public init(id: ObjectIdentifier = .random()) {
        untyped = Element(TextNode(id: id))
    }

    public subscript<Value>(dynamicMember keyPath: KeyPath<Element, Value>) -> Value {
        untyped[keyPath: keyPath]
    }

    public subscript<Value>(dynamicMember keyPath: WritableKeyPath<Element, Value>) -> Value {
        get { untyped[keyPath: keyPath] }
        set { untyped[keyPath: keyPath] = newValue }
    }

    public var id: ObjectIdentifier {
        node.id
    }

    public var text: String {
        get {
            node.text
        }
        set {
            untyped.copyIfNeeded()
            node.text = newValue
        }
    }
}

extension ObjectIdentifier {
    public static func random() -> ObjectIdentifier {
        unsafeBitCast(UInt.random(in: UInt.min...UInt.max), to: ObjectIdentifier.self)
    }
}

func buildView(from element: Element) -> UIView {
    let view: UIView

    if let shape = element.asShape() {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = shape.path
        shapeLayer.fillColor = shape.color

        view = UIView()
        view.layer.addSublayer(shapeLayer)
        shapeLayer.frame = view.bounds
    } else if let text = element.asText() {
        let label = UITextView()
        label.isScrollEnabled = false
        label.isEditable = false
        label.text = text.text
        view = label
    } else {
        view = UIView()
    }

    view.frame = element.frame
    view.alpha = element.opacity
    view.layer.zPosition = element.zIndex

    for child in element.children {
        view.addSubview(buildView(from: child))
    }
    if let mask = element.mask {
        view.mask = buildView(from: mask)
    }
    return view
}

public final class ElementRendererView: UIView {
    var element: Element = Element()

    public override var intrinsicContentSize: CGSize {
        element.size
    }

    public func populate(with element: Element) {
        self.element = element
        invalidateIntrinsicContentSize()

        for subview in subviews {
            subview.removeFromSuperview()
        }
        addSubview(buildView(from: element))
    }
}

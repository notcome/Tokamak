import TokamakCore
import UIKit

class ViewNode: Target {
    weak var parent: ViewNode?
    var children: [ViewNode] = []
    var view: AnyView = AnyView(EmptyView())

    var proposedViewSize: CGSize = .zero
    var actualViewSize: CGSize = .zero
    var origin: CGPoint = .zero

    var frame: CGRect {
        .init(origin: origin, size: actualViewSize)
    }
    var bounds: CGRect {
        .init(origin: .zero, size: actualViewSize)
    }

    class var hasUIView: Bool {
        true
    }

    private var _uiView: UIView!
    func loadUIView() -> UIView {
        UIView()
    }

    var uiView: UIView? {
        guard Self.hasUIView else { return nil }
        if _uiView == nil {
            _uiView = loadUIView()
        }
        return _uiView
    }

    func update() {}

    func layout() {
        fatalError()
    }

    func layoutSubviews() {
        guard !children.isEmpty else { return }
        fatalError()
    }

    var closestUIView: UIView {
        if let uiView {
            return uiView
        }
        return parent!.closestUIView
    }

    func addChild(_ child: ViewNode, before sibling: ViewNode?) {
        var siblingIndex = children.count
        if let sibling {
            siblingIndex = children.firstIndex { $0 === sibling }!
        }

        if let childUIView = child.uiView {
            attach(childUIView, before: siblingIndex)
        }

        children.insert(child, at: siblingIndex)
        layout(child: child)
    }

    private func attach(_ childUIView: UIView, before siblingIndex: Int) {
        guard let uiView else {
            let uiView = closestUIView
            guard uiView.subviews.isEmpty else {
                fatalError("We do not support such a complicated case")
            }
            uiView.addSubview(childUIView)
            return
        }

        for i in siblingIndex..<children.count {
            let sibling = children[i]
            if let siblingUIView = sibling.uiView {
                uiView.insertSubview(childUIView, belowSubview: siblingUIView)
            }
            if let descendant = sibling.firstDescendantWithUIView {
                uiView.insertSubview(childUIView, belowSubview: descendant.uiView!)
            }
        }
        uiView.addSubview(childUIView)
    }

    private func layout(child: ViewNode) {
        child.proposedViewSize = frame.size
        child.layout()
        let w = child.actualViewSize.width
        let h = child.actualViewSize.height

        let x = (actualViewSize.width - w) / 2
        let y = (actualViewSize.height - h) / 2
        child.origin = .init(x: x, y: y)

        guard let childUIView = child.uiView else { return }
        childUIView.frame.size = .init(width: w, height: h)
        guard let superview = childUIView.superview else { return }

        var parent = self
        var dx = x
        var dy = y
        while true {
            if parent.uiView == superview {
                childUIView.frame.origin = .init(x: dx, y: dy)
                return
            }
            dx += parent.origin.x
            dy += parent.origin.y
            parent = parent.parent!
        }
    }

    var firstDescendantWithUIView: ViewNode? {
        for child in children {
            if child.uiView != nil {
                return child
            }
            if let descendant = child.firstDescendantWithUIView {
                return descendant
            }
        }
        return nil
    }
}

protocol PrimitiveViewNodeConvertible {
    func createViewNode() -> ViewNode
}

protocol CocoaPrimitive {
    var renderedBody: AnyView { get }
}

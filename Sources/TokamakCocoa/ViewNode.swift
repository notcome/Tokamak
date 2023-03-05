import TokamakCore
import UIKit

class ViewNode: Target {
    weak var parent: ViewNode?
    var children: [ViewNode] = []
    var childrenOrigins: [CGPoint] = []
    var view: AnyView = AnyView(EmptyView())
    var proposal: ProposedViewSize = .zero
    var cachedFittingSize: (ProposedViewSize, CGSize)?
    var size: CGSize = .zero

    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        var w: CGFloat = 0
        var h: CGFloat = 0

        for child in children {
            let childSize = child.getFittingSize(proposal)
            w = max(childSize.width, w)
            h = max(childSize.height, h)
        }

        return .init(width: w, height: h)
    }

    func placeSubviews(_ proposal: ProposedViewSize) {
        var w: CGFloat = 0
        var h: CGFloat = 0

        for child in children {
            child.layout(proposal)
            w = max(child.size.width, w)
            h = max(child.size.height, h)
        }

        childrenOrigins = []
        for child in children {
            let x = (child.size.width - w) / 2
            let y = (child.size.height - h) / 2
            childrenOrigins.append(.init(x: x, y: y))
        }
    }

    var needsLayout: Bool = false
    func setNeedsLayout() {
        guard !needsLayout else { return }
        needsLayout = true
        cachedFittingSize = nil
        parent?.setNeedsLayout()
    }

    func addChild(_ child: ViewNode, before sibling: ViewNode?) {
        var siblingIndex = children.count
        if let sibling {
            siblingIndex = children.firstIndex { $0 === sibling }!
        }
        children.insert(child, at: siblingIndex)
        child.parent = self
        setNeedsLayout()
    }

    final func getFittingSize(_ proposal: ProposedViewSize) -> CGSize {
        if let (cachedProposal, cachedResult) = cachedFittingSize,
           proposal == cachedProposal
        {
            return cachedResult
        }
        let result = sizeThatFits(proposal)
        cachedFittingSize = (proposal, result)
        return result
    }

    final func layout(_ proposal: ProposedViewSize) {
        guard proposal != self.proposal || needsLayout else { return }
        needsLayout = false
        self.proposal = proposal
        size = getFittingSize(proposal)
        placeSubviews(proposal)
    }

    func generateOutput() -> Element {
        var element = Element(id: ObjectIdentifier(self))
        element.size = size
        element.children = zip(children, childrenOrigins).map { (child, origin) in
            var childElement = child.generateOutput()
            childElement.origin.x += origin.x
            childElement.origin.y += origin.y
            return childElement
        }
        return element
    }
}

protocol PrimitiveViewNodeConvertible {
    func createViewNode() -> ViewNode
}

protocol CocoaPrimitive {
    var renderedBody: AnyView { get }
}

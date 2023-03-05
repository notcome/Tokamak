import TokamakCore
import UIKit

final class PaddingViewNode: ViewNode {
    fileprivate var repn: Repn
    override var view: AnyView {
        get { AnyView(repn) }
        set {
            repn = mapAnyView(newValue, transform: { x in x })!
        }
    }

    fileprivate init(repn: Repn) {
        self.repn = repn
        super.init()
    }

    struct Repn: View, PrimitiveViewNodeConvertible, ParentView {
        var edges: Edge.Set
        var insets: EdgeInsets?
        var content: AnyView

        var children: [AnyView] {
            [content]
        }


        var body: Never {
            neverBody("PaddingViewNode.Repn")
        }

        func createViewNode() -> ViewNode {
            PaddingViewNode(repn: self)
        }
    }

    override func generateOutput() -> Element {
        var element = children[0].generateOutput()
        element.origin.x += childrenOrigins[0].x
        element.origin.y += childrenOrigins[0].y
        return element
    }

    override func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        let proposal = proposal.replacingUnspecifiedDimensions()
        let insets = EdgeInsets(applying: repn.edges, to: repn.insets ?? .init(_all: 10))
        let subviewSize = children.first?.getFittingSize(
          .init(
            width: proposal.width - insets.leading - insets.trailing,
            height: proposal.height - insets.top - insets.bottom
          )
        ) ?? .zero
        return .init(
          width: subviewSize.width + insets.leading + insets.trailing,
          height: subviewSize.height + insets.top + insets.bottom
        )
    }

    override func placeSubviews(_ proposal: ProposedViewSize) {
        let insets = EdgeInsets(applying: repn.edges, to: repn.insets ?? .init(_all: 10))
        let proposal = proposal.replacingUnspecifiedDimensions()
        childrenOrigins = []
        for child in children {
            let origin = CGPoint(x: insets.leading, y: insets.top)
            child.layout(.init(
                width: proposal.width - insets.leading - insets.trailing,
                height: proposal.height - insets.top - insets.bottom
            ))
            childrenOrigins.append(origin)
        }
    }
}

private extension EdgeInsets {
  init(applying edges: Edge.Set, to insets: EdgeInsets) {
    self.init(
      top: edges.contains(.top) ? insets.top : 0,
      leading: edges.contains(.leading) ? insets.leading : 0,
      bottom: edges.contains(.bottom) ? insets.bottom : 0,
      trailing: edges.contains(.trailing) ? insets.trailing : 0
    )
  }
}

import TokamakCore
import UIKit

extension Path {
    private func serialize(to path: CGMutablePath) {
        switch storage {
        case .empty:
            return
        case .rect(let rect):
            path.addRect(rect)
        case .ellipse(let rect):
            path.addEllipse(in: rect)
//        case .roundedRect(_):
//        case .stroked(_):
//        case .trimmed(_):
//        case .path(_):
        default:
            fatalError()
        }
    }

    var cgPath: CGPath {
        let destination = CGMutablePath()
        serialize(to: destination)
        return destination
    }
}

final class ShapeViewNode: ViewNode {
    fileprivate var repn: Repn
    override var view: AnyView {
        get { AnyView(repn) }
        set { repn = mapAnyView(newValue, transform: { x in x })! }
    }

    let shapeLayer = CAShapeLayer()

    fileprivate init(repn: Repn) {
        self.repn = repn
        super.init()
    }

    private var cgPath: CGPath = .init(rect: .zero, transform: nil)
    private var cgColor: CGColor {
        let r = _ColorProxy(repn.color).resolve(in: .defaultEnvironment)
        return CGColor(srgbRed: r.red, green: r.green, blue: r.blue, alpha: r.opacity)
    }

    override func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        repn.shape.sizeThatFits(proposal)
    }

    override func placeSubviews(_ proposal: ProposedViewSize) {
        size = repn.shape.sizeThatFits(proposal)
        cgPath = repn.shape.path(in: .init(origin: .zero, size: size)).cgPath
    }

    override func generateOutput() -> Element {
        var shapeElement = ShapeElement(id: ObjectIdentifier(self))
        shapeElement.size = size
        shapeElement.path = cgPath
        shapeElement.color = cgColor
        return shapeElement.untyped
    }
}

private extension ShapeViewNode {
    struct Repn: View, PrimitiveViewNodeConvertible {
        var shape: any Shape
        var color: Color

        var body: Never {
            neverBody("ShapeViewNode.Repn")
        }

        func createViewNode() -> ViewNode {
            ShapeViewNode(repn: self)
        }
    }
}

extension _ShapeView: CocoaPrimitive {
    var renderedBody: AnyView {
        let color = (style as? Color) ?? foregroundColor ?? Color.black
        let repn = ShapeViewNode.Repn(shape: shape, color: color)
        return AnyView(repn)
    }
}

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
        uiView!.layer.addSublayer(shapeLayer)
        shapeLayer.frame = .zero
        update()
    }

    private var cgColor: CGColor {
        let r = _ColorProxy(repn.color).resolve(in: .defaultEnvironment)
        return CGColor(srgbRed: r.red, green: r.green, blue: r.blue, alpha: r.opacity)
    }

    override func update() {
        layout()
        shapeLayer.fillColor = cgColor
    }

    override func layout() {
        actualViewSize = proposedViewSize
        let cgPath = repn.makePath(bounds).cgPath
        shapeLayer.path = cgPath
        shapeLayer.frame = bounds
    }
}

private extension ShapeViewNode {
    struct Repn: View, PrimitiveViewNodeConvertible {
        var makePath: (CGRect) -> Path
        var color: Color

        var body: Never {
            neverBody("ShapeTarget.Repn")
        }

        func createViewNode() -> ViewNode {
            ShapeViewNode(repn: self)
        }
    }
}

extension _ShapeView: CocoaPrimitive {
    var renderedBody: AnyView {
        let color = (style as? Color) ?? foregroundColor ?? Color.black
        let repn = ShapeViewNode.Repn(makePath: shape.path(in:), color: color)
        return AnyView(repn)
    }
}

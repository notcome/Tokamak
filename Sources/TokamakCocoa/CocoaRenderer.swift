import Foundation
import TokamakCore
import UIKit

extension EnvironmentValues {
    static var defaultEnvironment: Self {
        var environment = EnvironmentValues()
        environment[_ColorSchemeKey.self] = .light
        return environment
    }
}

//extension ModifiedContent: CocoaPrimitive where Content: View, Modifier == _FrameLayout {
//    var renderedBody: AnyView {
//        AnyView(content.environment(\.colorScheme, .dark))
//    }
//}

final class CocoaRenderer: Renderer {
    typealias TargetType = ViewNode

    func mountTarget(before sibling: ViewNode?, to parent: ViewNode, with host: MountedHost) -> ViewNode? {
        if let repn: PrimitiveViewNodeConvertible = mapAnyView(host.view, transform: { x in x }) {
            let viewNode = repn.createViewNode()
            parent.addChild(viewNode, before: sibling)
            return viewNode
        }

        if mapAnyView(host.view, transform: { (view: ParentView) in view }) != nil {
            return parent
        }

        fatalError()
    }

    func update(target: ViewNode, with host: MountedHost) {
        target.update()
    }

    func unmount(target: ViewNode, from parent: ViewNode, with task: UnmountHostTask<CocoaRenderer>) {

    }

    func primitiveBody(for view: Any) -> AnyView? {
        (view as? CocoaPrimitive)?.renderedBody
    }

    func isPrimitiveView(_ type: Any.Type) -> Bool {
        type is CocoaPrimitive.Type
    }
}


final class RootViewNode: ViewNode {
    override func layout() {
        layoutSubviews()
    }

    override func layoutSubviews() {
        for child in children {
            child.proposedViewSize = proposedViewSize
            child.layout()
        }

        let w = children.map(\.actualViewSize.width).max() ?? 0
        let h = children.map(\.actualViewSize.height).reduce(0, +)
        var currentY: CGFloat = 0


        for child in children {
            child.origin = .init(x: 0, y: currentY)
            currentY += child.actualViewSize.height
            child.uiView?.frame = child.frame
        }

        actualViewSize = .init(width: w, height: h)

        let x = (proposedViewSize.width - w) / 2
        let y = (proposedViewSize.height - h) / 2
        origin = .init(x: x, y: y)
        uiView!.frame = .init(x: x, y: y, width: w, height: h)
    }
}

public final class DemoView<Root: View>: UIView {
    private var rootNode = RootViewNode()
    private var renderer = CocoaRenderer()
    private var reconciler: StackReconciler<CocoaRenderer>!

    public static func from(_ root: Root) -> DemoView<Root> {
        let view = DemoView()
        view.mount(root)
        return view
    }

    public func mount(_ root: Root) {
        precondition(reconciler == nil)
        addSubview(rootNode.uiView!)

        reconciler = StackReconciler(
            view: root,
            target: rootNode,
            environment: .defaultEnvironment,
            renderer: renderer
        ) { next in
            print("before execute next")
            DispatchQueue.main.async {
                print("now execute next")
                next()
            }
        }
    }

    public override func layoutSubviews() {
        rootNode.proposedViewSize = bounds.size
        rootNode.layout()
    }
}

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

extension ModifiedContent: CocoaPrimitive where Content: View, Modifier == _PaddingLayout {
    var renderedBody: AnyView {
        let repn = PaddingViewNode.Repn(
            edges: modifier.edges,
            insets: modifier.insets,
            content: AnyView(content))
        return AnyView(repn)
    }
}

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
        target.setNeedsLayout()
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

public final class DemoView<Root: View>: UIView {
    private var rootNode = ViewNode()
    private var renderer = CocoaRenderer()
    private var reconciler: StackReconciler<CocoaRenderer>!

    public static func from(_ root: Root) -> DemoView<Root> {
        let view = DemoView()
        view.mount(root)
        return view
    }

    public func mount(_ root: Root) {
        precondition(reconciler == nil)

        reconciler = StackReconciler(
            view: root,
            target: rootNode,
            environment: .defaultEnvironment,
            renderer: renderer
        ) { [weak self] next in
            DispatchQueue.main.async {
                guard let self else { return }
                next()
                self.rootNode.layout(self.rootNode.proposal)
                self.repopulate()
            }
        }
        self.rootNode.layout(.init(bounds.size))
        self.repopulate()
    }

    public override func layoutSubviews() {
        rootNode.layout(.init(bounds.size))
        repopulate()
    }

    func repopulate() {
        let output = rootNode.generateOutput()
        let view = buildView(from: output)

        for subview in subviews {
            subview.removeFromSuperview()
        }

        addSubview(view)

        let x = (frame.size.width - view.frame.size.width) / 2
        let y = (frame.size.height - view.frame.size.height) / 2
        view.frame.origin = .init(x: x, y: y)
    }
}

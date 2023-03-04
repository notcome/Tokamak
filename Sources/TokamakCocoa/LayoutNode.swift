import TokamakCore

func x<L: LayoutModifier>(modifier: L, subviews: LayoutSubviews) {

    let layout = modifier.toLayout()
    var cache = layout.makeCache(subviews: subviews)
    layout.sizeThatFits(proposal: .infinity, subviews: subviews, cache: &cache)
}

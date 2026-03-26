import SwiftUI

struct NotchShape: Shape {
    var topRadius: CGFloat
    var bottomRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topRadius, bottomRadius) }
        set {
            topRadius = newValue.first
            bottomRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let tr = min(topRadius, min(w / 2, h / 2))
        let br = min(bottomRadius, min(w / 2, h / 2))

        var path = Path()

        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))

        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addArc(
            tangent1End: CGPoint(x: w, y: h),
            tangent2End: CGPoint(x: w - br, y: h),
            radius: br
        )

        path.addLine(to: CGPoint(x: br, y: h))
        path.addArc(
            tangent1End: CGPoint(x: 0, y: h),
            tangent2End: CGPoint(x: 0, y: h - br),
            radius: br
        )

        path.addLine(to: CGPoint(x: 0, y: 0))

        path.closeSubpath()
        return path
    }
}

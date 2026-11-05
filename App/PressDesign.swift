import SwiftUI

enum PressInk {
    static let canvas = Color(red: 0.966, green: 0.951, blue: 0.906)
    static let paper = Color(red: 0.991, green: 0.982, blue: 0.948)
    static let green = Color(red: 0.094, green: 0.235, blue: 0.188)
    static let red = Color(red: 0.694, green: 0.200, blue: 0.125)
    static let gold = Color(red: 0.957, green: 0.781, blue: 0.368)
    static let muted = Color(red: 0.33, green: 0.36, blue: 0.31)
    static let line = green.opacity(0.22)
}

struct Slug: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.system(.caption2, design: .monospaced, weight: .semibold))
            .tracking(1.1)
    }
}

struct EggMark: View {
    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 38, y: size.height / 38)
            var egg = Path()
            egg.move(to: CGPoint(x: 19, y: 3))
            egg.addCurve(to: CGPoint(x: 32, y: 23), control1: CGPoint(x: 25, y: 2), control2: CGPoint(x: 32, y: 15))
            egg.addCurve(to: CGPoint(x: 6, y: 24), control1: CGPoint(x: 33, y: 38), control2: CGPoint(x: 6, y: 39))
            egg.addCurve(to: CGPoint(x: 19, y: 3), control1: CGPoint(x: 6, y: 15), control2: CGPoint(x: 12, y: 4))
            context.fill(egg, with: .color(PressInk.red))
            var cuts = Path()
            for n in 0..<3 {
                let x = CGFloat(10 + n * 4)
                cuts.move(to: CGPoint(x: x, y: 24 + CGFloat(n)))
                cuts.addQuadCurve(to: CGPoint(x: x + 5, y: 13 + CGFloat(n)), control: CGPoint(x: x, y: 19))
            }
            context.stroke(cuts, with: .color(PressInk.canvas), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }.accessibilityHidden(true)
    }
}

struct ScaledLabel: View {
    let label: CartonLabel
    var body: some View {
        Color.clear.aspectRatio(1.6, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    CartonFace(label: label)
                        .frame(width: 300, height: 187.5)
                        .scaleEffect(proxy.size.width / 300, anchor: .topLeading)
                }
            }
            .accessibilityHidden(true)
    }
}

struct PressButtonStyle: ButtonStyle {
    var filled = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(filled ? PressInk.paper : PressInk.green)
            .background(filled ? PressInk.green : PressInk.paper, in: RoundedRectangle(cornerRadius: 9))
            .overlay { RoundedRectangle(cornerRadius: 9).strokeBorder(filled ? .clear : PressInk.line) }
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct ProofBoard: View {
    let label: CartonLabel
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(PressInk.gold).frame(width: 6, height: 6)
                    Slug("Label proof")
                }
                Spacer()
                Slug(String(format: "№ %02d", (LabelStyle.allCases.firstIndex(of: label.style) ?? 0) + 1))
            }
            ScaledLabel(label: label)
                .background { Rectangle().fill(PressInk.paper).shadow(color: .black.opacity(0.28), radius: 3, x: 2, y: 4) }
                .rotationEffect(.degrees(-2))
                .padding(.horizontal, 15).padding(.vertical, 9)
            HStack {
                Slug("RP  /  PRESS")
                Spacer()
                Slug("88 × 55 mm")
            }
        }
        .foregroundStyle(PressInk.paper)
        .padding(.horizontal, 17).padding(.vertical, 13)
        .background {
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(PressInk.green))
                var grid = Path()
                for x in stride(from: 0, to: size.width, by: 16) {
                    grid.move(to: CGPoint(x: x, y: 0)); grid.addLine(to: CGPoint(x: x, y: size.height))
                }
                for y in stride(from: 0, to: size.height, by: 16) {
                    grid.move(to: CGPoint(x: 0, y: y)); grid.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(grid, with: .color(.white.opacity(0.085)), lineWidth: 0.55)
                for point in [CGPoint(x: 14, y: 39), CGPoint(x: size.width - 14, y: 39),
                              CGPoint(x: 14, y: size.height-39), CGPoint(x: size.width-14, y: size.height-39)] {
                    var cross = Path()
                    cross.move(to: CGPoint(x: point.x-4, y: point.y)); cross.addLine(to: CGPoint(x: point.x+4, y: point.y))
                    cross.move(to: CGPoint(x: point.x, y: point.y-4)); cross.addLine(to: CGPoint(x: point.x, y: point.y+4))
                    context.stroke(cross, with: .color(PressInk.gold.opacity(0.75)), lineWidth: 1)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Label proof. \(label.style.title), \(label.flock), \(label.eggs) eggs Collection date: \(label.packedOn.formatted(Date.FormatStyle(date: .numeric, time: .omitted, locale: Locale(identifier: "en_US")))). \(label.note)")
    }
}

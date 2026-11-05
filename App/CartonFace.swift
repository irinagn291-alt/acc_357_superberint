import SwiftUI

/// The same fixed print area is scaled for the screen, sheets, and individual labels.
struct CartonFace: View {
    let label: CartonLabel

    private let ink = Color(red: 24/255, green: 60/255, blue: 48/255)
    private let red = Color(red: 188/255, green: 62/255, blue: 43/255)
    private let paper = Color(red: 250/255, green: 242/255, blue: 217/255)
    private let maize = Color(red: 250/255, green: 210/255, blue: 115/255)

    private var units: String { label.eggs == 1 ? "EGG" : "EGGS" }

    private var date: String {
        label.packedOn.formatted(
            Date.FormatStyle(date: .omitted, time: .omitted, locale: Locale(identifier: "en_US"))
                .day(.twoDigits).month(.twoDigits).year()
        )
    }

    var body: some View {
        Group {
            switch label.style {
            case .farm: farm
            case .market: market
            case .minimal: minimal
            }
        }
        .frame(width: 300, height: 187.5)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityElement(children: .combine)
    }

    private var farm: some View {
        ZStack {
            paper
            HeritageBorder(cut: 10)
                .stroke(ink, lineWidth: 1.8)
                .padding(5.5)
            HeritageBorder(cut: 8)
                .stroke(ink, lineWidth: 0.6)
                .padding(8.5)

            VStack(spacing: 0) {
                HStack(spacing: 5) {
                    flourish
                    caption("FRESH EGGS", size: 8.5, tracking: 1.6)
                    flourish.rotationEffect(.degrees(180))
                }
                .frame(height: 15)

                HStack(spacing: 4) {
                    VStack(alignment: .leading, spacing: 2) {
                        caption("FARM FRESH", size: 6.5, tracking: 1.1)
                            .foregroundStyle(red)
                        name(font: .custom("Georgia-Bold", fixedSize: 26), height: 55)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HenPrint()
                        .frame(width: 87, height: 68)
                        .accessibilityHidden(true)
                }
                .frame(height: 76)

                HStack(spacing: 10) {
                    field("COLLECTED ON", value: date)
                    Spacer(minLength: 0)
                    Diamond().fill(red).frame(width: 5, height: 5)
                    Spacer(minLength: 0)
                    field("PER CARTON", value: "\(label.eggs) eggs", align: .trailing)
                }
                .padding(.horizontal, 2)
                .frame(height: 34)
                .overlay(alignment: .top) { Rectangle().fill(ink).frame(height: 0.8) }

                note(font: .custom("Georgia-Italic", fixedSize: 10.5))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(ink)
            .padding(.horizontal, 22)
        }
    }

    private var market: some View {
        ZStack {
            maize
            VStack(spacing: 0) {
                HStack {
                    caption("MARKET EDITION", size: 7.5, tracking: 1.1)
                    Spacer()
                    caption("FRESH EGGS", size: 7.5, tracking: 1.1)
                }
                .foregroundStyle(paper)
                .padding(.horizontal, 12)
                .frame(height: 23)
                .background(red)

                HStack(spacing: 10) {
                    VStack(spacing: -3) {
                        Text(verbatim: "\(label.eggs)")
                            .font(.system(size: 57, weight: .black))
                            .tracking(-3)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                        caption(units, size: 9, tracking: 1)
                    }
                    .foregroundStyle(red)
                    .frame(width: 75)
                    Rectangle().fill(red).frame(width: 1)
                        .padding(.vertical, 8)
                    VStack(alignment: .leading, spacing: 2) {
                        caption("FROM OUR FARM", size: 6.5, tracking: 1)
                        name(font: .system(size: 23, weight: .black), height: 53)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(ink)
                }
                .padding(.horizontal, 10)
                .frame(height: 82)

                HStack(alignment: .center, spacing: 6) {
                    caption("COLLECTED ON", size: 7, tracking: 1.1)
                    Rectangle().fill(red).frame(height: 0.7)
                    Text(verbatim: date)
                        .font(.system(size: 12.5, weight: .heavy, design: .monospaced))
                        .fixedSize()
                }
                .foregroundStyle(ink)
                .padding(.horizontal, 12)
                .frame(height: 24)
                .overlay(alignment: .top) { Rectangle().fill(red).frame(height: 1.2) }

                note(font: .system(size: 10, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .foregroundStyle(ink)
                MarketChecks()
                    .fill(red)
                    .frame(height: 5)
            }
            .overlay { Rectangle().strokeBorder(red, lineWidth: 1.25) }
            .padding(.horizontal, 7)
        }
    }

    private var minimal: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Circle().fill(red).frame(width: 6, height: 6)
                    caption("FRESH EGGS", size: 7, tracking: 1.25)
                    Spacer(minLength: 0)
                }
                .frame(height: 15)
                Rectangle().fill(ink).frame(height: 1)
                    .padding(.top, 3)
                name(font: .system(size: 28, weight: .medium), height: 70)
                HStack(alignment: .firstTextBaseline) {
                    caption("COLLECTED ON", size: 6.8, tracking: 0.7)
                    Spacer(minLength: 4)
                    Text(verbatim: date)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                }
                .frame(height: 23)
                .overlay(alignment: .top) { Rectangle().fill(ink).frame(height: 0.65) }

                note(font: .system(size: 10, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(ink)
            .padding(.horizontal, 13)
            .frame(maxWidth: .infinity)

            VStack(spacing: 1) {
                EggStack().stroke(paper, lineWidth: 1.4)
                    .frame(width: 48, height: 68)
                    .accessibilityHidden(true)
                Rectangle().fill(maize).frame(width: 23, height: 1)
                    .padding(.vertical, 8)
                Text(verbatim: "\(label.eggs)")
                    .font(.system(size: 32, weight: .light, design: .monospaced))
                caption(units, size: 6.8, tracking: 1.2)
            }
            .foregroundStyle(paper)
            .frame(width: 68)
            .frame(maxHeight: .infinity)
            .background(ink)
        }
        .background(paper)
        .overlay { Rectangle().strokeBorder(ink, lineWidth: 1.4) }
    }

    private func name(font: Font, height: CGFloat) -> some View {
        Text(verbatim: label.flock)
            .font(font)
            .lineLimit(2)
            .minimumScaleFactor(0.41)
            .allowsTightening(true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: height, alignment: .leading)
    }

    private func note(font: Font) -> some View {
        Text(verbatim: label.note)
            .font(font)
            .lineLimit(2)
            .minimumScaleFactor(0.59)
            .allowsTightening(true)
            .frame(height: 28)
    }

    private func caption(_ text: String, size: CGFloat, tracking: CGFloat) -> some View {
        Text(verbatim: text)
            .font(.system(size: size, weight: .bold, design: .monospaced))
            .tracking(tracking)
            .lineLimit(1)
            .fixedSize()
    }

    private func field(_ title: String, value: String, align: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: align, spacing: 0.5) {
            caption(title, size: 6, tracking: 0.8)
            Text(verbatim: value).font(.custom("Georgia-Bold", fixedSize: 12))
        }
    }

    private var flourish: some View {
        HStack(spacing: 2) {
            Rectangle().fill(ink).frame(height: 0.65)
            Diamond().fill(ink).frame(width: 5, height: 4)
        }
        .frame(width: 38)
    }
}

private struct Diamond: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.midX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
            p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.midY))
            p.closeSubpath()
        }
    }
}

private struct HeritageBorder: Shape {
    let cut: CGFloat

    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.minX + cut, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX - cut, y: r.minY))
            p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + cut),
                           control: CGPoint(x: r.maxX - cut, y: r.minY + cut))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - cut))
            p.addQuadCurve(to: CGPoint(x: r.maxX - cut, y: r.maxY),
                           control: CGPoint(x: r.maxX - cut, y: r.maxY - cut))
            p.addLine(to: CGPoint(x: r.minX + cut, y: r.maxY))
            p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - cut),
                           control: CGPoint(x: r.minX + cut, y: r.maxY - cut))
            p.addLine(to: CGPoint(x: r.minX, y: r.minY + cut))
            p.addQuadCurve(to: CGPoint(x: r.minX + cut, y: r.minY),
                           control: CGPoint(x: r.minX + cut, y: r.minY + cut))
            p.closeSubpath()
        }
    }
}

private struct MarketChecks: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            let count = 48
            let width = r.width / CGFloat(count)
            for cell in 0..<count {
                let top = CGFloat(cell % 2) * r.height / 2
                p.addRect(CGRect(x: r.minX + CGFloat(cell) * width, y: r.minY + top,
                                 width: width, height: r.height / 2))
            }
        }
    }
}

private struct EggStack: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            for i in 0..<3 {
                let offset = CGFloat(i) * 12
                p.move(to: CGPoint(x: 24, y: 4 + offset))
                p.addCurve(to: CGPoint(x: 10, y: 31 + offset),
                           control1: CGPoint(x: 16, y: 5 + offset),
                           control2: CGPoint(x: 10, y: 21 + offset))
                p.addCurve(to: CGPoint(x: 38, y: 31 + offset),
                           control1: CGPoint(x: 10, y: 47 + offset),
                           control2: CGPoint(x: 38, y: 47 + offset))
                p.addCurve(to: CGPoint(x: 24, y: 4 + offset),
                           control1: CGPoint(x: 38, y: 21 + offset),
                           control2: CGPoint(x: 32, y: 5 + offset))
                p.closeSubpath()
            }
        }
    }
}

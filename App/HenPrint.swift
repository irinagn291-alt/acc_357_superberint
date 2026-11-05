import SwiftUI

/// A three-ink engraving. The incised feather marks reveal the paper beneath it.
struct HenPrint: View {
    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 240, size.height / 155)
            context.withCGContext { cg in
                cg.translateBy(x: (size.width - 240 * scale) / 2,
                               y: (size.height - 155 * scale) / 2)
                cg.scaleBy(x: scale, y: scale)
                Self.impress(in: cg)
            }
        }
        .accessibilityHidden(true)
    }

    static func impress(in cg: CGContext) {
        let pine = CGColor(red: 24/255, green: 60/255, blue: 48/255, alpha: 1)
        let brick = CGColor(red: 183/255, green: 61/255, blue: 38/255, alpha: 1)
        let gold = CGColor(red: 213/255, green: 151/255, blue: 49/255, alpha: 1)
        func move(_ x: CGFloat, _ y: CGFloat) { cg.move(to: CGPoint(x: x, y: y)) }
        func line(_ x: CGFloat, _ y: CGFloat) { cg.addLine(to: CGPoint(x: x, y: y)) }
        func curve(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat, _ x: CGFloat, _ y: CGFloat) {
            cg.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: a, y: b), control2: CGPoint(x: c, y: d))
        }
        func fill(_ color: CGColor) {
            cg.closePath()
            cg.setFillColor(color)
            cg.fillPath()
        }
        func stroke(_ color: CGColor, _ width: CGFloat) {
            cg.setStrokeColor(color)
            cg.setLineWidth(width)
            cg.strokePath()
        }

        cg.saveGState()
        cg.beginTransparencyLayer(auxiliaryInfo: nil)
        cg.setLineJoin(.round)
        cg.setLineCap(.round)

        // A few dry strokes ground the bird without putting it on a badge.
        move(29, 143); curve(40, 141, 59, 140, 70, 141)
        move(45, 146); curve(54, 144, 74, 144, 86, 144)
        move(79, 141); line(91, 140)
        move(103, 148); curve(117, 147, 127, 147, 139, 147)
        move(151, 144); curve(166, 142, 184, 144, 192, 143)
        move(180, 147); line(196, 146)
        move(195, 141); line(211, 139)
        stroke(pine, 1.1)

        // Spurs, ankles and splayed toes.
        move(103, 112); line(111, 113); line(104, 128); line(100, 136)
        line(112, 138); line(116, 141); line(104, 139); line(113, 144)
        line(110, 145); line(98, 139); line(88, 142); line(84, 141)
        line(95, 136); line(101, 121); line(97, 124); fill(pine)
        move(128, 112); line(135, 111); line(131, 123); line(134, 136)
        line(148, 138); line(153, 141); line(138, 140); line(148, 145)
        line(146, 146); line(133, 141); line(122, 145); line(118, 144)
        line(129, 137); line(126, 126); line(122, 129); fill(pine)
        move(107, 119); line(100, 135)
        move(130, 125); line(132, 136)
        stroke(gold, 1.4)

        // Tail fans into the rump; the high breast and small head set the hen's profile.
        move(178, 29)
        curve(170, 27, 161, 31, 156, 41)
        curve(150, 54, 145, 59, 134, 63)
        curve(116, 69, 96, 70, 81, 63)
        curve(65, 55, 49, 33, 21, 30)
        curve(26, 39, 36, 46, 46, 53)
        curve(35, 45, 21, 41, 10, 42)
        curve(14, 50, 25, 59, 42, 65)
        curve(30, 59, 21, 59, 13, 59)
        curve(18, 66, 30, 74, 43, 78)
        curve(36, 76, 28, 75, 23, 76)
        curve(32, 85, 45, 91, 57, 92)
        line(45, 92); curve(52, 99, 60, 102, 70, 102)
        line(65, 104); curve(69, 109, 78, 110, 85, 110)
        line(82, 113); curve(90, 114, 97, 118, 102, 122)
        line(109, 120); line(113, 121); line(117, 118)
        curve(121, 120, 125, 122, 129, 124)
        line(136, 118); line(139, 119); line(142, 115)
        curve(159, 110, 175, 100, 181, 87)
        curve(186, 77, 185, 64, 190, 55)
        curve(193, 51, 198, 49, 198, 43)
        curve(199, 34, 190, 28, 178, 29)
        fill(pine)

        // The red plate is slightly offset from the outline as in a relief print.
        move(163, 35)
        curve(158, 32, 160, 27, 164, 24)
        curve(164, 29, 167, 27, 168, 25)
        curve(165, 19, 168, 12, 171, 9)
        curve(174, 14, 173, 19, 177, 21)
        curve(176, 15, 179, 9, 183, 7)
        curve(186, 13, 181, 18, 185, 20)
        curve(188, 16, 191, 14, 194, 14)
        curve(196, 20, 191, 23, 194, 25)
        curve(197, 23, 200, 21, 202, 22)
        curve(203, 30, 197, 33, 192, 34)
        curve(186, 30, 173, 28, 163, 35)
        fill(brick)
        move(191, 49)
        curve(196, 47, 199, 50, 198, 55)
        curve(198, 60, 202, 63, 198, 66)
        curve(190, 71, 186, 61, 188, 56)
        curve(185, 61, 181, 60, 182, 56)
        curve(182, 53, 186, 52, 191, 49)
        fill(brick)

        move(197, 40); curve(204, 39, 211, 42, 216, 47)
        line(206, 48); line(197, 51); line(194, 48); fill(gold)
        move(198, 46); curve(205, 45, 208, 46, 212, 46)
        stroke(pine, 1.2)

        // A single sweeping greater covert, split into slender, tapered barbs.
        cg.setBlendMode(.clear)
        move(144, 68)
        curve(128, 77, 110, 70, 93, 71)
        curve(75, 72, 68, 78, 54, 79)
        curve(69, 80, 74, 75, 86, 74)
        curve(77, 78, 65, 82, 54, 84)
        curve(73, 84, 81, 76, 94, 75)
        curve(84, 80, 69, 88, 58, 89)
        curve(78, 91, 91, 76, 105, 76)
        curve(98, 81, 79, 94, 65, 96)
        curve(86, 96, 100, 82, 113, 77)
        curve(105, 88, 89, 98, 75, 101)
        curve(92, 101, 111, 88, 120, 78)
        curve(116, 89, 101, 100, 87, 105)
        curve(109, 101, 119, 88, 127, 77)
        curve(124, 87, 119, 94, 112, 100)
        curve(127, 93, 135, 78, 144, 68)
        fill(pine)

        // Long cuts follow the direction of the tail, throat and breast feathers.
        move(28, 35); curve(45, 41, 57, 57, 73, 63)
        move(19, 46); curve(37, 53, 51, 67, 64, 70)
        move(23, 62); curve(34, 65, 45, 75, 56, 76)
        move(35, 80); curve(39, 83, 45, 85, 49, 86)
        move(154, 46); curve(156, 40, 160, 35, 167, 34)
        move(153, 55); curve(156, 51, 158, 48, 159, 44)
        move(147, 66); curve(155, 60, 162, 53, 165, 44)
        move(146, 76); curve(154, 70, 164, 62, 168, 51)
        move(153, 79); curve(162, 72, 169, 65, 172, 55)
        move(160, 82); curve(171, 73, 176, 62, 177, 57)
        move(167, 86); curve(175, 77, 178, 69, 180, 63)
        move(113, 112); curve(121, 110, 131, 103, 136, 96)
        move(134, 109); curve(140, 106, 147, 99, 150, 95)
        stroke(pine, 1.45)
        move(35, 35); curve(47, 40, 61, 57, 73, 59)
        move(19, 50); curve(30, 57, 47, 67, 53, 69)
        move(141, 65); curve(146, 63, 150, 59, 152, 56)
        move(158, 64); curve(163, 60, 166, 55, 167, 52)
        move(163, 72); curve(167, 68, 172, 62, 173, 58)
        move(173, 83); curve(175, 80, 179, 75, 180, 70)
        move(102, 109); curve(106, 108, 113, 104, 118, 101)
        move(122, 114); curve(129, 112, 135, 108, 140, 102)
        move(143, 105); curve(150, 102, 155, 95, 158, 92)
        move(155, 101); curve(158, 99, 162, 94, 164, 91)
        stroke(pine, 0.8)

        // Cheek and eye are cut last to keep their edges crisp.
        move(168, 43); curve(173, 38, 176, 36, 183, 36)
        move(171, 48); curve(177, 50, 182, 50, 187, 47)
        move(178, 52); line(183, 51)
        stroke(pine, 1.3)
        cg.fillEllipse(in: CGRect(x: 181.4, y: 37.5, width: 8.5, height: 7.7))
        cg.setBlendMode(.normal)
        cg.setFillColor(gold)
        cg.fillEllipse(in: CGRect(x: 182.4, y: 38.3, width: 6.6, height: 6))
        cg.setFillColor(pine)
        cg.fillEllipse(in: CGRect(x: 184.6, y: 39.3, width: 3.6, height: 3.7))
        cg.endTransparencyLayer()
        cg.restoreGState()
    }
}

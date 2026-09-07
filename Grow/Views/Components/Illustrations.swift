import SwiftUI

    /// 插画加载：
    /// - "img:<名称>"：加载 Resources/Images/<名称>.heic 实物图/水墨插图（HEIF 压缩率更高），回退 .jpg/.png
    /// - 固定标识：SwiftUI 矢量插画
    /// - "emoji:🌿"：柔和光晕 + emoji（兜底占位）
struct IllustrationView: View {
    let identifier: String

    private static let cache = NSCache<NSString, UIImage>()

    static func bundleImage(_ name: String) -> UIImage? {
        if let hit = cache.object(forKey: name as NSString) { return hit }
        let url = Bundle.main.url(forResource: name, withExtension: "heic", subdirectory: "Images")
            ?? Bundle.main.url(forResource: name, withExtension: "jpg", subdirectory: "Images")
            ?? Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Images")
            ?? Bundle.main.url(forResource: name, withExtension: "heic")
            ?? Bundle.main.url(forResource: name, withExtension: "jpg")
        guard let url, let img = UIImage(contentsOfFile: url.path) else { return nil }
        cache.setObject(img, forKey: name as NSString)
        return img
    }

    var body: some View {
        if identifier.hasPrefix("img:") {
            let name = String(identifier.dropFirst(4))
            if let ui = Self.bundleImage(name) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                EmojiIllustration(emoji: "🌿")
            }
        } else if identifier.hasPrefix("emoji:") {
            EmojiIllustration(emoji: String(identifier.dropFirst(6)))
        } else {
            switch identifier {
            case "apple": AppleIllustration()
            case "panda": PandaIllustration()
            case "sunflower": SunflowerIllustration()
            default: PlaceholderIllustration()
            }
        }
    }
}

/// 大图横幅（古诗详情页顶部）：填满裁切
struct IllustrationBanner: View {
    let identifier: String

    var body: some View {
        Group {
            if identifier.hasPrefix("img:"),
               let ui = IllustrationView.bundleImage(String(identifier.dropFirst(4))) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                IllustrationView(identifier: identifier)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .clipped()
    }
}

// MARK: - Emoji 占位插画（柔和光晕底 + 大 emoji）

struct EmojiIllustration: View {
    let emoji: String

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color.white.opacity(0.9), .clear], center: .center, startRadius: 0, endRadius: w * 0.46))
                    .frame(width: w * 0.92, height: w * 0.92)
                Text(emoji)
                    .font(.system(size: w * 0.42))
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - 占位

struct PlaceholderIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [Theme.creamDeep, Theme.cream], startPoint: .top, endPoint: .bottom))
            Image(systemName: "leaf.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.inkSoft.opacity(0.4))
        }
    }
}

// MARK: - 苹果

struct AppleIllustration: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                // 背景光晕
                Circle()
                    .fill(RadialGradient(colors: [Color.white.opacity(0.9), .clear], center: .center, startRadius: 0, endRadius: w * 0.42))
                    .frame(width: w * 0.84, height: w * 0.84)

                // 果柄
                RoundedRectangle(cornerRadius: w * 0.03)
                    .fill(Color(red: 0.45, green: 0.33, blue: 0.22))
                    .frame(width: w * 0.055, height: w * 0.16)
                    .offset(y: -w * 0.30)

                // 叶子
                LeafShape()
                    .fill(LinearGradient(colors: [Color(red: 0.45, green: 0.72, blue: 0.38), Color(red: 0.32, green: 0.60, blue: 0.30)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: w * 0.26, height: w * 0.14)
                    .rotationEffect(.degrees(-24))
                    .offset(x: w * 0.14, y: -w * 0.30)

                // 果身（两瓣圆形相叠）
                AppleBodyShape()
                    .fill(LinearGradient(
                        colors: [Color(red: 0.95, green: 0.42, blue: 0.38), Color(red: 0.82, green: 0.24, blue: 0.26)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: w * 0.66, height: w * 0.62)
                    .shadow(color: Color(red: 0.82, green: 0.24, blue: 0.26).opacity(0.25), radius: w * 0.05, y: w * 0.03)

                // 高光
                Ellipse()
                    .fill(LinearGradient(colors: [.white.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.16, height: w * 0.24)
                    .rotationEffect(.degrees(-18))
                    .offset(x: -w * 0.15, y: -w * 0.12)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// 苹果身体：顶部略凹的两圆相融形
struct AppleBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = rect.width * 0.34
        p.addEllipse(in: CGRect(x: rect.midX - r, y: rect.height * 0.28, width: r * 2, height: r * 2))
        p.addEllipse(in: CGRect(x: rect.midX - r, y: rect.height * 0.22, width: r * 2, height: r * 2).offsetBy(dx: rect.width * 0.02, dy: rect.height * 0.08))
        // 底部补一块融合
        p.addEllipse(in: CGRect(x: rect.midX - r * 0.92, y: rect.height * 0.30, width: r * 1.84, height: r * 1.6))
        return p
    }
}

struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.midY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.midX, y: -rect.height * 0.35))
        p.addQuadCurve(to: CGPoint(x: 0, y: rect.midY), control: CGPoint(x: rect.midX, y: rect.height * 1.35))
        return p
    }
}

// MARK: - 熊猫

struct PandaIllustration: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let black = Color(red: 0.20, green: 0.20, blue: 0.22)
            let white = Color(red: 0.99, green: 0.99, blue: 0.98)
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color.white.opacity(0.85), .clear], center: .center, startRadius: 0, endRadius: w * 0.44))
                    .frame(width: w * 0.88, height: w * 0.88)

                // 耳朵
                ForEach([-1, 1], id: \.self) { s in
                    Circle()
                        .fill(black)
                        .frame(width: w * 0.24, height: w * 0.24)
                        .offset(x: s * w * 0.20, y: -w * 0.22)
                }

                // 脸
                Ellipse()
                    .fill(white)
                    .frame(width: w * 0.70, height: w * 0.62)
                    .shadow(color: .black.opacity(0.08), radius: w * 0.03, y: w * 0.02)

                // 眼斑
                ForEach([-1, 1], id: \.self) { s in
                    ZStack {
                        Ellipse()
                            .fill(black)
                            .frame(width: w * 0.17, height: w * 0.21)
                            .rotationEffect(.degrees(Double(s) * 18))
                        // 眼睛高光
                        Circle()
                            .fill(.white)
                            .frame(width: w * 0.045)
                            .offset(x: w * 0.015, y: -w * 0.02)
                    }
                    .offset(x: s * w * 0.155, y: -w * 0.05)
                }

                // 鼻子 + 嘴
                Ellipse()
                    .fill(black)
                    .frame(width: w * 0.09, height: w * 0.065)
                    .offset(y: w * 0.10)
                SmileShape()
                    .stroke(black, style: StrokeStyle(lineWidth: w * 0.02, lineCap: .round))
                    .frame(width: w * 0.14, height: w * 0.06)
                    .offset(y: w * 0.175)

                // 竹子
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 3).fill(Color(red: 0.42, green: 0.68, blue: 0.38))
                        .frame(width: w * 0.05, height: w * 0.28)
                    RoundedRectangle(cornerRadius: 3).fill(Color(red: 0.36, green: 0.62, blue: 0.34))
                        .frame(width: w * 0.05, height: w * 0.14)
                }
                .offset(x: w * 0.30, y: w * 0.16)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.midX, y: rect.maxY * 1.6))
        return p
    }
}

// MARK: - 向日葵

struct SunflowerIllustration: View {
    private let petalCount = 14
    private let petalColor = [Color(red: 0.99, green: 0.80, blue: 0.28), Color(red: 0.95, green: 0.68, blue: 0.20)]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                glowCircle(width: w * 0.88)

                // 茎和叶
                stemView(w: w)

                // 花瓣（两层错位）
                petalLayer(w: w)
                petalLayer(w: w, inner: true)

                // 花盘
                Circle()
                    .fill(RadialGradient(colors: [Color(red: 0.52, green: 0.36, blue: 0.20), Color(red: 0.40, green: 0.27, blue: 0.15)], center: .center, startRadius: 0, endRadius: w * 0.16))
                    .frame(width: w * 0.30, height: w * 0.30)
                seedLayer(w: w)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func glowCircle(width: CGFloat) -> some View {
        Circle()
            .fill(RadialGradient(colors: [Color.white.opacity(0.85), .clear], center: .center, startRadius: 0, endRadius: width * 0.5))
            .frame(width: width, height: width)
    }

    private func stemView(w: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: w * 0.02)
                .fill(LinearGradient(colors: [Color(red: 0.42, green: 0.66, blue: 0.36), Color(red: 0.35, green: 0.58, blue: 0.32)], startPoint: .top, endPoint: .bottom))
                .frame(width: w * 0.045, height: w * 0.40)
                .offset(y: w * 0.30)
            LeafShape()
                .fill(Color(red: 0.42, green: 0.66, blue: 0.36))
                .frame(width: w * 0.22, height: w * 0.12)
                .rotationEffect(.degrees(-30))
                .offset(x: -w * 0.14, y: w * 0.30)
            LeafShape()
                .fill(Color(red: 0.38, green: 0.62, blue: 0.34))
                .frame(width: w * 0.22, height: w * 0.12)
                .scaleEffect(x: -1)
                .rotationEffect(.degrees(-30))
                .offset(x: w * 0.14, y: w * 0.36)
        }
    }

    private func petalLayer(w: CGFloat, inner: Bool = false) -> some View {
        let petalW: CGFloat = inner ? w * 0.10 : w * 0.115
        let petalH: CGFloat = inner ? w * 0.24 : w * 0.30
        let offsetY: CGFloat = inner ? -w * 0.17 : -w * 0.20
        let halfStep = 360.0 / Double(petalCount) / 2

        return ForEach(0..<petalCount, id: \.self) { i in
            let base = Double(i) / Double(petalCount) * 360
            let angle = inner ? base + halfStep : base
            let color = petalColor[inner ? (i + 1) % 2 : i % 2]
            // 以整幅画布为容器旋转，使花瓣围绕花盘中心放射排列
            Color.clear
                .frame(width: w, height: w)
                .overlay(
                    PetalShape()
                        .fill(color.opacity(inner ? 0.92 : 1.0))
                        .frame(width: petalW, height: petalH)
                        .offset(y: offsetY)
                )
                .rotationEffect(.degrees(angle))
        }
    }

    private func seedLayer(w: CGFloat) -> some View {
        // 花盘籽点：一圈均匀分布的小点
        ForEach(0..<12, id: \.self) { i in
            let angle = Double(i) / 12 * 2 * .pi
            Circle()
                .fill(Color.black.opacity(0.15))
                .frame(width: w * 0.024)
                .offset(x: CGFloat(cos(angle)) * w * 0.075, y: CGFloat(sin(angle)) * w * 0.075)
        }
    }
}

/// 花瓣：椭圆尖头形
struct PetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX + rect.width * 0.25, y: rect.midY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX - rect.width * 0.25, y: rect.midY))
        return p
    }
}

// MARK: - 《静夜思》：夜、窗、月光、床

struct NightRoomIllustration: View {
    private static let nightTop = Color(red: 0.16, green: 0.22, blue: 0.38)
    private static let nightBottom = Color(red: 0.28, green: 0.36, blue: 0.52)

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // 夜空
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LinearGradient(colors: [Self.nightTop, Self.nightBottom], startPoint: .top, endPoint: .bottom))

                starField(w: w, h: h)

                // 月亮
                Circle()
                    .fill(RadialGradient(colors: [Color(red: 1.0, green: 0.96, blue: 0.80), Color(red: 0.98, green: 0.90, blue: 0.62)], center: .center, startRadius: 0, endRadius: w * 0.12))
                    .frame(width: w * 0.20)
                    .offset(x: w * 0.26, y: -h * 0.22)
                    .shadow(color: Color(red: 1.0, green: 0.94, blue: 0.7).opacity(0.5), radius: w * 0.08)

                // 地面（月光洒落）
                Rectangle()
                    .fill(Color(red: 0.72, green: 0.70, blue: 0.62).opacity(0.55))
                    .frame(height: h * 0.22)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                // 月光光斑
                Ellipse()
                    .fill(LinearGradient(colors: [Color.white.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.5, height: h * 0.16)
                    .offset(x: -w * 0.1, y: h * 0.30)

                // 窗
                WindowFrame()
                    .stroke(Color(red: 0.88, green: 0.82, blue: 0.68), style: StrokeStyle(lineWidth: w * 0.025, lineCap: .round))
                    .frame(width: w * 0.34, height: h * 0.30)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(red: 0.55, green: 0.62, blue: 0.60).opacity(0.5)))
                    .offset(x: w * 0.05, y: -h * 0.02)

                // 床
                BedShape()
                    .fill(Color(red: 0.48, green: 0.36, blue: 0.28))
                    .frame(width: w * 0.34, height: h * 0.20)
                    .offset(x: -w * 0.26, y: h * 0.22)

                // 小人（诗人剪影）
                PoetSilhouette()
                    .fill(Color(red: 0.14, green: 0.16, blue: 0.24))
                    .frame(width: w * 0.10, height: h * 0.22)
                    .offset(x: -w * 0.05, y: h * 0.14)
            }
        }
        .aspectRatio(0.9, contentMode: .fit)
    }

    private func starField(w: CGFloat, h: CGFloat) -> some View {
        ForEach(0..<16, id: \.self) { i in
            let opacity = 0.5 + Double(i % 4) * 0.12
            let size = CGFloat(2 + i % 3)
            let dx = CGFloat(sin(Double(i) * 2.7)) * w * 0.36
            let dy = CGFloat(cos(Double(i) * 1.9)) * h * 0.20 - h * 0.16
            Circle()
                .fill(.white.opacity(opacity))
                .frame(width: size)
                .offset(x: dx, y: dy)
        }
    }
}

struct WindowFrame: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRoundedRect(in: rect, cornerSize: CGSize(width: 6, height: 6))
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

struct BedShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // 床板
        p.addRoundedRect(in: CGRect(x: 0, y: rect.height * 0.45, width: rect.width, height: rect.height * 0.5), cornerSize: CGSize(width: 6, height: 6))
        // 床头
        p.addRoundedRect(in: CGRect(x: 0, y: 0, width: rect.width * 0.14, height: rect.height), cornerSize: CGSize(width: 5, height: 5))
        return p
    }
}

struct PoetSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // 头
        p.addEllipse(in: CGRect(x: rect.width * 0.25, y: 0, width: rect.width * 0.5, height: rect.width * 0.5))
        // 身
        p.addRoundedRect(in: CGRect(x: rect.width * 0.28, y: rect.width * 0.55, width: rect.width * 0.44, height: rect.height * 0.55), cornerSize: CGSize(width: 8, height: 8))
        return p
    }
}

// MARK: - 《咏鹅》：池塘、白鹅、水波

struct GoosePondIllustration: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let pondTop = Color(red: 0.55, green: 0.78, blue: 0.72)
            let pondBottom = Color(red: 0.32, green: 0.60, blue: 0.60)
            ZStack {
                // 池塘
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LinearGradient(colors: [pondTop, pondBottom], startPoint: .top, endPoint: .bottom))

                // 远处芦苇
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 0.38, green: 0.56, blue: 0.38).opacity(0.7))
                        .frame(width: w * 0.012, height: h * (0.14 + CGFloat(i % 3) * 0.04))
                        .rotationEffect(.degrees(Double(i - 2) * 6))
                        .offset(x: w * (CGFloat(i) * 0.06 - 0.32), y: -h * 0.26)
                }

                // 水波
                ForEach(0..<3, id: \.self) { i in
                    RippleShape()
                        .stroke(.white.opacity(0.35 - Double(i) * 0.08), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .frame(width: w * (0.4 + CGFloat(i) * 0.14), height: h * 0.05)
                        .offset(y: h * (0.16 + CGFloat(i) * 0.09))
                }

                // 鹅身
                GooseBodyShape()
                    .fill(LinearGradient(colors: [Color(red: 0.99, green: 0.98, blue: 0.95), Color(red: 0.94, green: 0.92, blue: 0.86)], startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.52, height: h * 0.42)
                    .offset(x: w * 0.02, y: h * 0.04)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

                // 鹅颈与头
                NeckGooseShape()
                    .fill(Color(red: 0.99, green: 0.98, blue: 0.95))
                    .frame(width: w * 0.26, height: h * 0.42)
                    .offset(x: -w * 0.16, y: -h * 0.16)

                // 红掌
                WebFootShape()
                    .fill(Color(red: 0.92, green: 0.52, blue: 0.34))
                    .frame(width: w * 0.12, height: h * 0.05)
                    .offset(x: w * 0.10, y: h * 0.235)
            }
        }
        .aspectRatio(0.9, contentMode: .fit)
    }
}

struct RippleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.midX, y: rect.maxY))
        return p
    }
}

/// 白鹅：身体 + 尾部上翘
struct GooseBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: rect.width * 0.05, y: rect.height * 0.15, width: rect.width * 0.8, height: rect.height * 0.75))
        // 尾巴上翘
        p.move(to: CGPoint(x: rect.width * 0.78, y: rect.height * 0.35))
        p.addQuadCurve(to: CGPoint(x: rect.width * 0.98, y: rect.height * 0.05), control: CGPoint(x: rect.width * 0.95, y: rect.height * 0.25))
        p.addQuadCurve(to: CGPoint(x: rect.width * 0.72, y: rect.height * 0.25), control: CGPoint(x: rect.width * 0.86, y: rect.height * 0.18))
        return p
    }
}

/// 鹅的曲项：白毛浮绿水，红掌拨清波
struct NeckGooseShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let headR = rect.width * 0.30
        // 头
        p.addEllipse(in: CGRect(x: rect.width * 0.06, y: 0, width: headR * 2, height: headR * 2))
        // 嘴
        p.move(to: CGPoint(x: rect.width * 0.03, y: headR * 0.95))
        p.addLine(to: CGPoint(x: -rect.width * 0.18, y: headR * 1.15))
        p.addLine(to: CGPoint(x: rect.width * 0.04, y: headR * 1.35))
        p.closeSubpath()
        // 弯曲的脖子
        p.move(to: CGPoint(x: rect.width * 0.32, y: headR * 1.6))
        p.addQuadCurve(to: CGPoint(x: rect.width * 0.72, y: rect.height), control: CGPoint(x: rect.width * 0.9, y: rect.height * 0.42))
        p.addLine(to: CGPoint(x: rect.width * 0.40, y: rect.height))
        p.addQuadCurve(to: CGPoint(x: rect.width * 0.16, y: headR * 1.7), control: CGPoint(x: rect.width * 0.56, y: rect.height * 0.45))
        p.closeSubpath()
        return p
    }
}

struct WebFootShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

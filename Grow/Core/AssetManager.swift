import UIKit

/// 统一资产门面（§23 AssetManager）：图片加载 + NSCache + 按需加载
/// 图片资源统一 720×720；缓存数量上限控制内存，淘汰交给 NSCache。
enum AssetManager {
    private static let imageCache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 120
        return c
    }()

    /// 从 App Bundle 加载内容图片（Images 目录，heic/jpg/png），带缓存
    static func bundleImage(_ name: String) -> UIImage? {
        if let hit = imageCache.object(forKey: name as NSString) { return hit }
        guard let image = loadUncached(name) else { return nil }
        imageCache.setObject(image, forKey: name as NSString)
        return image
    }

    private static func loadUncached(_ name: String) -> UIImage? {
        let url = Bundle.main.url(forResource: name, withExtension: "heic", subdirectory: "Images")
            ?? Bundle.main.url(forResource: name, withExtension: "jpg", subdirectory: "Images")
            ?? Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Images")
            ?? Bundle.main.url(forResource: name, withExtension: "heic")
            ?? Bundle.main.url(forResource: name, withExtension: "jpg")
        if let url, let image = UIImage(contentsOfFile: url.path) {
            return image
        }
        // 兜底：Asset Catalog 内命名资源
        return UIImage(named: name)
    }
}

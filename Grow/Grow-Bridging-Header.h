// Grow-Bridging-Header.h
// 桥接 sherpa-onnx C API（Vendor 内静态 framework），供 Swift 直接调用。
// 注：不走 clang module import（xcframework 嵌套模块在 app target 中不可靠），直接引入头文件。
#import "../Vendor/sherpa-onnx.xcframework/ios-arm64/SherpaOnnxC.framework/Headers/sherpa-onnx/c-api/c-api.h"

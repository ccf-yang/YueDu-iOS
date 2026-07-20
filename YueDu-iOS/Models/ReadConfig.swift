import Foundation

/// 阅读配置
struct ReadConfig: Codable {
    var reverseToc: Bool = false
    var pageAnim: Int = 0           // 0=覆盖,1=平移,2=仿真,3=无动画
    var splitLongChapter: Bool = true
    var removeWhiteSpace: Bool = true
    var indentCount: Int = 2
    var paddingLeft: Int = 16
    var paddingRight: Int = 16
    var paddingTop: Int = 20
    var paddingBottom: Int = 20
    var headerPaddingTop: Int = 8
    var footerPaddingBottom: Int = 8
    var showTimeLine: Bool = true
    var hideStatusBar: Bool = false
    var autoReadSpeed: Int = 46     // 每分钟翻页数
    var textBold: Bool = false
    var textColor: String?
    var bgColor: String?
    var bgIndex: Int = 0
    var fontSize: Int = 16
    var lineSpacingExtra: Int = 8
    var paragraphSpacing: Int = 6
    var fontName: String = "系统默认"
    var screenTimeOut: Int = 0      // 0=跟随系统
    var volumeKeyPage: Bool = false

    static let `default` = ReadConfig()
}

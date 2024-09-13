//
//  InstalledApp.swift
//  TrollInstallerX
//
//  Created by Alfie on 29/03/2024.
//

import SwiftUI

struct InstalledApp: Hashable {
    let displayName: String
    let bundleName: String
    let bundleIdentifier: String
    var bundlePath: String?
    
    var isInstalled: Bool
    
    var icon: UIImage?
    
    init(displayName: String, bundleName: String, bundleIdentifier: String) {
        self.displayName = displayName
        self.bundleName = bundleName
        self.bundleIdentifier = bundleIdentifier
        
        self.bundlePath = find_path_for_app(bundleName)
        self.isInstalled = !(bundlePath == nil)
        if bundlePath != nil {
            let fm = FileManager.default
            if fm.fileExists(atPath: bundlePath! + "/AppIcon60x60@2x.png") { self.icon = UIImage(contentsOfFile: bundlePath! + "/AppIcon60x60@2x.png") }
            if fm.fileExists(atPath: bundlePath! + "/AppIcon@2x.png") { self.icon = UIImage(contentsOfFile: bundlePath! + "/AppIcon@2x.png") }
            if fm.fileExists(atPath: bundlePath! + "/iOSAppIcon60x60@2x.png") { self.icon = UIImage(contentsOfFile: bundlePath! + "/iOSAppIcon60x60@2x.png") }
        }
    }
}

var persistenceHelperCandidates = [
    InstalledApp(displayName: "提示", bundleName: "Tips", bundleIdentifier: "com.apple.tips"),
    InstalledApp(displayName: "测距仪", bundleName: "Measure", bundleIdentifier: "com.apple.measure"),
    InstalledApp(displayName: "指南针", bundleName: "Compass", bundleIdentifier: "com.apple.compass"),
    InstalledApp(displayName: "图书", bundleName: "Books", bundleIdentifier: "com.apple.iBooks"),
    InstalledApp(displayName: "iTunes Store", bundleName: "MobileStore", bundleIdentifier: "com.apple.MobileStore"),
    InstalledApp(displayName: "翻译", bundleName: "SequoiaTranslator", bundleIdentifier: "com.apple.Translate"),
    InstalledApp(displayName: "播客", bundleName: "Podcasts", bundleIdentifier: "com.apple.podcasts"),
    InstalledApp(displayName: "计算器", bundleName: "Calculator", bundleIdentifier: "com.apple.calculator"),
    InstalledApp(displayName: "钱包", bundleName: "Passbook", bundleIdentifier: "com.apple.Passbook"),
    InstalledApp(displayName: "Apple TV", bundleName: "AppleTV", bundleIdentifier: "com.apple.tv"),
    InstalledApp(displayName: "无边记", bundleName: "Freeform", bundleIdentifier: "com.apple.freeform"),
    InstalledApp(displayName: "股票", bundleName: "Stocks", bundleIdentifier: "com.apple.stocks")
]

class HelperAlert: ObservableObject {
    static let shared = HelperAlert()
    @Published var showAlert: Bool = false
}

//
//  Installation.swift
//  TrollInstallerX
//
//  Created by Alfie on 22/03/2024.
//

import SwiftUI

let fileManager = FileManager.default
let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].path
let kernelPath = docsDir + "/kernelcache"


func checkForMDCUnsandbox() -> Bool {
    return fileManager.fileExists(atPath: docsDir + "/full_disk_access_sandbox_token.txt")
}

func getKernel(_ device: Device) -> Bool {
    if !fileManager.fileExists(atPath: kernelPath) {
        if fileManager.fileExists(atPath: Bundle.main.path(forResource: "kernelcache", ofType: "") ?? "") {
            try? fileManager.copyItem(atPath: Bundle.main.path(forResource: "kernelcache", ofType: "")!, toPath: kernelPath)
            if fileManager.fileExists(atPath: kernelPath) { return true }
        }
        if MacDirtyCow.supports(device) && checkForMDCUnsandbox() {
            let fd = open(docsDir + "/full_disk_access_sandbox_token.txt", O_RDONLY)
            if fd > 0 {
                let tokenData = get_NSString_from_file(fd)
                sandbox_extension_consume(tokenData)
                Logger.log("正在复制内核缓存")
                let path = get_kernelcache_path()
                do {
                    try fileManager.copyItem(atPath: path!, toPath: kernelPath)
                    return true
                } catch {
                    Logger.log("复制内核缓存失败", type: .error)
                    NSLog("Failed to copy kernelcache - \(error)")
                }
            }
        }
        Logger.log("正在下载内核")
        if !grab_kernelcache(kernelPath) {
            Logger.log("下载内核失败", type: .error)
            return false
        }
    }
    
    return true
}


func cleanupPrivatePreboot() -> Bool {
    // Remove /private/preboot/tmp
    let fileManager = FileManager.default
    do {
        try fileManager.removeItem(atPath: "/private/preboot/tmp")
    } catch let e {
        print("Failed to remove /private/preboot/tmp! \(e.localizedDescription)")
        return false
    }
    return true
}

func selectExploit(_ device: Device) -> KernelExploit {
    let flavour = (TIXDefaults().string(forKey: "exploitFlavour") ?? (physpuppet.supports(device) ? "physpuppet" : "landa"))
    if flavour == "landa" { return landa }
    if flavour == "physpuppet" { return physpuppet }
    if flavour == "smith" { return smith }
    return landa
}

func getCandidates() -> [InstalledApp] {
    var apps = [InstalledApp]()
    for candidate in persistenceHelperCandidates {
        if candidate.isInstalled { apps.append(candidate) }
    }
    return apps
}

@discardableResult
func doDirectInstall(_ device: Device) async -> Bool {
    
    let exploit = selectExploit(device)
    
    let iOS14 = device.version < Version("15.0")
    let supportsFullPhysRW = !(device.cpuFamily == .A8 && device.version > Version("15.1.1")) && ((device.isArm64e && device.version >= Version(major: 15, minor: 2)) || (!device.isArm64e && device.version >= Version("15.0")))
    
    Logger.log("正运行在 \(device.modelIdentifier) 设备上的 iOS 版本为 \(device.version.readableString)")
    
    if !iOS14 {
        if !(getKernel(device)) {
            Logger.log("获取内核漏洞失败", type: .error)
            return false
        }
    }
    
    Logger.log("正在查找内核漏洞")
    if !initialise_kernel_info(kernelPath, iOS14) {
        Logger.log("查找内核漏洞失败", type: .error)
        return false
    }
    
    Logger.log("正在利用内核 (\(exploit.name)) 漏洞")
    if !exploit.initialise() {
        Logger.log("利用内核漏洞失败", type: .error)
        return false
    }
    Logger.log("成功利用内核漏洞", type: .success)
    post_kernel_exploit(iOS14)
    
    var trollstoreTarData: Data?
    if FileManager.default.fileExists(atPath: docsDir + "/TrollStore.tar") {
        trollstoreTarData = try? Data(contentsOf: docsURL.appendingPathComponent("TrollStore.tar"))
    }
    
    if supportsFullPhysRW {
        if device.isArm64e {
            Logger.log("正在绕过 PPL (\(dmaFail.name))")
            if !dmaFail.initialise() {
                Logger.log("绕过 PPL 失败", type: .error)
                return false
            }
            Logger.log("成功绕过 PPL", type: .success)
        }
        
        if #available(iOS 16, *) {
            libjailbreak_kalloc_pt_init()
        }
        
        if !build_physrw_primitive() {
            Logger.log("构建硬件读写条件失败", type: .error)
            return false
        }
        
        if device.isArm64e {
            if !dmaFail.deinitialise() {
                Logger.log("初始化 \(dmaFail.name) 失败", type: .error)
                return false
            }
        }
        
        if !exploit.deinitialise() {
            Logger.log("初始化 \(exploit.name) 失败", type: .error)
            return false
        }
        
        Logger.log("正在解除沙盒")
        if !unsandbox() {
            Logger.log("解除沙盒失败", type: .error)
            return false
        }
        
        Logger.log("提升权限")
        if !get_root_pplrw() {
            Logger.log("提升权限失败", type: .error)
            return false
        }
        if !platformise() {
            Logger.log("平台化失败", type: .error)
            return false
        }
    } else {
        
        Logger.log("解除沙盒并提升权限中")
        if !get_root_krw(iOS14) {
            Logger.log("解除沙盒并提升权限失败", type: .error)
            return false
        }
    }
    
    remount_private_preboot()
    
    if let data = trollstoreTarData {
        do {
            try FileManager.default.createDirectory(atPath: "/private/preboot/tmp", withIntermediateDirectories: false)
            FileManager.default.createFile(atPath: "/private/preboot/tmp/TrollStore.tar", contents: nil)
            try data.write(to: URL(string: "file:///private/preboot/tmp/TrollStore.tar")!)
        } catch {
            print("无法成功写出 TrollStore.tar - \(error.localizedDescription)")
        }
    }
    
    // Prevents download finishing between extraction and installation
    let useLocalCopy = FileManager.default.fileExists(atPath: "/private/preboot/tmp/TrollStore.tar")

    if !fileManager.fileExists(atPath: "/private/preboot/tmp/trollstorehelper") {
        Logger.log("正在获取 TrollStore.tar")
        if !extractTrollStore(useLocalCopy) {
            Logger.log("获取 TrollStore.tar 失败", type: .error)
            return false
        }
    }
    
    let newCandidates = getCandidates()
    persistenceHelperCandidates = newCandidates
    
    DispatchQueue.main.sync {
        HelperAlert.shared.showAlert = true
        HelperAlert.shared.objectWillChange.send()
    }
    while HelperAlert.shared.showAlert { }
    let persistenceID = TIXDefaults().string(forKey: "persistenceHelper")
    
    if persistenceID != "" {
        if install_persistence_helper(persistenceID) {
            Logger.log("成功安装持久性助手！", type: .success)
        } else {
            Logger.log("安装持久性助手失败", type: .error)
        }
    }
    
    Logger.log("正在安装 TrollStore")
    if !install_trollstore(useLocalCopy ? "/private/preboot/tmp/TrollStore.tar" : Bundle.main.bundlePath + "/TrollStore.tar") {
        Logger.log("安装 TrollStore 失败", type: .error)
    } else {
        Logger.log("成功安装 TrollStore！", type: .success)
    }
    
    if !cleanupPrivatePreboot() {
        Logger.log("清除 /private/preboot 失败", type: .error)
    }
    
    if !supportsFullPhysRW {
        if !drop_root_krw(iOS14) {
            Logger.log("降低root权限失败", type: .error)
            return false
        }
        if !exploit.deinitialise() {
            Logger.log("初始化 \(exploit.name) 失败", type: .error)
            return false
        }
    }
    
    return true
}

func doIndirectInstall(_ device: Device) async -> Bool {
    let exploit = selectExploit(device)
    
    Logger.log("正运行在 \(device.modelIdentifier) 设备上的 iOS 版本为 \(device.version.readableString)")
    
    if !extractTrollStoreIndirect() {
        return false
    }
    defer {
        cleanupIndirectInstall()
    }
    
    if !(getKernel(device)) {
        Logger.log("获取内核失败", type: .error)
    }
    
    Logger.log("正在查找内核漏洞")
    if !initialise_kernel_info(kernelPath, false) {
        Logger.log("查找内核漏洞失败", type: .error)
        return false
    }
    
    Logger.log("正在利用内核漏洞 (\(exploit.name))")
    if !exploit.initialise() {
        Logger.log("利用内核漏洞失败", type: .error)
        return false
    }
    defer {
        if !exploit.deinitialise() {
            Logger.log("初始化 \(exploit.name) 失败", type: .error)
        }
    }
    Logger.log("成功利用内核", type: .success)
    post_kernel_exploit(false)
    
    var path: UnsafePointer<CChar>? = nil
    let pathPointer = withUnsafeMutablePointer(to: &path) { ptr in
        UnsafeMutablePointer<UnsafePointer<CChar>?>.init(ptr)
    }
    if is_persistence_helper_installed(pathPointer) {
        Logger.log("持久性助手已安装！" (\(path == nil ? "unknown" : String(cString: path!)))", type: .warning)
        return false
    }
    
    let apps = get_installed_apps() as? [String]
    var candidates = [InstalledApp]()
    for app in apps ?? [String]() {
        print(app)
        for candidate in persistenceHelperCandidates {
            if app.components(separatedBy: "/")[1].replacingOccurrences(of: ".app", with: "") == candidate.bundleName {
                candidates.append(candidate)
                candidates[candidates.count - 1].isInstalled = true
                candidates[candidates.count - 1].bundlePath = "/var/containers/Bundle/Application/" + app
            }
        }
    }
    
    persistenceHelperCandidates = candidates
    
    DispatchQueue.main.sync {
        HelperAlert.shared.showAlert = true
        HelperAlert.shared.objectWillChange.send()
    }
    while HelperAlert.shared.showAlert { }
    let persistenceID = TIXDefaults().string(forKey: "persistenceHelper")
    
    var pathToInstall = ""
    for candidate in persistenceHelperCandidates {
        if persistenceID == candidate.bundleIdentifier {
            pathToInstall = candidate.bundlePath!
        }
    }
    var success = false
    if !install_persistence_helper_via_vnode(pathToInstall) {
        Logger.log("安装持久性助手失败", type: .error)
    } else {
        Logger.log("成功安装持久性助手", type: .success)
        success = true
    }
    
    if success {
        let verbose = TIXDefaults().bool(forKey: "verbose")
        Logger.log("\(verbose ? "15" : "5") 秒后注销")
        DispatchQueue.global().async {
            sleep(verbose ? 15 : 5)
            restartBackboard()
        }
    }
    
    return true
}
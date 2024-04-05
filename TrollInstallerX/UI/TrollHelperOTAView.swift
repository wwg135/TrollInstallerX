//
//  TrollHelperOTAView.swift
//  TrollInstallerX
//
//  Created by Alfie on 26/03/2024.
//

import SwiftUI

struct TrollHelperOTAView: View {
    @Binding var arm64eVersion: Bool
    var body: some View {
            VStack {
                Text("TrollHelperOTA")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding()
                Text("您的设备兼容TrollHelperOTA - 这是一种100%可靠的安装方法，无需通过侧载应用程序进行安装。您可以点击此提示之外的区域来关闭，或者按下下方的按钮通过OTA在线进行安装。")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                Button(action: {
                    UIImpactFeedbackGenerator().impactOccurred()
                    UIApplication.shared.open(URL(string: "https://api.jailbreaks.app/troll" + (arm64eVersion ? "64e" : ""))!)
                }, label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: 175, height: 45)
                            .foregroundColor(.white.opacity(0.2))
                            .shadow(radius: 10)
                        Text("在线OTA安装")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                })
                .padding(.vertical)
            }
    }
}

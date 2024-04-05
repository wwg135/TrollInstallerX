//
//  PersistenceHelperView.swift
//  TrollInstallerX
//
//  Created by Alfie on 30/03/2024.
//

import SwiftUI

struct PersistenceHelperView: View {
    @Binding var isShowingHelperAlert: Bool
    let allowNoPersistenceHelper: Bool
    var body: some View {
        ScrollView {
            VStack {
                Text("持久性助手")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                if allowNoPersistenceHelper {
                    Text("如果您已经安装了一个持久性助手，请滚动到底部。")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            VStack(spacing: 20) {
                ForEach(persistenceHelperCandidates, id: \.self) { candidate in
                    Button(action: {
                        TIXDefaults().setValue(candidate.bundleIdentifier, forKey: "persistenceHelper")
                        withAnimation {
                            isShowingHelperAlert = false
                        }
                    }, label: {
                        HStack {
                            if let image = candidate.icon {
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: 44, height: 44)
                                    .cornerRadius(10)
                            } else {
//                                Image(systemName: "gear")
//                                    .resizable()
//                                    .frame(width: 44, height: 44)
//                                    .cornerRadius(10)
                            }
                            Text(candidate.displayName)
                                .font(.system(size: 20, weight: .regular, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.leading)
                            Spacer()
                        }
                    })
                }
                if allowNoPersistenceHelper {
                    Divider()
                    Button(action: {
                        TIXDefaults().setValue("", forKey: "persistenceHelper")
                        withAnimation {
                            isShowingHelperAlert = false
                        }
                    }, label: {
                        HStack {
                            Image(systemName: "xmark.circle")
                                .resizable()
                                .frame(width: 44, height: 44)
                                .cornerRadius(10)
                                .foregroundColor(.red)
                            Text("没有持久性助手")
                                .font(.system(size: 20, weight: .regular, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.leading)
                            Spacer()
                        }
                    })
                    .padding(.bottom)
                }
            }
        }
    }
}

//
//  ModelPickerView.swift
//  Remake the AR app
//
//  Created by 王浩宇 on 12/03/2023.
//

import SwiftUI
import QuickLookThumbnailing
import Combine

struct ModelPickerView: View {

    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: String?

    var models: [String]

    // 添加一个 ThumbnailGenerator 的实例
    @StateObject private var thumbnailGenerator = ThumbnailGenerator()

    var body: some View {
        ScrollView(.horizontal,showsIndicators: true){
            HStack(spacing: 30) {
                ForEach(models, id: \.self) { modelName in
                    Button(action: {
                        print("BEBUG: chosen \(modelName)")
                        self.isPlacementEnabled = true
                        self.selectedModel = "\(modelName)"
                    },
                    label: {
                        if let thumbnail = thumbnailGenerator.thumbnailImage[modelName] {
                            thumbnail
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100,height: 100)
                                .background(Color.white)
                                .cornerRadius(10)
                        } else {
                            Color.white
                                .frame(width: 100,height: 100)
                                .background(Color.gray)
                                .cornerRadius(10)
                            //一开始thumbnail是nil，先加载白图，通过.onAppear生成缩略图
                                .onAppear {
                                    thumbnailGenerator.generateThumbnail(for: modelName)
                                }
                            }
                    })
                }
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.5))
    }
}


class ThumbnailGenerator: ObservableObject {
    
    @Published var thumbnailImage: [String: Image] = [:]
    
    func generateThumbnail(for resource: String){
        guard let url = Bundle.main.url(forResource: resource, withExtension: ".usdz") else {
            print("DEBUG: unable to creat the url ")
            return
        }
        let scale = UIScreen.main.scale
        let request = QLThumbnailGenerator.Request(fileAt: url, size: CGSize(width: 100, height: 100), scale: scale, representationTypes: .all)
        let generator = QLThumbnailGenerator.shared
        
        generator.generateRepresentations(for: request){ (thumbnail, type, error) in
            DispatchQueue.main.async {
                if let thumbnail = thumbnail {
                    self.thumbnailImage[resource] = Image(uiImage: thumbnail.uiImage)
                }
            }
        }
    }
}

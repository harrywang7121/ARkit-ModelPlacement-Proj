//  ContentView.swift
//  ModelPickerApp
//
//  Created by 王浩宇 on 26/02/2023.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity
import MultipeerConnectivity

struct ContentView : View {
    
    @State private var isPlacementEnabled = false
    @State private var selectedModel: String?
    @State private var modelConfirmedForPlacement: String?
    @StateObject var arViewModel = ARViewModel()
    
    //文件部分最重要的一环
    private var models: [String] = {
        //Dynamiclly get file name
        //整段的核心是Filemanager.default.contentsOfDirectory(atPath: path)
        
        let filemanager = FileManager.default
        guard let path =  Bundle.main.resourcePath,
                let files = try? filemanager.contentsOfDirectory(atPath: path)
        else {
            print("DEBUG: No available models")
            return []
        }
        
        var availableModels: [String] = []
        for filenames in files where filenames.hasSuffix("usdz"){
            let modelName = filenames.replacingOccurrences(of: ".usdz", with: "")
            availableModels.append(modelName)
        }
        return availableModels
    }()
    
    var body: some View{
        ZStack(alignment: .bottom) {
            ARviewContainer(modelConfirmedForPlacement: self.$modelConfirmedForPlacement).environmentObject(arViewModel)
            
            if isPlacementEnabled{
                ModelPlacementView(isPlacementEnabled: self.$isPlacementEnabled, selectedModel: self.$selectedModel, modelConfirmedForPlacement: self.$modelConfirmedForPlacement)
            } else {
                ModelPickerView(isPlacementEnabled: self.$isPlacementEnabled, selectedModel: self.$selectedModel, models: self.models)
            }
        }.ignoresSafeArea()
    }
}


//ARViewContainer的创建与更新
struct ARviewContainer: UIViewRepresentable{
    
    @Binding var modelConfirmedForPlacement: String?
    @EnvironmentObject var arViewModel: ARViewModel
    
    func makeUIView(context: Context) -> ARView{
        return arViewModel.arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if let modelName = self.modelConfirmedForPlacement {
            print("DEBUG: adding model to scene - \(modelName)")
            
            let fileName = modelName + ".usdz"
            
            let modelEntity = try! ModelEntity.loadModel(named: fileName)

            let anchorEntity = AnchorEntity(plane: .any)
            
            anchorEntity.addChild(modelEntity)
            uiView.scene.addAnchor(anchorEntity)
            
            //add hand gesture
            modelEntity.generateCollisionShapes(recursive: true)
            uiView.installGestures(for: modelEntity)
            
            DispatchQueue.main.async {
                self.modelConfirmedForPlacement = nil
            }
        }
    }
}


struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

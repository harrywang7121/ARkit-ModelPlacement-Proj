//
//  SwiftUIView.swift
//  Remake the AR app
//
//  Created by 王浩宇 on 12/03/2023.
//

import SwiftUI

struct ModelPlacementView: View {
    
    @Binding var isPlacementEnabled : Bool
    @Binding var selectedModel: String?
    @Binding var modelConfirmedForPlacement: String?

    
    var body: some View {
        HStack(spacing: 50){
            Button {
                print("BEBUG: model placement confirmed ")
                
                isPlacementEnabled = false
                modelConfirmedForPlacement = selectedModel
                print("Selected: \(String(describing: selectedModel))")
                selectedModel = nil
                
            } label: {
                Image(systemName: "checkmark")
                    .frame(width: 80,height: 80)
                    .font(.largeTitle)
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(40)
                    .padding(20)
            }
            Button {
                print("BEBUG: model placement cancelled ")
                isPlacementEnabled = false
                selectedModel = nil
                
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 80,height: 80)
                    .font(.largeTitle)
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(40)
                    .padding(20)
            }
        }.padding()
    }
}

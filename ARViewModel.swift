//
//  ARViewModel.swift
//  Remake the AR app
//
//  Created by 王浩宇 on 03/04/2023.
//

import ARKit
import RealityKit
import MultipeerConnectivity
import SwiftUI
import FocusEntity
import Combine

//ARViewModel的配置，MVVM
class ARViewModel: ObservableObject {
    
    @Published var arView: ARView
    @Published var multipeerSession: MultipeerSession?
    @Published var sessionIDObservation: NSKeyValueObservation?
    
    // A dictionary to map MultiPeer IDs to ARSession ID's.
    // This is useful for keeping track of which peer created which ARAnchors.
    var peerSessionIDs = [MCPeerID: String]()
    
    init() {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        config.isCollaborationEnabled = true
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh){
            config.sceneReconstruction = .mesh
        }

        guard ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) else {
            fatalError("People occlusion is not supported on this device.")
        }
        config.frameSemantics.insert(.personSegmentationWithDepth)
        
        //FocusEntity加入
        let focusSquare = FocusEntity(on: arView, style: .classic(color: .yellow))
        arView.scene.addAnchor(focusSquare)
        
        arView.session.run(config)
        arView.environment.sceneUnderstanding.options = .occlusion

        //测试用，展示平面扫描结果
        //arView.debugOptions = [.showAnchorGeometry, .showAnchorOrigins, .showFeaturePoints]
        
        //测试用
        arView.createPlane()
        
        self.arView = arView
        
        //设置coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
        // Use key-value observation to monitor your ARSession's identifier.
        sessionIDObservation = arView.session.observe(\.identifier, options: [.new]) { object, change in
            print("SessionID changed to: \(change.newValue!)")
            // Tell all other peers about your ARSession's changed ID, so
            // that they can keep track of which ARAnchors are yours.
            guard let multipeerSession = self.multipeerSession else { return }
            self.sendARSessionIDTo(peers: multipeerSession.connectedPeers)
        }
        
        // Start looking for other players via MultiPeerConnectivity.
        multipeerSession = MultipeerSession(receivedDataHandler: self.receivedData, peerJoinedHandler: self.peerJoined, peerLeftHandler: peerLeft, peerDiscoveredHandler: peerDiscovered)
    }
}



//Plane Visualization
var planeMesh = MeshResource.generatePlane(width: 0.15, depth: 0.15)
var planeMaterial = SimpleMaterial(color: .white, isMetallic: false)
var planeEntity: ModelEntity? = ModelEntity(mesh: planeMesh,materials: [planeMaterial])
var planeAnchor = AnchorEntity()

extension ARView: ARSessionDelegate {

    func createPlane(){
        let planeAnchor = AnchorEntity(plane:.horizontal)
        do {
            planeMaterial.baseColor = try.texture(.load(named: "xiaoheizi"))
            planeMaterial.tintColor = UIColor.yellow.withAlphaComponent(0.9)
            planeAnchor.addChild(planeEntity!)
            self.scene.addAnchor(planeAnchor)
        } catch {
            print("找不到文件")
        }
    }
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let result = self.raycast(from: self.center, allowing: .estimatedPlane, alignment: .horizontal).first else{ return }
        planeEntity!.setTransformMatrix(result.worldTransform, relativeTo: nil)
    }
}






//Multipeer part
extension ARViewModel {
    
    private func sendARSessionIDTo(peers: [MCPeerID]) {
        guard let multipeerSession = multipeerSession else { return }
        let idString = arView.session.identifier.uuidString
        let command = "SessionID:" + idString
        if let commandData = command.data(using: .utf8) {
            multipeerSession.sendToPeers(commandData, reliably: true, peers: peers)
        }
    }
    
    func receivedData(_ data: Data, from peer: MCPeerID) {
        if let collaborationData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARSession.CollaborationData.self, from: data) {
            arView.session.update(with: collaborationData)
            return
        }
        // ...
        let sessionIDCommandString = "SessionID:"
        if let commandString = String(data: data, encoding: .utf8), commandString.starts(with: sessionIDCommandString) {
            let newSessionID = String(commandString[commandString.index(commandString.startIndex,
                                                                     offsetBy: sessionIDCommandString.count)...])
            // If this peer was using a different session ID before, remove all its associated anchors.
            // This will remove the old participant anchor and its geometry from the scene.
            if let oldSessionID = peerSessionIDs[peer] {
                removeAllAnchorsOriginatingFromARSessionWithID(oldSessionID)
            }
            
            peerSessionIDs[peer] = newSessionID
        }
    }
    
    func peerDiscovered(_ peer: MCPeerID) -> Bool {
        guard let multipeerSession = multipeerSession else { return false }
        
        if multipeerSession.connectedPeers.count > 4 {
            // Do not accept more than four users in the experience.
            print("A fifth peer wants to join the experience.\nThis app is limited to four users.")
            return false
        } else {
            return true
        }
    }
    /// - Tag: PeerJoined
    func peerJoined(_ peer: MCPeerID) {
        print("""
            A peer wants to join the experience.
            Hold the phones next to each other.
            """)
        // Provide your session ID to the new user so they can keep track of your anchors.
        sendARSessionIDTo(peers: [peer])
    }
        
    func peerLeft(_ peer: MCPeerID) {
        print("A peer has left the shared experience.")
        
        // Remove all ARAnchors associated with the peer that just left the experience.
        if let sessionID = peerSessionIDs[peer] {
            removeAllAnchorsOriginatingFromARSessionWithID(sessionID)
            peerSessionIDs.removeValue(forKey: peer)
        }
    }
    
    private func removeAllAnchorsOriginatingFromARSessionWithID(_ identifier: String) {
        guard let frame = arView.session.currentFrame else { return }
        for anchor in frame.anchors {
            guard let anchorSessionID = anchor.sessionIdentifier else { continue }
            if anchorSessionID.uuidString == identifier {
                arView.session.remove(anchor: anchor)
            }
        }
    }
}



//
//  ViewController.swift
//  ARKitPhysics
//
//  Created by mac126 on 2018/4/2.
//  Copyright © 2018年 mac126. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    
    var planeNodes = [SCNNode]()
    let rocketshipNodeName = "rocketship"
    
    var chameleon = Chameleon()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureLighting()
        addTapGestureToSceneView()
        addSwipeGestureToSceneView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    
    // MARK: - 初始化方法
    
    ///  启动世界追踪
    func setupSceneView() {

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
            
        sceneView.session.run(configuration)
        sceneView.delegate = self
        sceneView.scene = chameleon
        // 隐藏
        chameleon.hide()
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    func addTapGestureToSceneView() {
        // let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.addRocketshipToSceneView(recognizer:)))
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.addChameleonToSceneView(recognizer:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    func addSwipeGestureToSceneView() {
        let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.applyForceToRocketship(recognizer:)))
        swipeUpGesture.direction = .up
        sceneView.addGestureRecognizer(swipeUpGesture)
        
        let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.launchRocketship(recognizer:)))
        swipeDownGesture.direction = .down
        sceneView.addGestureRecognizer(swipeDownGesture)
    }
    
    func configureLighting() {
        // 是否自动更新场景的照明
        sceneView.automaticallyUpdatesLighting = true
        // 是否自动点亮没有光源的场景
        sceneView.autoenablesDefaultLighting = true
    }
    
    // 添加恐龙
    @objc func addChameleonToSceneView(recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        guard let hitTestResult = hitTestResults.first else {
            return
        }
        
        let translation = hitTestResult.worldTransform.translation
        let x = translation.x
        let y = translation.y + 0.05
        let z = translation.z
    
        let baseNode = chameleon.contentRootNode.childNodes[0]
        baseNode.position = SCNVector3Make(x, y, z)
        
        sceneView.scene.rootNode.addChildNode(baseNode)
        
    }
    
    /// 添加火箭
    @objc func addRocketshipToSceneView(recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        guard let hitTestResult = hitTestResults.first  else {
            return
        }
        let translation = hitTestResult.worldTransform.translation
        let x = translation.x
        let y = translation.y + 0.1
        let z = translation.z
        
        // 火箭
        guard let rocketshipScene = SCNScene(named: "art.scnassets/rocketship.scn"),
            let rocketshipNode = rocketshipScene.rootNode.childNode(withName: "rocketship", recursively: false) else {
            return
        }
        
        rocketshipNode.position = SCNVector3Make(x, y, z)
        rocketshipNode.name = rocketshipNodeName
        
        // 添加物理刚体
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        rocketshipNode.physicsBody = physicsBody
        
        
        sceneView.scene.rootNode.addChildNode(rocketshipNode)
        
    }
    
    /// 获取火箭节点
    func getRocketShipNode(from swipeLocation: CGPoint) -> SCNNode? {
        let hitTestResults = sceneView.hitTest(swipeLocation)

        guard let parentNode = hitTestResults.first?.node.parent, parentNode.name == rocketshipNodeName else {
            return nil
        }
        return parentNode
    }
    
    /// 添加作用力
    @objc func applyForceToRocketship(recognizer: UIGestureRecognizer) {
        guard recognizer.state == .ended  else {
            return
        }
        // 获取火箭节点
        let swipeLocation = recognizer.location(in: sceneView)
        
        guard let rocketNode = getRocketShipNode(from: swipeLocation), let physicsBody = rocketNode.physicsBody  else {
            return
        }
        // 添加作用力
        let direction = SCNVector3Make(0, 3, 0)
        physicsBody.applyForce(direction, asImpulse: true)
        
    }
    
    
    /// 发射火箭
    @objc func launchRocketship(recognizer: UIGestureRecognizer) {
        
        chameleon.turnLeft()
        
        return
        
        guard recognizer.state == .ended else {
            return
        }
        
        let swipeLocation = recognizer.location(in: sceneView)
        guard let rocketShipNode = getRocketShipNode(from: swipeLocation),
        let physicsBody = rocketShipNode.physicsBody,
        let reactorParticalSystem = SCNParticleSystem(named: "art.scnassets/reactor", inDirectory: nil),
        let engineNode = rocketShipNode.childNode(withName: "node2", recursively: false) else {
            return
        }
        
        physicsBody.isAffectedByGravity = false
        // 设置摩擦力
        physicsBody.damping = 0
        // 碰撞的节点数组
        reactorParticalSystem.colliderNodes = planeNodes
        engineNode.addParticleSystem(reactorParticalSystem)
        
        // 添加上升动作
        let action = SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 3)
        action.timingMode = .easeInEaseOut
        rocketShipNode.runAction(action)
        
    }
    
}

extension ViewController: ARSessionObserver {
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        // 创建平面
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        plane.materials.first?.diffuse.contents = UIColor.transparentWhite
        var planeNode = SCNNode(geometry: plane)
        
        planeNode.position = SCNVector3Make(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        planeNode.eulerAngles.x = -.pi / 2
        // 更新平面刚体
        update(&planeNode, withGeometry: plane, type: .static)
        
        node.addChildNode(planeNode)
        
        planeNodes.append(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor, let planeNode = node.childNodes.first  else {
            return
        }
        
        planeNodes = planeNodes.filter({ (node) -> Bool in
            node != planeNode
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
        var planeNode = node.childNodes.first,
        let plane = planeNode.geometry as? SCNPlane else {
            return
        }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        planeNode.position = SCNVector3Make(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        update(&planeNode, withGeometry: plane, type: .static)
    }
    
    // 更新平面节点的物理刚体
    func update(_ node: inout SCNNode, withGeometry geometry: SCNGeometry, type: SCNPhysicsBodyType)  {
        let shape = SCNPhysicsShape(geometry: geometry, options: nil)
        let physicsBody = SCNPhysicsBody(type: type, shape: shape)
        node.physicsBody = physicsBody
    }
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(x: translation.x, y: translation.y, z: translation.z)
    }
}

extension UIColor {
    open class var transparentWhite: UIColor {
        return UIColor.white.withAlphaComponent(0.5)
    }
}

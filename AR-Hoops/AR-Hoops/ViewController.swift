//
//  ViewController.swift
//  AR-Hoops
//
//  Created by Ansh Maroo on 9/29/19.
//  Copyright © 2019 Mygen Contac. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Each
class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var planeDetected: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    
    var power : Float = 1.0
    
    let timer = Each(0.05).seconds
    
    var basketAdded: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.debugOptions = [.showWorldOrigin]
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        
        sceneView.autoenablesDefaultLighting = true
        
        sceneView.delegate = self
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
    
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if basketAdded == true {
          
            timer.perform { () -> NextStep in
                self.power = self.power + 1
                
                return .continue
            }
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.basketAdded == true {
            timer.stop()
            shootBall()
        }
        power = 1
    }
    deinit {
        timer.stop()
    }
    func shootBall() {
        
        removeEveryOtherBall()
        
        guard let pointOfView = sceneView.pointOfView else {return}
                   
        

        let transform = pointOfView.transform

        let location = SCNVector3(transform.m41, transform.m42, transform.m43)

        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)

        let position = location + orientation

        let ball = SCNNode(geometry: SCNSphere(radius: 0.25))

        ball.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "ball")
        ball.position = position

        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball))
        ball.physicsBody = body
        
        ball.physicsBody?.applyForce(SCNVector3(orientation.x * power, orientation.y * power, orientation.z * power), asImpulse: true)
        
        ball.name = "Basketball"
        
        sceneView.scene.rootNode.addChildNode(ball)
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        if !hitTestResult.isEmpty {
            addBasket(hitTestResult: hitTestResult.first!)
        }
    }
    
    func addBasket(hitTestResult: ARHitTestResult) {
        if basketAdded == false {
            let basketScene = SCNScene(named: "Basketball.scnassets/Basketball.scn")
            let basketNode = basketScene?.rootNode.childNode(withName: "Basket", recursively: false)
            let positionOfPlane = hitTestResult.worldTransform.columns.3
            
            let xPosition = positionOfPlane.x
            
            let yPosition = positionOfPlane.y
            
            let zPosition = positionOfPlane.z
            
            
            
            basketNode?.position = SCNVector3(xPosition, yPosition, zPosition)
            
            basketNode?.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: basketNode!, options: [SCNPhysicsShape.Option.keepAsCompound:true, SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
            
            sceneView.scene.rootNode.addChildNode(basketNode!)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.basketAdded = true
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        DispatchQueue.main.async {
            self.planeDetected.isHidden = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+3) {
            self.planeDetected.isHidden = true
        }
    }
    func removeEveryOtherBall() {
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            if node.name == "Basketball" {
                node.removeFromParentNode()
            }
        }
    }
    
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
    
}

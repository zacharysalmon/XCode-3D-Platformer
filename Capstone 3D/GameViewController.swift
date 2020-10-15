//
//  GameViewController.swift
//  HitTheTree
//
//  Created by Zack Salmon on 7/8/20.
//  Copyright © 2020 Zack Salmon. All rights reserved.
//

import UIKit
import SceneKit
import AVFoundation //Audio Foundation
import CoreData
import CloudKit

class GameViewController: UIViewController
{
	var sceneView: SCNView!
	var scene: SCNScene!
	var sprite_scene: OverlayScene!
	var pause_menu: PauseMenu!
	let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
	let public_database = CKContainer.default().publicCloudDatabase
	let private_database = CKContainer.default().privateCloudDatabase
	var leaderboard: [CKRecord] = []

	
	var player: Player!
//	var player_position: SCNVector3 = SCNVector3(0.0, 0.0, 0.0)
//	var player_velocity: SCNVector3? = SCNVector3(0.0, 0.0, 0.0)
//	let starting_player_speed: Float = 1.3
//	let max_player_speed: Float = 3.3
//	var player_speed: Float = 1.3
//	let player_speed_delta: CGFloat = 0.001
//	let player_jump_height: Float = 5.0
//	var player_coins: Int = 0
	
	var track: Track!
//	var track2: Track!
	//	var track_layer_2: SCNNode!
	var track_layer: SCNNode!
//	var floor: SCNNode!
////	var track: SCNNode!
//	let starting_track_position_z: Float = 0.0
//	let starting_track_length: Float = 530.0
//	let max_track_length: Float = 560.0
//	var track_length: Float = 530.0
//	var next_track_position_z: Float = -1060
//	let floor_depth: Float = -30.0
//	let obstacle_distance_buffer: Float = 80.0
	
//	var coins: Coins
	var yellow_coin_node: SCNNode!
	var red_coin_node: SCNNode!
	var yellow_coins: SCNNode!
	var red_coins: SCNNode!
	
// All nodes that appear in the scene
//  var selfie_stick_node: SCNNode!
//	var cam_1: SCNNode!
	
	var obstacle_layer: SCNNode!
	var tree_node: SCNNode!
	var last_contact: SCNNode!
	
	//Various numbers used in calculations and constant positions.
	let starting_point: SCNVector3 =  SCNVector3(0.0, 0.5, 0.0)
	var count = 0
	var start = Date.timeIntervalSinceReferenceDate
	var jump_count = 0
	
	
	var number_of_trees: Int = 10
	let max_number_of_trees: Int = 25
	var number_of_coins: Int = 5
	
	// Bit masks for each of the categories of objects that are involved in collisions.
	var category_player: Int = 1
	var category_static: Int = 2
	var category_hidden: Int = 4
	
	// Array to keep track of what is currently being collided with the player.
	var collisions_array: [String: Bool] = ["game_over" : false,
									  "jump_sensor" : false,
									  "clear_sensor" : false]
	
//	var count: Int = 0
//	var jump_start: TimeInterval = Date.timeIntervalSinceReferenceDate
//	var has_jumped: Bool = false
	var is_paused: Bool = true
	var start_of_game: Bool = true
	
	var sounds: [String: SCNAudioSource] = [:]

	
	override func viewDidAppear(_ animated: Bool)
	{
		print("view did appear")
		player.setPlayerPosition(position: player.getPlayerPosition())
		player.getPlayerNode().physicsBody?.velocity = player.getPlayerVelocity()
		startCountdown()
	}
	
    override func viewDidLoad()
	{
		super.viewDidLoad()
		setupScene()
		setupNodes()
//		setupSounds()
    }
	
	override func loadView()
	{
	   let scnView = SCNView(frame: UIScreen.main.bounds, options: nil)
	   self.view = scnView
	 }
	
	func setupScene()
	{
		sceneView = (self.view as! SCNView)
		sceneView.delegate = self
		
		scene = SCNScene(named: "art.scnassets/MainScene.scn")
		sceneView.scene = scene
		
		scene.physicsWorld.contactDelegate = self
		
		
		self.sprite_scene = OverlayScene(size: self.view.bounds.size, game_scene: self)
		self.sceneView.overlaySKScene = self.sprite_scene
		
		self.pause_menu = PauseMenu(game_scene: self)
		
		
		let swipe_recognizer = UIPanGestureRecognizer()
		swipe_recognizer.minimumNumberOfTouches = 1
		swipe_recognizer.addTarget(self, action: #selector(GameViewController.sceneViewPanned(recognizer:)))
		sceneView.addGestureRecognizer(swipe_recognizer)
		
		sceneView.preferredFramesPerSecond = 60
//		sceneView.showsStatistics = true
//		sceneView.debugOptions = .showPhysicsShapes
//		sceneView.allowsCameraControl = true
		
		
	}
	
	func setupNodes()
	{
//		everything_node = scene.rootNode.childNode(withName: "everything", recursively: true)!
		player = Player(player_node: scene.rootNode.childNode(withName: "player", recursively: true)!, selfie_stick_node: scene.rootNode.childNode(withName: "selfie_stick", recursively: true)!)
//		selfie_stick_node = scene.rootNode.childNode(withName: "selfie_stick", recursively: true)!
		
		track_layer = scene.rootNode.childNode(withName: "track_layer", recursively: true)!
//		track = scene.rootNode.childNode(withName: "track", recursively: true)!
		track = Track(track: scene.rootNode.childNode(withName: "track", recursively: true)!, floor: scene.rootNode.childNode(withName: "floor", recursively: true)!, track_layer: track_layer)
//
//		track_layer_2 = track_layer_1.clone()
//		track2 = Track(track: scene.rootNode.childNode(withName: "track", recursively: true)!, floor: scene.rootNode.childNode(withName: "floor", recursively: true)!, track_layer: track_layer_2)
		
//		floor = scene.rootNode.childNode(withName: "floor", recursively: true)!
//		cam_1 = scene.rootNode.childNode(withName: "cam_1", recursively: true)!
		
		obstacle_layer = scene.rootNode.childNode(withName: "obstacle_layer", recursively: true)!
		tree_node = scene.rootNode.childNode(withName: "tree", recursively: true)!
		for i in 0...number_of_trees
		{
			obstacle_layer.insertChildNode(tree_node.clone(), at: i)
		}
		loopObstacles()
		
		
		
		yellow_coins = scene.rootNode.childNode(withName: "yellow_coins", recursively: true)!
		yellow_coin_node = scene.rootNode.childNode(withName: "yellow_coin", recursively: true)!
		
		red_coins = scene.rootNode.childNode(withName: "red_coins", recursively: true)!
		red_coin_node = scene.rootNode.childNode(withName: "red_coin", recursively: true)!
		placeCoins()
		
//		player_related = scene.rootNode.childNode(withName: "player_related", recursively: true)!
		
//		track_layer = scene.rootNode.childNode(withName: "track_layer", recursively: true)!
//		track = scene.rootNode.childNode(withName: "track", recursively: true)!
//		last_contact = track
	}
	
	func setupSounds()
	{
//		let background_music = SCNAudioSource(fileNamed: "background.mp3")!
//		background_music.volume = 0.1
//		background_music.loops = true
//		background_music.load()
//		let music_player = SCNAudioPlayer(source: background_music)
//		player.addAudioPlayer(music_player)
		
		// Let's the user listen to outside audio while the app is playing.
		try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient)
		try? AVAudioSession.sharedInstance().setActive(true)
	}
	
	
	@objc func sceneViewPanned(recognizer: UIPanGestureRecognizer)
	{
//		print("velocity: \(location)")
		if !is_paused
		{
			let location = recognizer.velocity(in: sceneView)
			if location.y < -700.0
			{
				player.jumpPlayer()
			}
			else
			{
				// Applying Force makes it so the player still falls if it's in the air and the screen is being Panned.
				//x is left to right, y is up and down, z is forward and backward
				player.getPlayerNode().physicsBody?.applyForce(SCNVector3(location.x * player.getPlayerSpeedDelta(), 0.0, 0.0), asImpulse: true)
			}
		}
	}
	
	func startCountdown()
	{
		if start_of_game
		{
			repeat
			{
				print(self.sprite_scene.countdown)
				sleep(1)
				self.sprite_scene.countdown -= 1
			} while sprite_scene.countdown > 0
			self.sprite_scene.countdown_node.isHidden = true
			self.sprite_scene.countdown = 3
			start_of_game = false
		}
		unpauseWorld()
	}
	
	
	func collisionHandler(player: SCNNode, object: SCNNode)
	{
		if object.physicsBody?.categoryBitMask == category_static && !is_paused
		{
			if object.name == "jump"
			{
				if #available(iOS 11.0, *)
				{
					//Modifying y to a lower number makes the player rotate backwards
					player.runAction(SCNAction.rotateTo(x: 1.5708, y: 1.2, z: 1.5708, duration: 0.1, usesShortestUnitArc: true))
					player.position.y += 0.1
				}
			}
			else if object.name == "track"
			{
				if #available(iOS 11.0, *)
				{
					player.runAction(SCNAction.rotateTo(x: 1.5708, y: 1.5708, z: 1.5708, duration: 0.1))
				}
			}
			else if object.name == "tree" && collisions_array["game_over"] == false
			{
				object.categoryBitMask = -1
				gameOver()
			}
			
		}
	
		if object.physicsBody?.categoryBitMask == category_hidden
		{
//			print("Hidden \(String(describing: object.name))")
			if object.name == "finish_sensor"
			{
//				collisions_array[object.name!] = true
				player.physicsBody?.applyForce(SCNVector3(0, 0, 0), asImpulse: true)
				player.position = starting_point
			}
			else if object.name == "floor" && collisions_array["game_over"] == false && !is_paused
			{
				gameOver()
			}
			else if object.name == "yellow_coin"
			{
				object.removeFromParentNode()
				yellowCoinHit()
			}
			else if object.name == "red_coin"
			{
				object.removeFromParentNode()
				redCoinHit()
			}
		}
	}
	
	
	func updateCollisions(object: SCNNode)
	{
		collisions_array[object.name!] = true
		if collisions_array["jump_sensor"] == true && collisions_array["clear_sensor"] == true
		{
			updateScore()
			print("player: \(player.getPlayerPosition().z)")
			track.loopTrack()
			loopObstacles()
			placeCoins()
		}
		
		for each in collisions_array
		{
			if each.key != object.name
			{
				collisions_array[each.key] = false
			}
		}
		//print("\(collisions_array)\n\n")
	}

	
	func yellowCoinHit()
	{
		let end = NSDate.timeIntervalSinceReferenceDate
		let elapsed = end - self.start
//		print("elapsed: \(elapsed)")
		if elapsed > 0.1
		{
			print("yellow")
			self.sprite_scene.score += 1
			self.player.setPlayerCoins(coins: self.player.getPlayerCoins() + 1)
		}
		self.start = NSDate.timeIntervalSinceReferenceDate
	}
	
	func redCoinHit()
	{
		let end = NSDate.timeIntervalSinceReferenceDate
		let elapsed = end - self.start
//		print("elapsed: \(elapsed)")
		if elapsed > 0.01
		{
			print("red")
			self.sprite_scene.score += 5
			self.player.setPlayerCoins(coins: self.player.getPlayerCoins() + 5)
		}
		self.start = NSDate.timeIntervalSinceReferenceDate
	}
	
	func updateScore()
	{
		self.sprite_scene.score += 1
		jump_count += 1
		if jump_count % 3 == 0
		{
			print("updating")
			updateLevel()
		}
	}
	
//	func loopTrack()
//	{
//		let old_track: SCNNode! = track_layer.childNode(withName: "track", recursively: false)
//
//		let new_track: SCNNode! = old_track.clone()
//		old_track.removeFromParentNode()
//		track_layer.addChildNode(new_track)
//		new_track.position = SCNVector3(0.0, 0.0, next_track_position_z)
//		next_track_position_z -= track_length
////		print(track_layer.childNodes.count)
//
//		for each in track_layer.childNodes
//		{
//			print("pos: \(each.position.z)")
//		}
//		print("next: \(next_track_position_z)")
//	}
	
	func loopObstacles()
	{
		for each in obstacle_layer.childNodes
		{
			each.eulerAngles = SCNVector3(0.0, 0.0, 0.0)
			var random_position = getTreePositionVector()
			if random_position.x > 19.0
			{
				//right side
				each.eulerAngles.z = 0.45
				random_position.y = random_position.x.magnitude / 6.0
			}
			else if random_position.x < -19.0
			{
				//left side
				each.eulerAngles.z = -0.45
				random_position.y = random_position.x.magnitude / 6.0
			}
		
			each.position = random_position
//			print("trees: \(each.position)")
		}
	}
	
	func getTreePositionVector() -> SCNVector3
	{
		let random_x = CGFloat.random(in: -25.0 ... 25.0)
		let random_y = CGFloat(0.0)
//		let random_z = CGFloat.random(in: (CGFloat(next_track_position_z + track_length + obstacle_distance_buffer)) ... (CGFloat(next_track_position_z + (track_length * 2) - obstacle_distance_buffer)))
	let random_z = CGFloat.random(in: (CGFloat(track.getNextTrackPositionZ() + track.getTrackLength() + track.getObstacleDistanceBuffer())) ... (CGFloat(track.getNextTrackPositionZ() + (track.getTrackLength() * 2) - track.getObstacleDistanceBuffer())))
		return SCNVector3(random_x, random_y, random_z)
	}
	
	func getCoinPositionVector() -> SCNVector3
	{
		let random_x = CGFloat.random(in: -17.0 ... 17.0)
		let random_y = CGFloat(3.0)
//		let random_z = CGFloat.random(in: (CGFloat(next_track_position_z + track_length + obstacle_distance_buffer)) ... (CGFloat(next_track_position_z + (track_length * 2) - obstacle_distance_buffer)))
	let random_z = CGFloat.random(in: (CGFloat(track.getNextTrackPositionZ() + track.getTrackLength() + track.getObstacleDistanceBuffer())) ... (CGFloat(track.getNextTrackPositionZ() + (track.getTrackLength() * 2) - track.getObstacleDistanceBuffer())))
		return SCNVector3(random_x, random_y, random_z)
	}

	
	func placeCoins()
	{
		while yellow_coins.childNodes.count < 5
		{
			yellow_coins.addChildNode(yellow_coin_node.clone())
		}
//		print(yellow_coins.childNodes)

		if red_coins.childNodes.count < 1
		{
			print("Adding red coin")
			red_coins.addChildNode(red_coin_node.clone())
		}
//		print(red_coins.childNodes)


//		print("yellow_count: \(yellow_coins.childNodes.count)")
//		print("red_count: \(red_coins.childNodes.count)")

		for each in yellow_coins.childNodes
		{
			each.position = getCoinPositionVector()
		}

		for each in red_coins.childNodes
		{
			each.position = getCoinPositionVector()
		}
	}
	
	func updateLevel()
	{
		if player.getPlayerSpeed() < player.getMaxPlayerSpeed()
		{
			let player_speed_increment: Float = 0.20
			player.setPlayerSpeed(speed: player.getPlayerSpeed() + player_speed_increment)
		}
//		if track_length < max_track_length
//  		{
//			track_length += 30
//			next_track_position_z -= 10
//		}
		if track.getTrackLength() < track.getMaxTrackLength()
		{
			track.setTrackLength(track_length: track.getTrackLength() + 30)
			track.setNextTrackPositionZ(next_track_position_z: track.getNextTrackPositionZ() - 10)
		}
		if obstacle_layer.childNodes.count <= max_number_of_trees
		{
			obstacle_layer.addChildNode(tree_node.clone())
		}
		
//		print("speed: \(player.getPlayerSpeed()), track_length: \(track_length), next_track: \(next_track_position_z), tree_count: \(obstacle_layer.childNodes.count)")
		print("speed: \(player.getPlayerSpeed()), track_length: \(track.getTrackLength()), next_track: \(track.getNextTrackPositionZ()), tree_count: \(obstacle_layer.childNodes.count)")
	}
	
	
	func gameOver()
	{
		let end = NSDate.timeIntervalSinceReferenceDate
		let elapsed = end - start
		start = NSDate.timeIntervalSinceReferenceDate
//		print(elapsed)
		if elapsed > 0.1
		{
			collisions_array["game_over"] = true
			print("Game Over")
			self.player.getPlayerNode().removeFromParentNode()
			sprite_scene.setHighScore()
			saveToCloud()
			openGameOverMenu()
		}
	}
	
	func saveToCloud()
	{
//		var user_reference = String()
		CKContainer.default().fetchUserRecordID
		{ (record_id, error_1) in
			if error_1 != nil
			{
				print(error_1!)
			}
			let player_name = UserDefaults.standard.string(forKey: "player_name")
			self.public_database.fetch(withRecordID: record_id!)
			{ (record1, error_2) in
				if error_2 != nil
				{
					print(error_2!)
				}
				
				let old_high_score = UserDefaults.standard.value(forKey: "high_score") as! Int
				
				if record1 != nil && old_high_score < self.sprite_scene.score
				{
					record1!.setValue(player_name, forKey: "player_name")
					record1!.setValue(self.sprite_scene.score, forKey: "player_score")
					record1!.setValue(self.player.getPlayerCoins(), forKey: "player_coins")
					self.public_database.save(record1!)
						{ (record2, error_3)
							in
							guard record2 != nil else {print(error_3!); return}
							print("user_record: \(String(describing: record1))")
						print("record2: \(String(describing: record2))")
						}
				}
				let user_id = record1?.recordID.recordName
				UserDefaults.standard.setValue(user_id, forKey: "user_id")
				
				let player_record = CKRecord(recordType: "Player")
				player_record.setValue(user_id, forKey: "user_reference")
				player_record.setValue(player_name, forKey: "player_name")
				player_record.setValue(self.sprite_scene.score, forKey: "player_score")
				player_record.setValue(self.player.getPlayerCoins(), forKey: "player_coins")
				let operation = CKModifyRecordsOperation(recordsToSave: [player_record], recordIDsToDelete: nil)
//				print("player_record: \(player_record)")
				self.public_database.add(operation)
			}
		}
		
	}
	
	func unpauseWorld()
	{
		print("Unpaused")
		if is_paused
		{
			is_paused = false
			player.getPlayerNode().isPaused = false
		}
	}
	
	func pauseWorld()
	{
		print("Paused")
		if !is_paused
		{
			is_paused = true
			player.getPlayerNode().isPaused = true
			openPauseMenu()
		}
		else
		{
			player.setPlayerPosition(position: player.getPlayerPosition())
			player.setPlayerVelocity(velocity: player.getPlayerVelocity())
			print("Unpause?")
			unpauseWorld()
		}
	}
	
	
	func openPauseMenu()
	{
		let scnStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
		guard let pause_menu = scnStoryboard.instantiateViewController(withIdentifier: "PauseMenu") as? PauseMenu else
		{
			print("Couldn't find the PauseMenu view controller")
			return
		}
		pause_menu.modalTransitionStyle = .crossDissolve
		present(pause_menu, animated: true, completion: nil)
	}
	
	func openGameOverMenu()
	{
		DispatchQueue.main.async
		{
			let game_over_menu = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "GameOverMenu") as? GameOverMenu 
			if game_over_menu != nil
			{
				game_over_menu?.modalTransitionStyle = .crossDissolve
				self.present(game_over_menu!, animated: true, completion: nil)
			}
		}
		
	}
	
    override var prefersStatusBarHidden: Bool
	{
        return false
    }
	
}


extension GameViewController : SCNSceneRendererDelegate
{
	// This render function updates the scene every frame. Try to keep a minimal amount of operations in this function to not overload the CPU.
	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
	{
		if !self.is_paused
		{
			player.movePlayer()
		}
		
		player.setPlayerPosition(position: player.getPlayerPosition())
//		floor.position = SCNVector3(player.getPlayerNode().position.x, floor_depth, player.getPlayerNode().position.z)
		track.getFloor().position = SCNVector3(player.getPlayerNode().position.x, track.getFloorDepth(), player.getPlayerNode().position.z)
	}
}

extension GameViewController : SCNPhysicsContactDelegate
{
	func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact)
	{
		var contact_node: SCNNode!
		var player: SCNNode
		if contact.nodeA.name == "player"
		{
			player = contact.nodeA
			contact_node = contact.nodeB
		}
		else
		{
			player = contact.nodeB
			contact_node = contact.nodeA
		}

		if contact_node.name == "tree"
		{
			contact_node.categoryBitMask = -1
			gameOver()
		}
		
		updateCollisions(object: contact_node)
		collisionHandler(player: player, object: contact_node)
	}
}

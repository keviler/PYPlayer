//
//  PYPlayerView.swift
//  Student
//
//  Created by 周朋毅 on 2022/2/23.
//

import UIKit
import SwiftUI
import Combine

public struct PYPlayerView: View {
    @ObservedObject public var parameters: PlayerParameters
    
    public init(parameters: PlayerParameters) {
        self.parameters = parameters
    }
    public var body: some View {
        ZStack {
            PYPlayerHostingView(parameters: parameters)
                .background(Color.black.edgesIgnoringSafeArea(.all))
            PYPlayerControl(parameters: self.parameters)
        }
        .onDisappear {
            self.parameters.player?.pause()
        }
        .onAppear {
            self.parameters.player?.play()
        }
        .onReceive(parameters.$videos.combineLatest(parameters.$index)) { (videos, index) in
            if videos.count > index {
                parameters.player?.url = videos[index].url
            }
        }
    }
}

struct PYPlayerHostingView: UIViewRepresentable {
    @ObservedObject var parameters: PlayerParameters
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.addSubview(context.coordinator.playView)
        context.coordinator.playView.translatesAutoresizingMaskIntoConstraints = false
        context.coordinator.playView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        context.coordinator.playView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        context.coordinator.playView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        context.coordinator.playView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        if self.parameters.videos.count > self.parameters.index {
            context.coordinator.url = self.parameters.videos[self.parameters.index].url
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
    func makeCoordinator() -> PYPlayer {
        let player = PYPlayer()
        player.loadStateChanged = { (_, state) in
            self.parameters.loadState = state
        }
        player.playStateChanged = { (_, state) in
            self.parameters.playbackState = state
        }
        player.onPlayChange = { (_, playTime) in
            self.parameters.time = playTime
        }
        player.onBufferChange = { (_, bufferTime) in
            self.parameters.bufferTime = bufferTime
        }
        player.onEnd = { (_, state) in
            self.parameters.didEnd = true
        }
        player.onFailed = { (_, state) in
            self.parameters.didEnd = true
        }
        player.onReady = {(player, duration) in
            self.parameters.totalDuration = duration
        }
        self.parameters.player = player
        return player
    }
    static func dismantleUIView(_ uiView: UIView, coordinator: PYPlayer) {
        coordinator.stop()
    }
}

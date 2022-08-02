//
//  PYPlayerControl.swift
//  Demo
//
//  Created by 周朋毅 on 2022/3/22.
//

import SwiftUI
import AVFoundation
import Kingfisher
import SwiftUIX

struct PYPlayerControl: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var parameters: PlayerParameters
    @State private var isShowing: Bool = true

    @State private var showRateView: Bool = false {
        didSet {
            if showRateView {
                isShowing = false
            }
        }
    }
    @State private var showListView: Bool = false {
        didSet {
            if showListView {
                isShowing = false
            }
        }
    }

    var body: some View {
        ZStack {
            GeometryReader { geo in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        TapGesture(count: 2)
                                .onEnded {
                                    playButtonAction()
                                }
                                .simultaneously(with:
                                                    TapGesture()
                                                    .onEnded {
                                                        withAnimation(.easeInOut) {
                                                            showRateView = false
                                                            showListView = false
                                                            isShowing.toggle()
                                                        }
                                                    })
                    )
                    .gesture(
                        DragGesture(minimumDistance: 5, coordinateSpace: .global)
                            .onChanged({ value in
                                print(value.translation)
                                if abs(value.translation.width) > abs(value.translation.height) { //横向滑动 调整播放进度
                                    self.parameters.isDragging = true
                                    var progressValue = self.parameters.playProgress + value.translation.width / geo.size.width
                                    if progressValue > 1 {
                                        progressValue = 1
                                    } else if progressValue < 0 {
                                        progressValue = 0
                                    }
                                    self.parameters.seekTime = progressValue * parameters.totalDuration
                                } else { //竖向滑动，调整音量亮度
                                    
                                }
                            })
                            .onEnded({ value in
                                if abs(value.translation.width) > abs(value.translation.height) { //横向滑动
                                    parameters.isDragging = false
                                    var progressValue = self.parameters.playProgress + value.translation.width / geo.size.width
                                    if progressValue > 1 {
                                        progressValue = 1
                                    } else if progressValue < 0 {
                                        progressValue = 0
                                    }
                                    var seekTime = progressValue * parameters.totalDuration
                                    if progressValue == 1 { //拖动到最后 向前缓冲五秒
                                        seekTime -= 5
                                    }
                                    parameters.time = seekTime
                                    parameters.player?.seek(to: seekTime)
                                } else {
                                    
                                }
                            })
                    )
                
            }
            if self.parameters.loadState == .prepare {
                KFImage(URL(string: self.parameters.currentVideo?.cover ?? ""))
                    .resizable()
            }
            if  self.parameters.loadState == .unknown ||
                self.parameters.loadState == .prepare ||
                self.parameters.loadState == .stalled ||
                self.parameters.playbackState == .seeking {
                loadingView
            }
            if  self.parameters.playbackState == .paused {
                centerPlayButton
            }
            if isShowing {
                VStack(alignment: .leading) {
                    topView
                    Spacer()
                    bottomView
                }
                .clipped()
            }
            if showRateView {
                rateView
                    .transition(AnyTransition.move(edge: .trailing))
            }
            if showListView {
                listView
                    .transition(AnyTransition.move(edge: .trailing))
            }
        }
    }
    
    var progressView: some View {
        HStack {
            Text("\(parameters.isDragging ? parameters.seekTime.durationString : parameters.time.durationString)")
                .font(.system(size: 12))
                .foregroundColor(Color.white)
            ZStack {
                PYProgressView(value: parameters.bufferTime / parameters.totalDuration)
                PYSlider(value: parameters.seekProgress) { value in
                    parameters.isDragging = true
                } onDragging: { value in
                    self.parameters.seekTime = value * parameters.totalDuration
                } dragEnded: { value in
                    parameters.isDragging = false
                    let seekTime = value * parameters.totalDuration
                    parameters.time = seekTime
                    parameters.player?.seek(to: seekTime)
                }
                .trackBackgroundColor(.clear)
            }
            Text("\(parameters.totalDuration.durationString)")
                .font(.system(size: 12))
                .foregroundColor(Color.white)
        }
    }
    var nextButton: some View {
        Button {
            parameters.index += 1
        } label: {
            Image(systemName: "forward.end")
                .resizable()
                .frame(width: 15, height: 15)
                .foregroundColor(.white)
                .padding(.horizontal)
        }
    }
    
    var fullScreenButton: some View {
        Button {
            if parameters.isFullScreen {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                withAnimation(Animation.easeOut(duration: 0.1)) {
                    parameters.isFullScreen.toggle()
                }
            }
        } label: {
            Image(systemName: parameters.isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                .foregroundColor(.white)
                .padding(.horizontal)
        }
    }

    

}

// top control bottom control
extension PYPlayerControl {
    var topView: some View {
        HStack {
            if !parameters.isFullScreen {
                Image(systemName: "chevron.backward")
                    .foregroundColor(.white)
                    .onTapGesture {
                        if !parameters.isFullScreen {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
            }
            Text(self.parameters.currentVideo?.title ?? "")
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            if parameters.isFullScreen {
                Image(systemName: "arrow.down")
                    .foregroundColor(.white)
                    .onTapGesture {
                        
                    }
                listButton
            }
        }
        .padding()
        .background(
            LinearGradient(colors: [Color.black.opacity(0.9), Color.clear], startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
        )
//        .transition(AnyTransition.move(edge: .top))
    }
    var bottomView: some View {
        Group {
            if parameters.isFullScreen {
                VStack {
                    progressView
                    HStack {
                        playButton
                        if parameters.videos.count > 1 && parameters.index < parameters.videos.count - 1 {
                            nextButton
                        }
                        Spacer()
                        rateButton
                        fullScreenButton
                    }
                }
                .padding(.horizontal)
            } else {
                HStack(spacing: 0) {
                    playButton
                    progressView
                        .padding(.trailing)
                    rateButton
                    fullScreenButton
                }
            }
        }
        .frame(height: parameters.isFullScreen ? 71 : 33)
        .background(
            LinearGradient(colors: [Color.black.opacity(0.9), Color.clear], startPoint: .bottom, endPoint: .top)
                .edgesIgnoringSafeArea(.all)
        )
//        .transition(AnyTransition.move(edge: .bottom))
    }
}

extension PYPlayerControl {
    var rateButton: some View {
        Text(String(format: "%.1fX", self.parameters.rate))
            .font(.system(size: 16))
            .foregroundColor(Color.white)
            .onTapGesture {
                withAnimation(.easeInOut) {
                    showRateView.toggle()
                }
            }
    }
    var rateView: some View {
        HStack {
            Spacer()
            ScrollView {
                VStack {
                    ForEach([0.5, 0.75, 1, 1.5, 2, 3], id: \.self) { rate in
                        rateText(rate: rate)
                    }
                }
            }
            .background (
                blueView
            )
        }
    }
    
    func rateText(rate: Double) -> some View {
        Text(String(format: "%.1fX", rate))
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal)
            .background((rate == self.parameters.rate) ? Color.systemBlue : Color.clear)
            .cornerRadius(8, style: .continuous)
            .padding(.horizontal)
            .padding(.horizontal)
            .onTapGesture {
                self.parameters.player?.rate = Float(rate)
                withAnimation(.easeInOut) {
                    showRateView.toggle()
                }
            }
    }
    
    var blueView: some View {
        BlurEffectView(style: .systemUltraThinMaterial)
            .edgesIgnoringSafeArea(.all)
            .cornerRadius([.topLeft, .bottomLeft], 10)
    }
}

// 播放列表
extension PYPlayerControl {
    var listButton: some View {
        Image(systemName: "list.bullet")
            .foregroundColor(.white)
            .padding(.horizontal)
            .onTapGesture {
                withAnimation(.easeInOut) {
                    showListView.toggle()
                }
            }
    }
    var listView: some View {
        HStack {
            Spacer()
            ScrollView {
                VStack {
                    ForEach(self.parameters.videos, id: \.url) { video in
                        videoCell(of: video)
                    }
                }
            }
            .background (
                BlurEffectView(style: .systemUltraThinMaterial)
                    .edgesIgnoringSafeArea(.all)
                    .cornerRadius([.topLeft, .bottomLeft], 10)
            )
        }
    }
    
    func videoCell(of video: PYVideo) -> some View {
        Text(video.title)
            .foregroundColor(.white)
            .padding(.vertical)
            .padding(.horizontal, 12)
            .frame(width: 150)
            .background((video == self.parameters.currentVideo) ? Color(UIColor.systemBlue) : Color.clear)
            .cornerRadius(10)
            .onTapGesture {
                self.parameters.index = self.parameters.videos.firstIndex(of: video) ?? 0
                withAnimation(.easeInOut) {
                    showListView.toggle()
                }
            }
    }

}

// play button and actions
extension PYPlayerControl {
    var playButton: some View {
        Button(action: playButtonAction) {
            Image(systemName: parameters.playbackState == .playing ? "pause.fill" : "play.fill")
                .resizable()
                .frame(width: 15, height: 15)
                .foregroundColor(.white)
                .padding(.horizontal)
        }
    }
    func playButtonAction() {
        switch parameters.playbackState {
        case .playing: parameters.player?.pause()
        case .paused: parameters.player?.play()
        default: break
        }
    }
    var centerPlayButton: some View {
        
        Button(action: playButtonAction) {
            Image(systemName: parameters.playbackState == .playing ? "pause.fill" : "play.circle")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.white)
                .padding()
        }
    }
}

extension PYPlayerControl {
    var loadingView: some View {
        ActivityIndicator()
            .style(.large)
            .tintColor(.white)
    }
}

//
//  PYPlayer.swift
//  FengKao
//
//  Created by 周朋毅 on 2022/4/6.
//

import Foundation
import IJKMediaFramework
import UIKit
import SwiftUI

public class PYPlayer {
    public enum PlaybackState {
        case unknown
        case playing
        case paused
        case seeking
        case failed
        case stopped
    }
    public enum LoadState {
        case unknown
        case prepare
        case playable
        case playthroughOK
        case stalled
    }

    private var timer: Timer?

    private(set) var player: IJKFFMoviePlayerController?
    lazy var options: IJKFFOptions = {
        let options = IJKFFOptions.byDefault()
//        options?.setPlayerOptionIntValue(1, forKey: "enable-accurate-seek")
        options?.setOptionIntValue(1, forKey: "dns_cache_clear", of: kIJKFFOptionCategoryFormat)
        return options!
    }()
    private var lastVolume: Float = 0.0
    private var shouldAutoPlay: Bool = true
    private var seekTime: TimeInterval = 0
    private var presentationSize: CGSize = .zero

    var volume: Float = 0.0 {
        didSet {
            volume = min(max(0, volume), 1)
            self.player?.playbackVolume = volume
        }
    }
    var playState: PlaybackState = .unknown {
        didSet {
            self.playStateChanged?(self, playState)
        }
    }

    public var playStateChanged: ((PYPlayer, PlaybackState)-> Void)?
    public var loadStateChanged: ((PYPlayer, LoadState)-> Void)?
    public var onPrepare: ((PYPlayer, URL)-> Void)?
    public var onReady: ((PYPlayer, TimeInterval)-> Void)?
    public var onPlayChange: ((PYPlayer, TimeInterval)-> Void)?
    public var onBufferChange: ((PYPlayer, TimeInterval)-> Void)?
    public var onEnd: ((PYPlayer, URL?)-> Void)?
    public var onFailed: ((PYPlayer, URL?)-> Void)?
    public var presentationSizeChanged: ((PYPlayer, CGSize)-> Void)?

    public var isPlaying: Bool = false
    public var isPreparedToPlay: Bool = false
    public var isReadyToPlay: Bool = false
    public var loadState: LoadState = .unknown {
        didSet {
            self.loadStateChanged?(self, loadState)
        }
    }
    public var url: URL? = nil {
        didSet {
            guard url != nil, url != oldValue else { return }
            if self.player != nil {
                stop()
            }
            prepareToPlay()
        }
    }
    public var rate: Float = 1.0 {
        didSet {
            if (self.player != nil && fabsf(player?.playbackRate ?? 1) > 0.00001) {
                self.player?.playbackRate = rate
            }
        }
    }
    public var muted: Bool = false {
        didSet {
            if (muted) {
                self.lastVolume = self.player?.playbackVolume ?? 0
                self.player?.playbackVolume = 0
            } else {
                /// Fix first called the lastVolume is 0.
                if (self.lastVolume == 0) {
                    self.lastVolume = self.player?.playbackVolume ?? 0
                } else {
                    self.player?.playbackVolume = self.lastVolume
                }
            }
        }
    }
    public var scalingMode: IJKMPMovieScalingMode = .aspectFit {
        didSet {
            self.player?.scalingMode = scalingMode
        }
    }

    deinit {
        stop()
    }
    func prepareToPlay() {
        guard let url = url else { return }
        isPreparedToPlay = true
        initializePlayer()
        if (self.shouldAutoPlay) {
            play()
        }
        self.loadState = .prepare
        onPrepare?(self, url)
    }

    public func reloadPlayer() {
        prepareToPlay()
    }

    public func play() {
        guard !self.isPlaying else { return }
        if (!isPreparedToPlay) {
            prepareToPlay()
        } else {
            player?.play()
            if let timer = timer {
                timer.fireDate = Date()
            }
            self.player?.playbackRate = self.rate
            isPlaying = true
            self.playState = .playing
        }
    }

    public func pause() {
        if let timer = self.timer {
            timer.fireDate = Date.distantFuture
        }
        self.player?.pause()
        isPlaying = false
        self.playState = .paused
    }

    public func stop() {
        loadStateChanged = nil
        playStateChanged = nil
        onPlayChange = nil
        onBufferChange = nil
        onEnd = nil
        onFailed = nil
        onReady = nil
        removeMovieNotificationObservers()
        player?.shutdown()
        playView.removeFromSuperview()
        player = nil
        url = nil
        timer?.invalidate()
        timer = nil
        presentationSize = .zero
        isPlaying = false
        isPreparedToPlay = false
        isReadyToPlay = false
        playState = .stopped
    }

    public func replay() {
        seek(to: 0) { finished in
            if (finished) {
                self.play()
            }
        }
    }

    public func seek(to time: TimeInterval, completionHandler: ((Bool)->Void)? = nil)  {
        if (self.player?.duration ?? 0 > 0) {
            self.player?.currentPlaybackTime = time
            if self.player?.playbackState == .stopped || self.player?.playbackState == .paused {
                self.player?.play()
            }
            completionHandler?(true)
        } else {
            self.seekTime = time
        }
    }

    public func thumbnailImageAtCurrentTime() -> UIImage? {
        self.player?.thumbnailImageAtCurrentTime()
    }


    func initializePlayer() {
        if self.player != nil {
            removeMovieNotificationObservers()
            player?.shutdown()
            player?.view.removeFromSuperview()
            player = nil
        }

        self.player = IJKFFMoviePlayerController(contentURL: self.url, with: self.options)
        self.player?.shouldAutoplay = self.shouldAutoPlay
        self.player?.prepareToPlay()
        if let ijkPlayView = self.player?.view {
            self.playView.addSubview(ijkPlayView)
            ijkPlayView.translatesAutoresizingMaskIntoConstraints = false
            ijkPlayView.topAnchor.constraint(equalTo: self.playView.topAnchor).isActive = true
            ijkPlayView.bottomAnchor.constraint(equalTo: self.playView.bottomAnchor).isActive = true
            ijkPlayView.leadingAnchor.constraint(equalTo: self.playView.leadingAnchor).isActive = true
            ijkPlayView.trailingAnchor.constraint(equalTo: self.playView.trailingAnchor).isActive = true
        }
        self.player?.scalingMode = self.scalingMode
        addPlayerNotificationObservers()
    }

    func addPlayerNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(loadStateDidChange(_:)), name: .IJKMPMoviePlayerLoadStateDidChange, object: player)
        NotificationCenter.default.addObserver(self, selector: #selector(moviePlayBackFinish(_: )), name: .IJKMPMoviePlayerPlaybackDidFinish, object: player)
        NotificationCenter.default.addObserver(self, selector: #selector(mediaIsPreparedToPlayDidChange(_: )), name: .IJKMPMediaPlaybackIsPreparedToPlayDidChange, object: player)
        NotificationCenter.default.addObserver(self, selector: #selector(moviePlayBackStateDidChange(_: )), name: .IJKMPMoviePlayerPlaybackStateDidChange, object: player)
        NotificationCenter.default.addObserver(self, selector: #selector(sizeAvailableChange(_:)), name: .IJKMPMovieNaturalSizeAvailable, object: player)
    }

    func removeMovieNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: .IJKMPMoviePlayerLoadStateDidChange, object: player)
        NotificationCenter.default.removeObserver(self, name: .IJKMPMoviePlayerPlaybackDidFinish, object: player)
        NotificationCenter.default.removeObserver(self, name: .IJKMPMediaPlaybackIsPreparedToPlayDidChange, object: player)
        NotificationCenter.default.removeObserver(self, name: .IJKMPMoviePlayerPlaybackStateDidChange, object: player)
        NotificationCenter.default.removeObserver(self, name: .IJKMPMovieNaturalSizeAvailable, object: player)
    }

    @objc func timerUpdate() {
        guard let player = player else { return }
        if (player.currentPlaybackTime > 0 && !self.isReadyToPlay) {
            self.isReadyToPlay = true
            self.loadState = .playthroughOK
        }
        self.onPlayChange?(self, player.currentPlaybackTime > 0 ? player.currentPlaybackTime : 0)
        self.onBufferChange?(self, player.playableDuration)
    }


    /// 播放完成
    @objc func moviePlayBackFinish(_ notification: Notification) {
        let userInfo = notification.userInfo?[IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] as? Int ?? 0
        let reason = IJKMPMovieFinishReason(rawValue: userInfo) ?? .userExited
        switch reason {
        case .playbackEnded:
            self.playState = .stopped
            self.onEnd?(self, self.url)
        case .userExited: break
        case .playbackError:
            self.playState = .failed
            self.onFailed?(self, self.url)
        @unknown default:
            fatalError("IJKMPMovieFinishReason \(reason)")
        }
    }

    // 准备开始播放了
    @objc func mediaIsPreparedToPlayDidChange(_ notification: Notification) {
        // 视频开始播放的时候开启计时器
        if self.timer == nil {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerUpdate), userInfo: nil, repeats: true)
            RunLoop.main.add(self.timer!, forMode: .common)
        }
        
        if (self.isPlaying) {
            play()
            self.muted = false
            if (self.seekTime > 0) {
                seek(to: self.seekTime)
                self.seekTime = 0; // 滞空, 防止下次播放出错
                play()
            }
        }
        onReady?(self, self.player?.duration ?? 0)
    }


    /**
     视频加载状态改变了
     IJKMPMovieLoadStateUnknown == 0
     IJKMPMovieLoadStatePlayable == 1
     IJKMPMovieLoadStatePlaythroughOK == 2
     IJKMPMovieLoadStateStalled == 4
     */
    @objc func loadStateDidChange(_ notification: Notification) {
        guard let player = player else { return }
        print("loadStateDidChange\(player.loadState)")
        if player.loadState.contains(IJKMPMovieLoadState.playable) {
            if player.currentPlaybackTime >= 0 {
                self.loadState = .playable
            }
        } else if player.loadState.contains(IJKMPMovieLoadState.playthroughOK) {
            self.loadState = .playthroughOK
        } else if player.loadState.contains(IJKMPMovieLoadState.stalled) {
            self.loadState = .stalled
        } else {
            self.loadState = .unknown
        }
    }

    // 播放状态改变
    @objc func moviePlayBackStateDidChange(_ notification: Notification) {
        guard let player = player else { return }
        switch (player.playbackState) {
        case .stopped:
            self.playState = .stopped
        case .playing:
            self.playState = .playing
        case .paused:
            self.playState = .paused
        case .seekingForward, .seekingBackward:
            self.playState = .seeking
        default:
            break
        }
    }

    /// 视频的尺寸变化了
    @objc func sizeAvailableChange(_ notification: Notification) {
        guard let player = player else { return }
        self.presentationSize = player.naturalSize
        self.presentationSizeChanged?(self, self.presentationSize);
    }
    
    lazy var playView: UIView = {
        let view = UIView()
        return view
    }()
}

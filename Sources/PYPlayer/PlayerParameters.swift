//
//  File.swift
//  
//
//  Created by 周朋毅 on 2022/5/9.
//

import Foundation

public class PlayerParameters: ObservableObject {
    @Published public var videos: [PYVideo]
    @Published public var index: Int {
        didSet {
            if self.videos.count > self.index {
                player?.url = self.videos[self.index].url
            }
        }
    }
    
    @Published public var player: PYPlayer?
    var rate: Double {
        get {
            Double(self.player?.rate ?? 1.0)
        }
    }
    @Published public var totalDuration: Double = 0
    @Published public var bufferTime: Double = 0
    @Published public var time: Double = 0
    @Published public var isDragging: Bool = false {
        didSet {
            seekTime = 0
        }
    }
    @Published public var seekTime: Double = 0
    @Published public var isFullScreen: Bool = false
    @Published public var playbackState: PYPlayer.PlaybackState = .unknown
    @Published public var loadState: PYPlayer.LoadState = .prepare
    @Published public var didEnd: Bool = false {
        didSet {
            if didEnd == true {
                if videos.count - 1 > index {
                    index += 1
                    didEnd = false
                }
            }
        }
    }
    public var currentVideo: PYVideo? {
        get {
            if videos.count > index {
                return videos[index % videos.count]
            }
            return nil
        }
    }
    public var playProgress: Double {
        get {
            if totalDuration > 0 {
                return time / totalDuration
            } else {
                return 0
            }
        }
    }
    public var seekProgress: Double {
        get {
            if isDragging {
                if totalDuration > 0 {
                    return seekTime / totalDuration
                } else {
                    return 0
                }
            } else {
                return self.playProgress
            }
        }
    }

    public init(videos: [PYVideo] = [], index: Int = 0) {
        self.videos = videos
        self.index = index
    }
    
    public func stop() {
        self.player?.stop()
    }
    
    deinit {
        
    }
}

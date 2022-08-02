//
//  File.swift
//  
//
//  Created by 周朋毅 on 2022/5/9.
//

import Foundation

public class PlayerParameters: ObservableObject {
    @Published var videos: [PYVideo]
    @Published var index: Int {
        didSet {
            if self.videos.count > self.index {
                player?.url = self.videos[self.index].url
            }
        }
    }
    
    @Published var player: PYPlayer?
    var rate: Double {
        get {
            Double(self.player?.rate ?? 1.0)
        }
    }
    @Published var totalDuration: Double = 0
    @Published var bufferTime: Double = 0
    @Published var time: Double = 0
    @Published var isDragging: Bool = false {
        didSet {
            seekTime = 0
        }
    }
    @Published var seekTime: Double = 0
    @Published var isFullScreen: Bool = false
    @Published var playbackState: PYPlayer.PlaybackState = .unknown
    @Published var loadState: PYPlayer.LoadState = .prepare
    @Published var didEnd: Bool = false {
        didSet {
            if didEnd == true {
                if videos.count - 1 > index {
                    index += 1
                    didEnd = false
                }
            }
        }
    }
    var currentVideo: PYVideo? {
        get {
            if videos.count > index {
                return videos[index % videos.count]
            }
            return nil
        }
    }
    var playProgress: Double {
        get {
            if totalDuration > 0 {
                return time / totalDuration
            } else {
                return 0
            }
        }
    }
    var seekProgress: Double {
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

    init(videos: [PYVideo] = [], index: Int = 0) {
        self.videos = videos
        self.index = index
    }
    
    func stop() {
        self.player?.stop()
    }
    
    deinit {
        
    }
}

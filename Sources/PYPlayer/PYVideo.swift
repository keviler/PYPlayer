//
//  FKVideo.swift
//  Student
//
//  Created by 周朋毅 on 2022/4/2.
//

import Foundation

public struct PYVideo: Equatable {
    public var url: URL
    public var title: String
    public var cover: String?
    public init(url: URL, title: String, cover: String? = nil) {
        self.url = url
        self.title = title
        self.cover = cover
    }
}


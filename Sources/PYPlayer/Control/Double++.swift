//
//  File.swift
//  
//
//  Created by 周朋毅 on 2022/8/2.
//

import Foundation

extension Double {

    var playerTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date(timeIntervalSinceReferenceDate: self))
    }
    
    var fileSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: .file)
    }
    var durationString: String {
      let hours:Int = Int(self.truncatingRemainder(dividingBy: 86400) / 3600)
      let minutes:Int = Int(self.truncatingRemainder(dividingBy: 3600) / 60)
      let seconds:Int = Int(self.truncatingRemainder(dividingBy: 60))

      if hours > 0 {
          return String(format: "%i:%02i:%02i", hours, minutes, seconds)
      } else {
          return String(format: "%02i:%02i", minutes, seconds)
      }
    }

}

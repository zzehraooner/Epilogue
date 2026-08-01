import ActivityKit
import WidgetKit
import SwiftUI

public struct StashActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var memoryCount: Int
        public var latestMemoryName: String
    }
    
    public var depoName: String
    
    public init(depoName: String) {
        self.depoName = depoName
    }
}

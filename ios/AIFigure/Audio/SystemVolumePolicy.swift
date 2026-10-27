import Foundation

enum SystemVolumePolicy {
    static func target(old: Float, new: Float, foreground: Bool, recording: Bool) -> Int? {
        guard foreground,!recording,old.isFinite,new.isFinite,(0...1).contains(old),(0...1).contains(new),abs(new-old)>0.0001 else { return nil }
        return Int((Double(new)*100).rounded())
    }
}

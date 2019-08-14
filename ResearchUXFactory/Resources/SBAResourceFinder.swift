//
//  SBAResourceFinder.swift
//  ResearchUXFactory
//
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import UIKit
import AudioToolbox

/**
 The SBAResourceFinderDelegate delegate is used to define additional functionality on the app delegate
 related to finding resources.
 */
@objc
@available(*, unavailable, message: "Use `SBAInfoManager.shared.resourceBundles` instead.")
public protocol SBAResourceFinderDelegate: class, NSObjectProtocol {
    
    /**
     @return Default resource bundle
    */
    func resourceBundle() -> Bundle
    
    /**
     Path to a given resource.
     @param resourceName    The name of the resource
     @param resourceType    The type of the resource
     @return                The path to the resource (if applicable)
    */
    func path(forResource resourceName: String, ofType resourceType: String) -> String?
}

@objc
open class SBAResourceFinder: NSObject {
    
    @objc
    public static let shared = SBAResourceFinder()
    
    private func resourceBundles() -> [Bundle] {
        return SBAInfoManager.shared.resourceBundles
    }
    
    @objc
    public func path(forResource resourceNamed: String, ofType: String, mainBundleOnly: Bool = false) -> String? {
        let path = Bundle.main.path(forResource: resourceNamed, ofType: ofType)
        if mainBundleOnly || (path != nil) {
            return path
        }
        else {
            for bundle in resourceBundles() {
                if let path = bundle.path(forResource: resourceNamed, ofType: ofType) {
                    return path
                }
            }
        }
        return nil
    }
    
    @objc
    public func image(forResource resourceNamed: String) -> UIImage? {
        if let image = UIImage(named: resourceNamed) {
            return image
        }
        else {
            for bundle in resourceBundles() {
                if let image = UIImage(named: resourceNamed, in: bundle, compatibleWith: nil) {
                    return image
                }
            }
        }
        return nil;
    }
    
    @objc
    public func data(forResource resourceNamed: String, ofType: String, bundle: Bundle? = nil) -> Data? {
        if let path = bundle?.path(forResource: resourceNamed, ofType: ofType) ??
            self.path(forResource: resourceNamed, ofType: ofType) {
            return (try? Data(contentsOf: URL(fileURLWithPath: path)))
        }
        return nil
    }
    
    @objc
    public func html(forResource resourceNamed: String) -> String? {
        if let data = self.data(forResource: resourceNamed, ofType: "html"),
            let html = String(data: data, encoding: String.Encoding.utf8) {
            return importHTML(html)
        }
        return nil
    }
    
    private func importHTML(_ input: String) -> String {
        
        // setup string
        var htmlString = input
        func search(_ str: String, _ range: Range<String.Index>?) -> Range<String.Index>? {
            return htmlString.range(of: str, options: .caseInsensitive, range: range, locale: nil)
        }
        
        // search for <import href="resourceName.html" /> and replace with contents of resource file
        var keepGoing = true
        while keepGoing {
            keepGoing = false
            if let startRange = search("<import", nil),
                let endRange = search("/>", startRange.upperBound..<htmlString.endIndex),
                let hrefRange = search("href", startRange.upperBound..<endRange.upperBound),
                let fileStartRange = search("\"", hrefRange.upperBound..<endRange.upperBound),
                let fileEndRange = search(".html\"", fileStartRange.upperBound..<endRange.upperBound) {
                let resourceName = String(htmlString[fileStartRange.upperBound..<fileEndRange.lowerBound])
                if let importText = html(forResource: resourceName) {
                    keepGoing = true
                    htmlString.replaceSubrange(startRange.lowerBound..<endRange.upperBound, with: importText)
                }
            }
        }
        
        return htmlString
    }
    
    @objc
    public func json(forResource resourceNamed: String, bundle: Bundle? = nil) -> [String : Any]? {
        do {
            if let data = self.data(forResource: resourceNamed, ofType: "json", bundle: bundle) {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                return json as? [String : Any]
            }
        }
        catch let error as NSError {
            // Throw an assertion rather than throwing an exception (or rethrow)
            // so that production apps don't crash.
            assertionFailure("Failed to read json file: \(error)")
        }
        return nil
    }
    
    @objc
    public func plist(forResource resourceNamed: String, mainBundleOnly: Bool = false) -> [String : Any]? {
        if let path = self.path(forResource: resourceNamed, ofType: "plist", mainBundleOnly: mainBundleOnly),
            let dictionary = NSDictionary(contentsOfFile: path) {
                return dictionary as? [String : Any]
        }
        return nil
    }
    
    @objc
    public func infoPlist(forResource resourceNamed: String) -> [String : Any]? {
        guard let dictionary = self.plist(forResource: resourceNamed, mainBundleOnly: true) else { return nil }
        var plist = dictionary
        // Look to see if there is a second plist source that includes private keys
        if let additionalInfo = self.plist(forResource: "\(resourceNamed)-private", mainBundleOnly: true) {
            plist = plist.sba_merge(from: additionalInfo)
        }
        return plist
    }
    
    @objc
    public func url(forResource resourceNamed: String, withExtension: String) -> URL? {
        if let url = Bundle.main.url(forResource: resourceNamed, withExtension: withExtension),
            (url as NSURL).checkResourceIsReachableAndReturnError(nil) {
            return url
        }
        else {
            for bundle in resourceBundles() {
                if let url = bundle.url(forResource: resourceNamed, withExtension: withExtension),
                    (url as NSURL).checkResourceIsReachableAndReturnError(nil) {
                    return url
                }
            }
        }
        return nil;
    }
    
    @objc
    public func systemSoundID(forResource resourceNamed: String, withExtension: String = "aif") -> SystemSoundID {
        guard let url = self.url(forResource: resourceNamed, withExtension: withExtension),
            let sound = SystemSound(soundURL: url)
        else {
            return 0
        }
        return sound.soundID
    }

}

/**
 Wraps a SystemSoundID.
 
 A class is used in order to provide appropriate cleanup when the sound is
 no longer needed.
 */
class SystemSound {
    var soundID: SystemSoundID = 0
    
    init?(soundURL: URL) {
        if AudioServicesCreateSystemSoundID(soundURL as CFURL, &soundID) != noErr {
            return nil
        }
    }
    
    deinit {
        AudioServicesDisposeSystemSoundID(soundID)
    }
}

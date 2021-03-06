/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage

class FaviconManager : BrowserHelper {
    let profile: Profile!
    weak var browser: Browser?

    init(browser: Browser, profile: Profile) {
        self.profile = profile
        self.browser = browser

        if let path = NSBundle.mainBundle().pathForResource("Favicons", ofType: "js") {
            if let source = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
                var userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
                browser.webView.configuration.userContentController.addUserScript(userScript)
            }
        }
    }

    class func name() -> String {
        return "FaviconsManager"
    }

    func scriptMessageHandlerName() -> String? {
        return "faviconsMessageHandler"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        println("DEBUG: faviconsMessageHandler message: \(message.body)")

        let manager = SDWebImageManager.sharedManager()
        if let url = browser?.webView.URL?.absoluteString {
            let site = Site(url: url, title: "")
            if let icons = message.body as? [String: Int] {
                for icon in icons {
                    if let iconUrl = NSURL(string: icon.0) {
                        manager.downloadImageWithURL(iconUrl, options: SDWebImageOptions.LowPriority, progress: nil, completed: { (img, err, cacheType, success, url) -> Void in
                            let fav = Favicon(url: url.absoluteString!,
                                date: NSDate(),
                                type: IconType(rawValue: icon.1)!)

                            fav.width = Int(img.size.width)
                            fav.height = Int(img.size.height)

                            self.profile.favicons.add(fav, site: site, complete: nil)
                        })
                    }
                }
            }
        }
    }
}
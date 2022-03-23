//
//  Extension.swift
//  URLTextView
//
//  Created by Vinu David Jose on 22/03/22.
//

import Foundation
import UIKit

extension UITextView {
    func numberOfLines() -> Int {
        let layoutManager = self.layoutManager
        let numberOfGlyphs = layoutManager.numberOfGlyphs
        var lineRange: NSRange = NSRange(location: 0, length: 1)
        var index = 0
        var numberOfLines = 0

        while index < numberOfGlyphs {
            layoutManager.lineFragmentRect(
                forGlyphAt: index, effectiveRange: &lineRange
            )
            index = NSMaxRange(lineRange)
            numberOfLines += 1
        }
        return numberOfLines - 1
    }
}

extension String {

    public func substring(with nsrange: NSRange) -> Substring? {
        guard let range = Range(nsrange, in: self) else { return nil }
        return self[range]
    }

    public var isHTML: Bool {
        if isEmpty {
            return false
        }
        return (range(of: "<(\"[^\"]*\"|'[^']*'|[^'\">])*>", options: .regularExpression) != nil)
    }


    public var html2AttributedString: NSAttributedString? {
        if !self.isHTML {
            return NSAttributedString(string: self,
                                      attributes:[NSAttributedString.Key.font:
                                                    UIFont.systemFont(ofSize: 12),
                                                  NSAttributedString.Key.foregroundColor:
                                                    UIColor.black as Any])
        } else {
            return Data(utf8).html2AttributedString
        }

    }

    // Converts the string to half size if its full size
    public var halfSize: String {
        let text: CFMutableString = NSMutableString(string: self) as CFMutableString
        CFStringTransform(text, nil, kCFStringTransformFullwidthHalfwidth, false)
        return text as String
    }
}

extension Data {

    public var html2AttributedString: NSAttributedString? {
        do {
            let attributeString = try NSAttributedString(data: self,
                                                         options: [.documentType: NSAttributedString.DocumentType.html,
                                                                   .characterEncoding: String.Encoding.utf8.rawValue],
                                                         documentAttributes: nil)
            if let attributtedString = attributeString.mutableCopy() as? NSMutableAttributedString {
                if attributeString.string.isEmpty {
                    return nil
                }
                // setting app font to html string
                let range = NSRange(location: 0,
                                    length: attributtedString.length) // Bugfix: SBPF_SIT-100
                attributtedString.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)],
                                                range: range)
                attributtedString.addAttribute(NSAttributedString.Key.foregroundColor,
                                               value: UIColor.black as Any, range: range)
                return attributtedString
            }
            return nil

        } catch {
            print("error:", error)
            return  nil
        }
    }
    public var html2String: String { html2AttributedString?.string ?? "" }
}

extension NSAttributedString {

    /// Method to convert attributted text to
    /// html format with link and new line support
    /// - Returns: html string
    public func toHtml() -> String? {

        var linkArray = [(url: String, range: NSRange)]()
        let range = NSRange(location: 0, length: length)
        self.enumerateAttribute(NSAttributedString.Key.link,
                                in:range,
                                options:.longestEffectiveRangeNotRequired) { value, range, _ in
            if let url = value as? NSURL, let string = url.absoluteString {
                linkArray.append((url: string, range: range))
            }
        }
        var htmlString = self.string
        var location:Int = 0
        linkArray.forEach { (hyperLink) in
            location += hyperLink.range.location
            let linkRange =  NSRange(location: location, length: hyperLink.range.length)
            if let substring = htmlString.substring(with: linkRange), let range = Range(linkRange, in: htmlString) {

                let urlStr = hyperLink.url
                let replacingString = "<a href='" + urlStr + "'>\(substring)</a>"

                location += replacingString.count
                location -= hyperLink.range.location
                location -= substring.count

                htmlString = htmlString.replacingCharacters(in: range, with: replacingString)
            } else {
                print("error occured in html conversion")
            }
        }
        htmlString = htmlString.replacingOccurrences(
            of: "\n", with: "<br>")
        return htmlString
    }
    /// Add hyper link text
    /// - Parameters:
    ///   - url: url string
    ///   - string: Text in which url to be added
    ///   - substring: substring part of the string
    ///   - font: Font for the string
    /// - Returns: Attributted string
    public func addHyperLink(
        urlString: String,
        in string: String,
        substring: String,
        font: UIFont? = nil) -> NSAttributedString {
            let nsString = NSString(string:string)
            let substringRange = nsString.range(of:substring)
            let attributedString = NSMutableAttributedString(string:string)
            let stringurlfixed = urlString.addingPercentEncoding(withAllowedCharacters:
                                                                        .urlQueryAllowed) ?? urlString.halfSize
            if let url = URL(string: stringurlfixed) {
                if let stringFont = font {
                    attributedString.addAttribute(.font, value: stringFont, range: substringRange)
                    attributedString.addAttribute(.link, value: url, range:substringRange)
                }
            }
            return attributedString
        }

}

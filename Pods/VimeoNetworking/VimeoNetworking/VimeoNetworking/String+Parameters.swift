//
//  String+Utilities.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/29/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

public extension String
{
    /**
     Construct a dictionary of parameters from the current string
     
     - returns: a dictionary of parameters if parsing succeeded
     */
    func parametersDictionaryFromQueryString() -> [String: String]?
    {
        var parametersDictionary: [String: String] = [:]
        
        let scanner = NSScanner(string: self)
        while !scanner.atEnd
        {
            var name: NSString?
            let equals = "="
            scanner.scanUpToString(equals, intoString: &name)
            scanner.scanString(equals, intoString: nil)
            
            var value: NSString?
            let ampersand = "&"
            scanner.scanUpToString(ampersand, intoString: &value)
            scanner.scanString(ampersand, intoString: nil)
            
            if let name = name?.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding),
                let value = value?.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
            {
                parametersDictionary[name] = value
            }
        }
        
        return parametersDictionary.count > 0 ? parametersDictionary : nil
    }
    
    /**
     Splits a link string into a path and a query
     
     - returns: a tuple containing: the path with any query string removed, and the query string if found
     */
    func splitLinkString() -> (path: String, query: String?)
    {
        let components = self.componentsSeparatedByString("?")
        
        if components.count == 2
        {
            return (path: components[0], query: components[1])
        }
        else
        {
            return (path: self, query: nil)
        }
    }
}

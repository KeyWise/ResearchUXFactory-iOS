/*
 Copyright (c) 2017, Sage Bionetworks. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


import Foundation


public extension Array where Element: Equatable {
    
    /**
     Look for the next object which matches the given object. This is used for arrays
     that may have the same object defined multiple times within the array.
     
     @param object  Optional object to look for a match. If `nil` the first element in the series is returned.
     
     @return        Next object that matches this one or `nil` if not found.
     */
    public func sba_nextMatch(_ object: Array.Iterator.Element?) -> Array.Iterator.Element? {
        guard let match = object else { return self.first }
        return self.sba_next({ (match == $0) })
    }
}


public extension Array {
    
    /**
     Return an `Array` mutated to include the given element.
     
     @param newElement  The element to append.
     
     @return            An `Array` with the element appended to the end.
     */
    public func sba_appending(_ newElement: Element) -> [Element] {
        var mutable = self
        mutable.append(newElement)
        return mutable
    }
    
    /**
     Return an `Array` mutated to include the given elements.
     
     @param contents    The elements to append.
     
     @return            An `Array` with the elements appended to the end.
     */
    public func sba_appending(contentsOf contents: [Element]) -> [Element] {
        var mutable = self
        mutable.append(contentsOf: contents)
        return mutable
    }
}

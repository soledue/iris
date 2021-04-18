//
//  Extension.swift
//  Iris
//
//  Created by Ivailo Kanev on 05/03/21.
//

import Foundation
import Cocoa
extension NSScreen {
    var isMain: Bool {
        return frame.origin.x == 0 && frame.origin.y == 0
    }
    var deviceID: UInt32? {
        let description: NSDeviceDescriptionKey = NSDeviceDescriptionKey(rawValue: "NSScreenNumber")
        if let deviceID = deviceDescription[description] as? NSNumber {
            return deviceID.uint32Value
        }
        return nil
    }
    var isBuildIn: Bool {
        guard let deviceID = deviceID else {
            return false
        }
        return CGDisplayIsBuiltin(deviceID) != 0
    }
    var currentResolution: CGSize {
        guard let deviceID = deviceID else {
            return .zero
        }
        return CGDisplayBounds(deviceID).size
    }
    var allDisplayModes: [CGDisplayMode] {
        guard let deviceID = deviceID else {
            return []
        }
        let options = [kCGDisplayShowDuplicateLowResolutionModes as String: 1] as CFDictionary
        guard let modes = CGDisplayCopyAllDisplayModes(deviceID, options) else {
            return []
        }
        var modesArray = [CGDisplayMode]()
        
        let count = CFArrayGetCount(modes)
        for i in 0..<count {
            let modeRaw = CFArrayGetValueAtIndex(modes, i)
            let mode = unsafeBitCast(modeRaw, to: CGDisplayMode.self)
            modesArray.append(mode)
        }
        return modesArray
    }
    func ioInfo() -> NSDictionary? {
        guard let deviceID = deviceID else {
            return nil
        }
        var service: io_iterator_t = 0
        IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"), &service)
        let vendorToMatch = CGDisplayVendorNumber(deviceID)
        let productToMatch = CGDisplayModelNumber(deviceID)
        let serialToMatch = CGDisplaySerialNumber(deviceID)
        repeat {
            let serv = IOIteratorNext(service)
            if serv == 0 {
                break
            }
            if let dict = IODisplayCreateInfoDictionary(serv, IOOptionBits(kIODisplayOnlyPreferredName)) {
                let info = dict.takeRetainedValue() as NSDictionary
                if
                    let vendor = info[kDisplayVendorID] as? Int32, vendor == vendorToMatch,
                    let model = info[kDisplayProductID] as? Int32, model == productToMatch,
                    ((info[kDisplaySerialNumber] as? Int32) ?? 0) == serialToMatch
                {
                    return info
                }
            }
        } while true
        
        return nil
    }
    func set(mode: CGDisplayMode) {
        guard let deviceID = deviceID else {
            return
        }

        let config = UnsafeMutablePointer<CGDisplayConfigRef?>.allocate(capacity: 1)
        if (CGBeginDisplayConfiguration(config) == CGError.success) {
            CGConfigureDisplayWithDisplayMode(config.pointee, deviceID, mode, nil)
            CGCompleteDisplayConfiguration(config.pointee, CGConfigureOption.permanently)
        }
    }
    func setAsMain() {
        defer {
            config.deallocate()
        }
        let offsetX = frame.origin.x
        let offsetY = frame.origin.y
        let config = UnsafeMutablePointer<CGDisplayConfigRef?>.allocate(capacity: 1)
        if (CGBeginDisplayConfiguration(config) == CGError.success) {
            for screen in NSScreen.screens {
                if let deviceID = screen.deviceID {
                    let newX = Int32(screen.frame.origin.x - offsetX)
                    let newY = -Int32(screen.frame.origin.y - offsetY)
                    CGConfigureDisplayOrigin(config.pointee, deviceID, newX, newY)
                }
            }
            CGCompleteDisplayConfiguration(config.pointee, CGConfigureOption.permanently)
        }
    }
}
extension CGDisplayMode {
    public var isStretched: Bool{
        return ioFlags & UInt32(kDisplayModeStretchedFlag) == UInt32(kDisplayModeStretchedFlag)
    }
    public var isInterlaced: Bool{
        return ioFlags & UInt32(kDisplayModeInterlacedFlag) == UInt32(kDisplayModeInterlacedFlag)
    }
}
extension Array where Element: CGDisplayMode {
    func removeDuplicates() -> [CGDisplayMode] {
        var result = [CGDisplayMode]()

        for value in self {
            if !result.contains(where: {value.height == $0.height && value.width == $0.width}) {
                result.append(value)
            }
        }
        return result
    }
}
public extension String {
    var typeset: TypeSet {
        return TypeSet(string: self)
    }
}
public class TypeSet {
    var s: String
    var a: NSMutableAttributedString
    var r: NSRange
    init(string s: String) {
        self.s = s
        self.a = NSMutableAttributedString(string: s)
        self.r = NSString(string: s).range(of: s)
    }
    func color(color c: NSColor)-> TypeSet {
        a.addAttributes([NSAttributedString.Key.foregroundColor: c], range: r)
        return self
    }
    func font(font f: NSFont)->TypeSet {
        a.addAttributes([NSAttributedString.Key.font: f], range: r)
        return self
    }
    var string: NSAttributedString {
        return a
    }
    func underline(color: NSColor) -> TypeSet {
        a.addAttributes([NSAttributedString.Key.underlineColor: color, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue], range: r)
        return self
    }
    func аligment(alignment: NSTextAlignment) -> TypeSet {
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = alignment
        a.addAttributes([NSAttributedString.Key.paragraphStyle: titleParagraphStyle], range: r)
        return self
    }
    func spacing(spacing: CGFloat) -> TypeSet {
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.minimumLineHeight = spacing
        titleParagraphStyle.maximumLineHeight = spacing
        a.addAttributes([NSAttributedString.Key.paragraphStyle: titleParagraphStyle], range: r)
        return self
    }
    func contains(substring: String) -> TypeSet {
        r = NSString(string: s).range(of: substring)
        return self
    }
    func range(from: Int, lenght: Int) -> TypeSet {
        if (from  <= s.count) && (from + lenght) <= s.count {
            r = NSMakeRange(from, lenght)
        }
        return self
    }
}

public func +(lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
    let lhs = NSMutableAttributedString(attributedString: lhs)
    lhs.append(rhs)
    return lhs
}

public func +=(lhs: NSAttributedString, rhs: NSAttributedString) {
    let lhs = NSMutableAttributedString(attributedString: lhs)
    lhs.append(rhs)
}

extension NSImage {
    func canvas(_ canvasSize: CGSize, aligment: NSImageAlignment = .alignCenter) -> NSImage {
        
        let newImage = NSImage(size: canvasSize)
        newImage.lockFocus()
        var x = (canvasSize.width - size.width) / 2
        if aligment == .alignRight {
            x = (canvasSize.width - size.width)
        }
        let centeredImageRect = CGRect(x: x,
                                       y: (canvasSize.height - size.height) / 2,
                                       width: size.width,
                                       height: size.height)
        draw(in: centeredImageRect, from: NSMakeRect(0, 0, size.width, size.height), operation: .sourceOver, fraction: CGFloat(1))
        newImage.unlockFocus()
        newImage.size = canvasSize
        return NSImage(data: newImage.tiffRepresentation!)!
        
    }
    func current(_ isDark: Bool) -> NSImage {
        let color: NSColor = isDark ? .white : .black
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        draw(in: NSMakeRect(0, 0, size.width, size.height), from: NSMakeRect(0, 0, size.width, size.height), operation: .sourceOver, fraction: CGFloat(1))
        let path = NSBezierPath(roundedRect: NSRect(x: 0, y: (size.height - 8) / 2, width: 8, height: 8), xRadius: 8, yRadius: 8)
        color.setFill()
        path.fill()
        newImage.unlockFocus()
        newImage.size = size
        return NSImage(data: newImage.tiffRepresentation!)!
    }
    func add(_ isDark: Bool) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        draw(in: NSMakeRect(0, 0, size.width, size.height), from: NSMakeRect(0, 0, size.width, size.height), operation: .sourceOver, fraction: CGFloat(1))
        let plus = NSImage(named: "plus")
        plus?.draw(in: NSMakeRect(0, (size.height - 10) / 2, 10, 10))
        newImage.unlockFocus()
        newImage.size = size
        return NSImage(data: newImage.tiffRepresentation!)!
    }
    func remove(_ isDark: Bool) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        draw(in: NSMakeRect(0, 0, size.width, size.height), from: NSMakeRect(0, 0, size.width, size.height), operation: .sourceOver, fraction: CGFloat(1))
        let plus = NSImage(named: "cancel")
        plus?.draw(in: NSMakeRect(0, (size.height - 10) / 2, 10, 10))
        newImage.unlockFocus()
        newImage.size = size
        return NSImage(data: newImage.tiffRepresentation!)!
    }
    func resize(_ canvasSize: CGSize) -> NSImage {
        let destSize = NSMakeSize(canvasSize.width, canvasSize.height)
        let newImage = NSImage(size: destSize)
        newImage.lockFocus()
        draw(in: NSMakeRect(0, 0, destSize.width, destSize.height), from: NSMakeRect(0, 0, size.width, size.height), operation: .sourceOver, fraction: CGFloat(1))
        newImage.unlockFocus()
        newImage.size = destSize
        return NSImage(data: newImage.tiffRepresentation!)!
    }

    static func empty(with size: CGSize) -> NSImage? {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        newImage.unlockFocus()
        newImage.size = size
        return NSImage(data: newImage.tiffRepresentation!)!
    }
    func inverted() -> NSImage {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return self
        }

        let ciImage = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIColorInvert") else {
            return self
        }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        guard let outputImage = filter.outputImage else {
            return self
        }

        guard let outputCgImage = outputImage.toCGImage() else {
            return self
        }

        return NSImage(cgImage: outputCgImage, size: self.size)
    }
}
fileprivate extension CIImage {
    func toCGImage() -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(self, from: self.extent) {
            return cgImage
        }
        return nil
    }
}

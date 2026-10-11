#!/usr/bin/swift
//  Author: Hari Sekhon
//  Date: 2026-03-27 17:32:24 -0500 (Fri, 27 Mar 2026)
//
//  vim:ts=4:sts=4:sw=4:et
//
//  https///github.com/HariSekhon/DevOps-Bash-tools
//
//  License: see accompanying Hari Sekhon LICENSE file
//
//  If you're using my code you're welcome to connect with me on LinkedIn
//  and optionally send me feedback
//
//  https://www.linkedin.com/in/HariSekhon
//

// HUD style (Heads-Up Display)
//
// This doesn't steal window focus so you won't have to stop typing to address it
//
// This is sample code only, for reference, I am not using this regularly
//
// Use instead macnotify.sh or macalert.sh
//
// See the HariSekhon/Knowledge-Base page on Mac for more details
// on the different types of desktop notifications and alerts that can be done

import AppKit

// --- CONFIGURATION ---
let displayDuration: Double = 1.2      // Seconds before it vanishes
let hudWidth: CGFloat = 260            // Width of the pop-up
let hudHeight: CGFloat = 70            // Height of the pop-up
let cornerRadius: CGFloat = 20         // Roundness of the edges
let fontSize: CGFloat = 17             // Size of the text
// ---------------------

let arguments = CommandLine.arguments
let message = arguments.count > 1 ? arguments[1] : "Alert"

let app = NSApplication.shared
let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: hudWidth, height: hudHeight),
    styleMask: [.borderless],
    backing: .buffered,
    defer: false
)

// Styling the HUD Window
window.level = .statusBar
window.isOpaque = false
window.backgroundColor = .clear
window.center()
window.ignoresMouseEvents = true // Allows you to click "through" it to windows behind

// The Blur Effect (Materials)
let visualEffect = NSVisualEffectView(frame: window.contentView!.bounds)
visualEffect.autoresizingMask = [.width, .height]

/* THEME OPTIONS for .material:
   .hudWindow      - Classic dark HUD (Default)
   .ultraDark      - Very dark, high contrast
   .fullScreenUI   - Modern semi-transparent
   .light          - White frosted glass
*/
visualEffect.material = .hudWindow
visualEffect.state = .active
visualEffect.wantsLayer = true
visualEffect.layer?.cornerRadius = cornerRadius
window.contentView?.addSubview(visualEffect)

// The Text Label
let label = NSTextField(labelWithString: message)
label.font = .systemFont(ofSize: fontSize, weight: .semibold)
label.textColor = .white
label.alignment = .center
label.frame = visualEffect.bounds
visualEffect.addSubview(label)

window.makeKeyAndOrderFront(nil)

// Auto-close timer
DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
    exit(0)
}

app.run()

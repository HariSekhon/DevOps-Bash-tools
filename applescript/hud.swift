//
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

import Cocoa

let arguments = CommandLine.arguments
let message = arguments.count > 1 ? arguments[1] : "Notification"

let visualEffect = NSVisualEffectView()
visualEffect.blendingMode = .behindWindow
visualEffect.state = .active
visualEffect.material = .hudWindow
visualEffect.layer?.cornerRadius = 18

let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 300, height: 80),
    styleMask: [.borderless],
    backing: .buffered, defer: false)

window.contentView = visualEffect
window.isOpaque = false
window.backgroundColor = .clear
window.level = .floating
window.center()
window.makeKeyAndOrderFront(nil)

let label = NSTextField(labelWithString: message)
label.font = NSFont.systemFont(ofSize: 18, weight: .medium)
label.textColor = .white
label.alignment = .center
label.frame = window.contentView!.bounds
window.contentView?.addSubview(label)

DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
    NSApp.terminate(nil)
}

NSApplication.shared.run()

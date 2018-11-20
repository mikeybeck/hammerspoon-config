-- A global variable for the Hyper Mode
hyper = hs.hotkey.modal.new({}, 'F17')

-- Enter Hyper Mode when F18 (Hyper/Capslock) is pressed
function enterHyperMode()
  hyper.triggered = false
  hyper:enter()
end

-- Leave Hyper Mode when F18 (Hyper/Capslock) is pressed,
-- send ESCAPE if no other keys are pressed.
function exitHyperMode()
  hyper:exit()
  if not hyper.triggered then
    hs.eventtap.keyStroke({}, 'ESCAPE')
  end
end

-- Bind the Hyper key
f18 = hs.hotkey.bind({}, 'F18', enterHyperMode, exitHyperMode)

local inspect = require 'inspect'

hs.alert.show("Config loaded")

hyper:bind({}, "R", function()
    hs.reload()
    hyper.triggered = true
end)

hyper:bind({}, "W", function()
    hs.alert.show("Hello World!")
    hyper.triggered = true
end)

require "layout"

-- require "everhourTime"
-- hs.loadSpoon('AClock')


local menubar = require "menubar"
menubar.init()

hs.loadSpoon("BitbucketPullRequests")

require "muteMic"


hyper:bind({}, "Space", function()
    hs.hints.windowHints()
    hyper.triggered = true
end)

-- Restart uBar
hyper:bind({}, "U", function()
    ubar = hs.application.get('uBar')
    hs.application.kill(ubar)
    hs.timer.doAfter(2, function() hs.application.launchOrFocus('uBar') end)
    hyper.triggered = true
end)

-- Set up tinker
hyper:bind({}, "T", function()
    hs.eventtap.keyStrokes('php artisan tinker')
    hs.eventtap.keyStroke({}, 'RETURN')
    hs.timer.usleep(1000)
    -- hs.eventtap.keyStrokes('\\Auth::loginUsingId(3);')
    -- hs.eventtap.keyStroke({}, 'RETURN')
    hs.eventtap.keyStrokes('$customer = App\\customer::find(81570036);')
    hs.eventtap.keyStroke({}, 'RETURN')
    hs.eventtap.keyStrokes('$whitelabel = App\\whiteLabel::findSp(200);')
    hs.eventtap.keyStroke({}, 'RETURN')
    hyper.triggered = true
end)


-- Skip current Spotify track 15 seconds forward
hyper:bind({}, "f9", function()
    hs.spotify.setPosition(hs.spotify.getPosition() + 15)
    hyper.triggered = true
end)

-- Rewind current Spotify track by 15 seconds
hyper:bind({}, "f7", function()
    hs.spotify.setPosition(hs.spotify.getPosition() - 15)
    hyper.triggered = true
end)

hs.urlevent.bind("someAlert", function(eventName, params)
    hs.alert.show("Received someAlert")
end)

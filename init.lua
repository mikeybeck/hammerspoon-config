local inspect = require 'inspect'



hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
  hs.reload()
end)
hs.alert.show("Config loaded")

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "W", function()
  hs.alert.show("Hello World!")
end)

require "layout"

-- require "everhourTime"
-- hs.loadSpoon('AClock')


local menubar = require "menubar"
menubar.init()


-- require "test"
-- test.init()

-- require "bitbucketPRs"
hs.loadSpoon("BitbucketPullRequests")

require "muteMic"


hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Space", function()
	-- test1()
	-- test2()
	hs.hints.windowHints()

--	test4()
end)


hs.hotkey.bind({"cmd", "alt", "ctrl"}, "C", function()
	-- test1()
	-- test2()
	print(inspect(hs.settings.get('BBprev')))

--	test4()
end)

-- Restart uBar
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "U", function()
    ubar = hs.application.get('uBar')
    hs.application.kill(ubar)
    hs.timer.doAfter(2, function() hs.application.launchOrFocus('uBar') end)
end)

-- Set up tinker
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "T", function()
    hs.eventtap.keyStrokes('php artisan tinker')
    hs.eventtap.keyStroke({}, 'RETURN')
    hs.timer.usleep(1000)
    -- hs.eventtap.keyStrokes('\\Auth::loginUsingId(3);')
    -- hs.eventtap.keyStroke({}, 'RETURN')
    hs.eventtap.keyStrokes('$customer = App\\customer::find(81570036);')
    hs.eventtap.keyStroke({}, 'RETURN')
    hs.eventtap.keyStrokes('$whitelabel = App\\whiteLabel::findSp(200);')
    hs.eventtap.keyStroke({}, 'RETURN')
end)

-- Skip current Spotify track 15 seconds forward
hs.hotkey.bind({"alt", "ctrl"}, "f9", function()
    hs.spotify.setPosition(hs.spotify.getPosition() + 15)
end)

-- Rewind current Spotify track by 15 seconds
hs.hotkey.bind({"alt", "ctrl"}, "f7", function()
    hs.spotify.setPosition(hs.spotify.getPosition() - 15)
end)

hs.urlevent.bind("someAlert", function(eventName, params)
    hs.alert.show("Received someAlert")
end)

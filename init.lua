local inspect = require 'inspect'



hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
  hs.reload()
end)
hs.alert.show("Config loaded")

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "W", function()
  hs.alert.show("Hello World!")
end)

require "layout"


local menubar = require "menubar"
menubar.init()


-- require "test"
-- test.init()

require "bitbucketPRs"

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

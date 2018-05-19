-- Maximise window on LHS
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Left", function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h - 45
  win:setFrame(f)
end)

-- Maximise window on RHS
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Right", function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x / 2
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h - 45
  win:setFrame(f)
end)

-- Maximise window
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Up", function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x
  f.y = max.y
  f.w = max.w
  f.h = max.h - 45
  win:setFrame(f)
end)




-- Initiate dev layout
-- hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Return", function()
-- local leftScreen = hs.screen.allScreens()[2];
-- local middleScreen = hs.screen.allScreens()[3];
-- local rightScreen = hs.screen.allScreens()[1];
-- local windowLayout = {
--     {"Rambox",  nil,          rightScreen, hs.layout.maximized,    nil, nil},
--     {"PhpStorm",  nil,          middleScreen, hs.layout.maximized,    nil, nil},
--     {"DataGrip",    nil,      leftScreen, hs.layout.right50,   nil, nil},
--     {"iTerm2",    nil,      middleScreen, nil,   nil, nil},
--     {"Tower",    nil,      leftScreen, nil,   nil, nil},
-- }
-- hs.layout.apply(windowLayout)
-- hs.alert.show('dev layout initiated')
-- end)







-- hs.hotkey.bind({"cmd", "alt", "ctrl"}, "H", function()
--   hs.notify.new({title="Hammerspoon", informativeText="Setting home layout"}):send()
--   local leftScreen = hs.screen.allScreens()[2];
--   local middleScreen = hs.screen.allScreens()[3];
--   local rightScreen = hs.screen.allScreens()[1];
--   local windowLayout = {
--         {"PhpStorm", nil, middleScreen, hs.layout.maximized,    nil, nil},
--         {"iTerm2",    nil,      middleScreen, {x=0.25, y=0.25, w=0.6, h=0.5},   nil, nil},
-- --        {"Charles", nil, homeMonitor, {x=0.6, y=0.6, w=0.4, h=0.4},   nil, nil},
-- --        {"Safari", nil, homeMonitor, {x=0.6, y=0, w=0.4, h=0.6}, nil, nil},        
--     }
--     hs.layout.apply(windowLayout)
-- end)



--
-- Try to setup the workplace workflow
--
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Return", function()

  local workApplications = { 'Rambox','Phpstorm','DataGrip','iTerm2','Tower','Toggl'}
  local workApplicationWatcher;
  
  hs.notify.new({title="Hammerspoon", informativeText="Starting work applications"}):send()

  --
  -- Discover which apps are needed (not launched or visible)
  --
  local neededApps = {}
  for key, value in pairs(workApplications) do
    local app = hs.application.find(value);
    if app == nil then
      table.insert(neededApps,value)
    else
      local windows = app:allWindows();
      for s, t in pairs(windows) do
        t:raise()
      end 
    end 
  end 

  
  if #neededApps == 0 then
    doWorkLayout()
  else
    workApplicationWatcher = hs.application.watcher.new(appLaunched)
    workApplicationWatcher:start()

    for key, value in pairs(neededApps) do      
      hs.application.launchOrFocus(value)
    end 

  end

end)


--
-- Watcher for launching apps, when app launches are required
--
function appLaunched( appName, eventType, app )
  if eventType ~= hs.application.watcher.launched then
    return
  end   

  local launchCount = 0
  for key, value in pairs(workApplications) do
    if hs.application.find(value) ~= nil then 
      launchCount = launchCount + 1
    end 
  end 

  if launchCount == #workApplications then
    workApplicationWatcher:stop()
    doWorkLayout()
  end   
end


--
-- Success, set up the work layout
--
function doWorkLayout()
  local leftScreen = hs.screen.allScreens()[2];
  local middleScreen = hs.screen.allScreens()[3];
  local rightScreen = hs.screen.allScreens()[1];
  local windowLayout = {
    {"Rambox",  nil,          rightScreen, hs.layout.maximized,    nil, nil},
    {"PhpStorm",  nil,          middleScreen, hs.layout.maximized,    nil, nil},
    {"DataGrip",    nil,      leftScreen, hs.layout.right50,   nil, nil},
    {"iTerm2",    nil,      middleScreen, {x=0.25, y=0.25, w=0.6, h=0.5},   nil, nil},
    {"Tower",    nil,      leftScreen, {x=0.25, y=0.25, w=0.6, h=0.5},   nil, nil},
    {"Toggl",    nil,      rightScreen, nil, nil, nil},
  }
  hs.notify.new({title="Hammerspoon", informativeText="Applying work layout"}):send()
  hs.layout.apply(windowLayout)
end 
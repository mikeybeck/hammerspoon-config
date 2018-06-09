-- Bitbucket Pull Requests monitor module for Hammerspoon
-- v0.1

local inspect = require 'inspect' -- This isn't *required* but helps with debugging.  Remove this line if you don't have this file.


-- TODO:
-- Separate my PRs
-- Move icons/images to github repo & serve from there
-- Updated x time ago (currently displays 'updated at time')
-- Improve automatic refresh

--[[
Note:
Build state currently not functioning; I'm not sure why - the BB API isn't returning the status value
Build state isn't too important and requires a API call, so disabled for now
]]

local config = require 'config'

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Down", function()
	-- test1()
	-- test2()
    hs.alert.show('testing')

    -- hs.timer.new(5, function() hs.alert.show('timer') end)
    test3(config.bitbucket.username, config.bitbucket.password)

    testDoEveryStart(username, password)
end)

local testTimerValue

function testDoEveryStart(username, password)
  -- assertIsNil(testTimerValue)
  testTimerValue = 0

  testTimer = hs.timer.doEvery(60, function()
        if type(testTimerValue) == "number" then
          if testTimerValue > 60 then
            testTimerValue = true
          elseif testTimerValue % 5 == 0 then
            test3(username, password)
            testTimerValue = testTimerValue + 1
            	print(testTimerValue)
            		      hs.alert.show('Reloading PRs')

          -- else
          	-- Update time in menu

          end
        end
      end)
  -- assertTrue(testTimer:running())

end



hs.hotkey.bind({"cmd", "alt", "ctrl"}, "x", function()
	-- test1()
	-- test2()
    hs.alert.show('Reloading PRs...')

	test3(config.bitbucket.username, config.bitbucket.password)

--	test4()
end)


local bitbucket = {}
local numRuns = 0
local lastUpdatedAt


function test3(username, password)
	local url = 'https://bitbucket.org/api/2.0/repositories/'.. config.bitbucket.repo_owner ..'/'.. config.bitbucket.repo_slug ..'/pullrequests/'
	local bodyTable = {}
	author_name = '';
	title = '';
	num_approvals = 0;
	approved_by_me = false;
	numRuns = numRuns + 1
	lines = {}

	menuItem:setTitle('...')

	hs.http.asyncGet(url, {Authorization = "Basic " .. hs.base64.encode(username .. ":" .. password)}, function(status, body, headers)
		if status == 200 then

			bodyTable = hs.json.decode(body)

			values = bodyTable.values[0] or bodyTable.values[1]

			for key, value in pairs(bodyTable.values) do

				author_name = value.author.display_name
				title = value.title
				num_comments = value.comment_count
				link = value.links.html.href

				local url2 = value.links.self.href

				status2, body2, headers2 = hs.http.get(url2, {Authorization = "Basic " .. hs.base64.encode(username .. ":" .. password)})
				if status2 == 200 then
					body2 = hs.json.decode(body2)
					participants = body2.participants
					approved_by_me = false
					num_approvals = 0

					for key2, value2 in pairs(body2.participants) do

						num_approvals = num_approvals + (value2.approved and 1 or 0)

						participant_name = value2.user.display_name

						if participant_name == 'Mike Beck' and value2.approved then
							approved_by_me = true
						end

					end


					-- local url3 = value.links.statuses.href

					-- status3, body3, headers3 = hs.http.get(url3, {Authorization = "Basic " .. hs.base64.encode(username .. ":" .. password)})

					-- if status3 == 200 then
					-- 	body3 = hs.json.decode(body3)

					-- 	print (inspect(body3))
					-- 							print (inspect(headers3))
					-- 													print (inspect(url3))

					-- 	values3 = body3.values[0] or body3.values[1]

						build_state = 'SUCCESSFUL' --values3.state

				        line = { approved = approved_by_me, author = author_name, title = title, approvals = num_approvals, comments = num_comments, state = build_state, url = link }  --$(_jq '.num_comments') | href=$(_jq '.link_html') color=$colour"
				        table.insert(lines, line)

					-- end

				else
					print("bb call2 failed with status code: " .. status)
				end

			end

		else
			print("bb call failed with status code: " .. status)

        end

        -- Get current time for 'last updated at' value
        local hour = os.date("%I")
        if string.sub(hour, 1, 1) == '0' then
            hour = string.sub(hour, 2)
        end
        lastUpdatedAt = os.date(hour .. ":%M:%S %p")
        doMenu(lines)

	end)

	return bodyTable

end

menuItem = hs.menubar.new()

function doMenu(lines)
	  if menuItem:isInMenubar() then
	    menuItem:delete()
	    menuItem = hs.menubar.new()
	  end

		prIcon = hs.image.imageFromURL('https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Octicons-git-pull-request.svg/180px-Octicons-git-pull-request.svg.png')
		commentsIcon = hs.image.imageFromURL('https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Octicons-git-pull-request.svg/180px-Octicons-git-pull-request.svg.png')
		size = { h = 23, w = 20 }
		prIcon = prIcon:setSize(size)
		commentsIcon = commentsIcon:setSize(size)

		menu = { { title = "View all open pull requests",
		fn = function() hs.urlevent.openURL('https://bitbucket.org/blasttechnologies/arena/pull-requests/') end } }

		table.insert(menu, { title = '-' })

		num_prs = 0
		num_approved = 0
		for key, value in pairs(lines) do

			BBprev = hs.settings.get('BBprev')
            bbkey = value.url:match( "([^/]+)$" )

			if BBprev[bbkey] ~= nil then
				value.prev = { approvals = BBprev[bbkey].approvals, comments = BBprev[bbkey].comments }
			else
				value.prev = { approvals = 0, comments = 0 }
			end


			value.approvals2 = value.approvals .. ' '
			if value.approvals ~= value.prev.approvals then
				value.approvals2 = value.approvals .. '*'
			end
			value.comments2 = value.comments .. ' '
			if value.comments ~=
				value.prev.comments then
				value.comments2 = value.comments .. '*'
			end

			while string.len(value.author) < 15 do
				value.author = value.author .. ' '
			end

			if string.len(value.title) > 35 then
				value.title = string.sub(value.title, 0, 32) .. '...'
			else
				while string.len(value.title) < 35 do
					value.title = value.title .. ' '
				end
			end

			text = value.author .. ' - ' .. value.title .. ' | 👍 ' .. value.approvals2 .. ' | 💬 ' .. value.comments2
			color = { red = 0, blue = 0, green = 0 }
			if value.approvals > 1 and value.state == 'SUCCESSFUL' then
				color = { red = 0, blue = 0.5, green = 1 }
			elseif value.state ~= 'SUCCESSFUL' then
				 color = { red = 1, blue = 0, green = 0 }
			end

			line = { title = hs.styledtext.new(text, { color = color, font = 'Monaco' }), checked = value.approved,
			fn = function(keyPressed)
				local openURL = true
				if keyPressed.cmd then
					openURL = false
				end

				if openURL then
					hs.urlevent.openURL(value.url)
		       	end

	            bbkey = value.url:match( "([^/]+)$" )
	            BBprev[bbkey] = { approvals = value.approvals, comments = value.comments }

	            hs.settings.set('BBprev', BBprev )
	       		doMenu(lines)
			end }


	        table.insert(menu, line)
	        num_prs = num_prs + 1

	        if value.approved then
	        	num_approved = num_approved + 1
	        end
		end

        table.insert(menu, { title = '-' })
        table.insert(menu, { title = 'Last updated at ' .. lastUpdatedAt })

		num_unapproved = num_prs - num_approved

		print(inspect(menu))

		menuItem:setTitle(num_prs .. '|' .. num_unapproved)

		menuItem:setIcon(prIcon)

		menuItem:setMenu(menu)


		print(inspect(lines))
		-- hs.settings.set('menuLines', lines )


	    -- hs.alert.show(testTimerValue)
end


local inspect = require 'inspect'

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
  hs.reload()
end)
hs.alert.show("Config loaded")


require "layout"


--local menubar = require "menubar"
--menubar.init()








hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Down", function()
	-- test1()
	-- test2()
	test3('USERNAME', 'PASSWORD')
end)


local bitbucket = {}

function test3(username, password)
   local url = 'https://bitbucket.org/api/2.0/repositories/REPO_OWNER/REPO_SLUG/pullrequests/'
   local bodyTable = {}
	author_name = '';
	title = '';
	num_approvals = 0;
	approved_by_me = false;
	lines = {}

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

					-- print('----------0')
					-- 	print(author_name)
					-- print(title)
					-- print(num_approvals)
					-- print(approved_by_me)
					-- print(num_comments)
					-- print('----------1')


					local url3 = value.links.statuses.href

					status3, body3, headers3 = hs.http.get(url3, {Authorization = "Basic " .. hs.base64.encode(username .. ":" .. password)})

					if status3 == 200 then
						body3 = hs.json.decode(body3)

						values3 = body3.values[0] or body3.values[1]

						build_state = values3.state

				        line = { approved = approved_by_me, author = author_name, title = title, approvals = num_approvals, comments = num_comments, state = build_state, url = link }  --$(_jq '.num_comments') | href=$(_jq '.link_html') color=$colour"
				        table.insert(lines, line)

					end

				else
					print("bb call2 failed with status code: " .. status)
				end

			end

		else
			print("bb call failed with status code: " .. status)

		end

	    print(inspect(lines))


        doMenu(lines)

	end)

	return bodyTable

end

menuItem = hs.menubar.new()

function doMenu(lines)
	-- if menuItem:isInMenubar() then
	--     menuItem:removeFromMenuBar()
	-- end
	  if menuItem:isInMenubar() then
	    hs.alert.show('Reloading PRs...')
	    menuItem:delete()
	    menuItem = hs.menubar.new()
	  end
	--  hs.menubar:removeFromMenuBar()
	 -- local menuItem = hs.menubar.new()


	-- 		menuItem:setMenu({
	
	--       { title = 'title', fn = ''},
	--       { title = "my menu item", fn = function() print("you clicked my menu item!") end },
	--       { title = "-" },
	--       { title = "other item", fn = some_function },
	--       { title = "disabled item", disabled = true },
	--       { title = hs.styledtext.new("My text", { color = { red = .5, blue = 1, green = 0 }}), checked = true },

	-- })


		menu = {}
		num_prs = 0
		num_approved = 0
		for key, value in pairs(lines) do
			text = value.author .. ' - ' .. value.title .. ' | ' .. value.approvals .. ' | ' .. value.comments
			color = { red = 0, blue = 0, green = 0 }
			if value.approvals > 1 and value.state == 'SUCCESSFUL' then
				color = { red = 0, blue = 0.5, green = 1 }
			elseif value.state ~= 'SUCCESSFUL' then
				 color = { red = 1, blue = 0, green = 0 }
			end

			line = { title = hs.styledtext.new(text, { color = color }), checked = value.approved, fn = function() hs.urlevent.openURL(value.url) end }
	        table.insert(menu, line)
	        num_prs = num_prs + 1

	        if value.approved then
	        	num_approved = num_approved + 1
	        end
		end

		num_unapproved = num_prs - num_approved

		print(inspect(menu))

		menuItem:setTitle('PRs ' .. num_prs .. '|' .. num_unapproved)

		menuItem:setMenu(menu)

end

function test2()

	print(html)
end

function test1()

	local menuItem = hs.menubar.new()
	      hs.alert.show('TESTz!')
	menuItem:setTitle('ITEM' .. 1)
	menuItem:setMenu({
	      {title = 'title', fn = ''},
	      { title = "my menu item", fn = function() print("you clicked my menu item!") end },
	      { title = "-" },
	      { title = "other item", fn = some_function },
	      { title = "disabled item", disabled = true },
	      { title = hs.styledtext.new("My text", { color = { red = .5, blue = 1, green = 0 }}), checked = true },

	})
	--table.insert(gmailBars, gmailBar)
	-- end)

end



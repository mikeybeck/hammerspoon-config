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

   hs.http.asyncGet(url, {Authorization = "Basic " .. hs.base64.encode(username .. ":" .. password)}, function(status, body, headers)
                       if status == 200 then
                          -- local mailCount = string.match(body, "<fullcount>([0-9]*)")
                          -- cb(tonumber(mailCount))
                          print('success')

                          --print(inspect(hs.json.decode(body)))

                          bodyTable = hs.json.decode(body)

                          --print(body)et

				          --print(bodyTable.page)

				          --print(inspect(bodyTable.values))

						  --print(inspect(bodyTable.values[0] or bodyTable.values[1]))

						  values = bodyTable.values[0] or bodyTable.values[1] -- Values is nested; get first value.  This might be the case when there is only one open PR...

						  -- print(inspect(values.author.display_name))

  						  for key, value in pairs(bodyTable.values) do
  							  -- print(inspect(value.author.display_name))
  							  author_name = value.author.display_name
  							  -- print(inspect(value.title))
  							  title = value.title


-- print(inspect(value))

-- print(inspect(value.destination.commit.links.self.href))
local url2 = value.links.self.href
-- print(url2)



  						-- 	status2, body2, headers2 = hs.http.get(url2, {Authorization = "Basic " .. hs.base64.encode(username .. ":" .. password)})
  					 --        if status2 == 200 then
  						-- 	  	body2 = hs.json.decode(body2)
								-- participants = body2.participants
								-- approved_by_me = false
								-- num_approvals = 0

								-- for key2, value2 in pairs(body2.participants) do

								-- 	num_approvals = num_approvals + (value2.approved and 1 or 0)

								-- 	participant_name = value2.user.display_name
								-- 	if participant_name == 'Mike Beck' and value2.approved then
								-- 		approved_by_me = true
								-- 	end
								-- end

								-- print('----------0')
	       --                 			print(author_name)
								-- 	print(title)
								-- 	print(num_approvals)
								-- 	print(approved_by_me)
	 						-- 	print('----------1')

 							-- else
	       --                			print("bb call2 failed with status code: " .. status)

  						-- 	end

local url3 = value.links.statuses.href

  							status3, body3, headers3 = hs.http.get(url3, {Authorization = "Basic " .. hs.base64.encode(username .. ":" .. password)})

 							if status3 == 200 then
  							  	body3 = hs.json.decode(body3)

  							  	values3 = body3.values[0] or body3.values[1]

  							  	print(values3.state)

							end

		                       
  							  

						   end

                       else
                          print("bb call failed with status code: " .. status)
                       end
   end)

   return bodyTable

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



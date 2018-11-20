local gmail = require "gmail"
local menubar = {}

local gmailBars = {}

local apiKey = nil
local credFile = nil
local gmailCreds = {}

function menubar.init()
   if file_exists("gmail_creds.lua") then
      credFile = require "gmail_creds"
      updateGmailBar()
      hs.timer.doEvery(20*60, updateGmailBar)
      hs.alert.show('GmailBar in use!')
   else
      hs.alert.show('GmailBar in use, but no gmail_creds file found!')
   end

end

function nextMinute()
   return (math.floor(hs.timer.localTime() / 60) * 60) + 60
end

function updateGmailBar()
   for index, gmailBar in ipairs(gmailBars) do
      gmailBar:delete()
   end

   gmailBars = {}

  local url = "https://mail.google.com/mail/feed/atom"

   for index, creds in ipairs(credFile) do
      gmail.mailCount(creds.username, creds.password, url, function(count)
                         if count > 0 then
                            local gmailBar = hs.menubar.new()
                            gmailBar:setTitle('📬' .. count)
                            gmailBar:setMenu({
                                  {title = creds.username,
                                   fn = updateGmailBar}})
                            table.insert(gmailBars, gmailBar)
                         end
      end)
   end
end

function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then
      io.close(f)
      return true
   else
      return false
   end
end

return menubar

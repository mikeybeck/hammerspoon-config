-- Bitbucket Pull Requests monitor module for Hammerspoon
-- v0.35

local inspect = require 'inspect' -- This isn't *required* but helps with debugging.  Remove this line if you don't have this file.

-- TODO:
-- Move icons/images to github repo & serve from there
-- Updated x time ago (currently displays 'updated at time').  Not sure if this is really possible...
-- Don't show change indicators for my activity - might not be worthwhile due to extra API calls required

--[[
Note:
Build state currently not functioning; I'm not sure why the BB API isn't returning the status value
Build state isn't too important and requires a API call, so disabled for now
]]
local config = require 'config'

local gmail = require 'gmail'
local credFile = require 'gmail_creds'

local url =
    'https://bitbucket.org/api/2.0/repositories/' ..
    config.bitbucket.repo_owner ..
        '/' .. config.bitbucket.repo_slug .. '/pullrequests/?pagelen=' .. config.bitbucket.max_num_prs

hs.hotkey.bind(
    {'cmd', 'alt', 'ctrl'},
    'Down',
    function()
        getPRs(config.bitbucket.username, config.bitbucket.password)

        refresh(config.bitbucket.username, config.bitbucket.password)
    end
)
hs.hotkey.bind(
    {'cmd', 'alt', 'ctrl'},
    'x',
    function()
        hs.alert.show('Reloading PRs...')

        getPRs(config.bitbucket.username, config.bitbucket.password)
    end
)

local timerValue
local stopped = false

function refresh(username, password)
    timerValue = 0
    refreshTimer =
        hs.timer.doEvery(
        config.bitbucket.refresh_freq,
        function()
            local time = hs.timer.localTime() / 36
            if
                config.bitbucket.auto_refresh and
                    (time < config.bitbucket.work_start or time > config.bitbucket.work_end)
             then
                refreshTimer:stop()
                stopped = true
                print(time)
            elseif timerValue > config.bitbucket.refresh_num then
                refreshTimer:stop()
                stopped = true
            end

            if config.bitbucket.check_emails then
                if newPrEmail() then
                    hs.alert.show('Reloading PRs!!!!...')
                    getPRs(username, password)
                end
            else
                getPRs(username, password)
            end

            timerValue = timerValue + 1
        end
    )
end

function newPrEmail()
    local numPrEmails = hs.settings.get('numPrEmails') or 0
    local url = 'https://mail.google.com/mail/feed/atom/' .. config.bitbucket.gmail_prs_label
    print(numPrEmails)
    for index, creds in ipairs(credFile) do
        gmail.mailCount(
            creds.username,
            creds.password,
            url,
            function(count)
                if count > numPrEmails then
                    hs.settings.set('numPrEmails', count)
                    hs.settings.set('newEmail', true)
                else
                    hs.settings.set('numPrEmails', count)
                    hs.settings.set('newEmail', false)
                end
            end
        )
    end
    return hs.settings.get('newEmail')
end

local lastUpdatedAt = {}

function getURL(url, username, password)
    hs.http.asyncGet(
        url,
        {Authorization = 'Basic ' .. hs.base64.encode(username .. ':' .. password)},
        function(status1, body1, headers1)
            status = status1
            body = body1
            headers = headers1
        end
    )
end

function getPRs(username, password)
    author_name = ''
    title = ''
    num_approvals = 0
    approved_by_me = false
    otherPRs = {}
    myPRs = {}

    menuItem:setTitle('...')

    getURL(url, username, password)

    hs.timer.waitUntil(
        function()
            return status ~= nil
        end,
        function()
            parseBBJson(username, password)

            createMenu()
        end
    )
end

function createMenu()
    -- Get current time for 'last updated at' value
    local hour = os.date('%I')
    if string.sub(hour, 1, 1) == '0' then
        hour = string.sub(hour, 2)
    end

    lastUpdatedAt.time = os.date(hour .. ':%M:%S %p')
    lastUpdatedAt.date = os.date('%x')

    -- Add my PRs to other PRs
    local allPRs = otherPRs
    for i = 1, #myPRs do
        allPRs[#allPRs + 1] = myPRs[i]
    end

    doMenu(allPRs)
    -- end
    -- )
end

function parseBBJson(username, password)
    if status == 200 then
        bodyTable = hs.json.decode(body)

        values = bodyTable.values[0] or bodyTable.values[1]

        for key, value in pairs(bodyTable.values) do
            author_name = value.author.display_name
            title = value.title
            num_comments = value.comment_count
            link = value.links.html.href
            remote_branch = config.bitbucket.remote_branches[value.destination.branch.name]
            if remote_branch == nil then
                remote_branch = config.bitbucket.remote_branches['default']
            end

            last_updated = value.updated_on

            local url2 = value.links.self.href

            status2, body2, headers2 =
                hs.http.get(url2, {Authorization = 'Basic ' .. hs.base64.encode(username .. ':' .. password)})

            if status2 == 200 then
                body2 = hs.json.decode(body2)
                participants = body2.participants
                approved_by_me = false
                num_approvals = 0

                for key2, value2 in pairs(body2.participants) do
                    num_approvals = num_approvals + (value2.approved and 1 or 0)

                    participant_name = value2.user.display_name

                    if participant_name == config.bitbucket.my_name and value2.approved then
                        approved_by_me = true
                    end
                end

                build_state = 'SUCCESSFUL' --values3.state

                line = {
                    approved = approved_by_me,
                    author = author_name,
                    title = title,
                    approvals = num_approvals,
                    comments = num_comments,
                    state = build_state,
                    url = link,
                    branch = remote_branch,
                    updated = last_updated
                }

                if author_name == config.bitbucket.my_name then
                    table.insert(myPRs, line)
                else
                    table.insert(otherPRs, line)
                end
            else
                print('bb call2 failed with status code: ' .. status)
            end
        end
    else
        print('bb call failed with status code: ' .. status)
    end
end

menuItem = hs.menubar.new()

function doMenu(allPRs)
    if menuItem:isInMenubar() then
        menuItem:delete()
        menuItem = hs.menubar.new()
    end

    prIcon =
        hs.image.imageFromURL(
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Octicons-git-pull-request.svg/180px-Octicons-git-pull-request.svg.png'
    )
    commentsIcon =
        hs.image.imageFromURL(
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Octicons-git-pull-request.svg/180px-Octicons-git-pull-request.svg.png'
    )
    size = {h = 23, w = 20}
    prIcon = prIcon:setSize(size)
    commentsIcon = commentsIcon:setSize(size)

    menu = {
        {
            title = 'View all open pull requests',
            fn = function()
                hs.urlevent.openURL(
                    'https://bitbucket.org/' ..
                        config.bitbucket.repo_owner .. '/' .. config.bitbucket.repo_slug .. '/pull-requests/'
                )
            end
        }
    }

    table.insert(menu, {title = '-'})

    num_prs = 0
    num_my_prs = 0
    num_approved = 0
    added_mine = false
    for key, value in pairs(allPRs) do
        if string.gsub(value.author, '%s+', '') == string.gsub(config.bitbucket.my_name, '%s+', '') then
            if not added_mine then
                table.insert(menu, {title = '-'})
                added_mine = true
            end
            num_my_prs = num_my_prs + 1
        end

        BBprev = hs.settings.get('BBprev')
        bbkey = value.url:match('([^/]+)$')

        if BBprev[bbkey] ~= nil then
            value.prev = {
                approvals = BBprev[bbkey].approvals,
                comments = BBprev[bbkey].comments,
                updated = BBprev[bbkey].updated
            }
        else
            value.prev = {approvals = 0, comments = 0, updated = ' - '}
        end

        value.approvals2 = value.approvals .. ' '
        if value.approvals ~= value.prev.approvals then
            value.approvals2 = value.approvals .. '*'
        end

        value.comments2 = value.comments
        value.commentsDiff = ' '
        if value.comments ~= value.prev.comments then
            value.commentsDiff = value.commentsDiff .. (value.comments - value.prev.comments)
        end

        value.updated2 = ' - '
        if value.updated ~= value.prev.updated then
            value.updated2 = ' * '
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

        text =
            value.author ..
            ' ' ..
                value.branch ..
                    value.updated2 .. value.title .. ' | 👍 ' .. value.approvals2 .. ' | 💬 ' .. value.comments2
        color = {red = 0, blue = 0, green = 0}
        if value.approvals > 1 and value.state == 'SUCCESSFUL' then
            color = {red = 0, blue = 0.7, green = 1}
        elseif value.state ~= 'SUCCESSFUL' then
            color = {red = 1, blue = 0, green = 0}
        end

        line = {
            title = hs.styledtext.new(text, {color = color, font = 'Monaco'}) ..
                hs.styledtext.new(
                    value.commentsDiff,
                    {color = color, baselineOffset = 3.0, font = {name = 'Monaco', size = 10}}
                ),
            checked = value.approved,
            fn = function(keyPressed)
                local openURL = true
                if keyPressed.cmd then
                    openURL = false
                end

                if openURL then
                    hs.urlevent.openURL(value.url)
                end

                bbkey = value.url:match('([^/]+)$')
                BBprev[bbkey] = {approvals = value.approvals, comments = value.comments, updated = value.updated}

                hs.settings.set('BBprev', BBprev)
                added_mine = false
                doMenu(allPRs)
            end
        }

        table.insert(menu, line)
        num_prs = num_prs + 1

        if value.approved then
            num_approved = num_approved + 1
        end
    end

    table.insert(menu, {title = '-'})

    if lastUpdatedAt.date ~= os.date('%x') then
        table.insert(menu, {title = 'Last updated on ' .. lastUpdatedAt.date .. ' at ' .. lastUpdatedAt.time})
    else
        table.insert(
            menu,
            {
                title = 'Last updated today at ' .. lastUpdatedAt.time,
                fn = function(keyPressed)
                    if keyPressed.cmd then
                        clearUpdates(allPRs)
                    end
                end
            }
        )
    end

    num_unapproved = num_prs - num_approved - num_my_prs

    menuColour = {red = 0, blue = 0, green = 0}
    if stopped then
        -- PRs no longer being updated automatically
        menuColour = {red = 0.7, blue = 0, green = 0}
    end

    menuItem:setTitle(
        hs.styledtext.new(
            num_unapproved,
            {color = menuColour, superscript = 1, baselineOffset = -3.0, paragraphStyle = {alignment = 'right'}}
        ) ..
            hs.styledtext.new('/', {color = menuColour, superscript = 0, baselineOffset = -1.0}) ..
                hs.styledtext.new(
                    num_prs,
                    {color = menuColour, superscript = -1, paragraphStyle = {alignment = 'left'}}
                )
    )

    menuItem:setIcon(prIcon)

    menuItem:setMenu(menu)
end

function clearUpdates(allPRs)
    BBprev = hs.settings.get('BBprev')

    for key, value in pairs(allPRs) do
        bbkey = value.url:match('([^/]+)$')

        BBprev[bbkey] = {approvals = value.approvals, comments = value.comments, updated = value.updated}

        hs.settings.set('BBprev', BBprev)
        added_mine = false
    end

    doMenu(allPRs)
end

function tableConcat(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

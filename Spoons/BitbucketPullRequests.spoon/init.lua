
-- TODO:
-- Updated x time ago (currently displays 'updated at time').  Not sure if this is really possible...
-- Don't show change indicators for my activity - might not be worthwhile due to extra API calls required
-- More filtering options?
-- Bug: my items get mixed in with the others when sorting
-- Update code to conform to Spoon API conventions: https://github.com/Hammerspoon/hammerspoon/blob/master/SPOONS.md

-- try making menu items a separate global variable in order to make updating single items easier (done - needs tidying up though)
-- reduce number of table copy operations

--[[
Note:
Build state currently not functioning; I'm not sure why the BB API isn't returning the status value
Build state isn't too important and requires a API call, so disabled for now
]]

local obj = {}
obj.__index = obj

-- Internal function used to find our location, so we know where to load files from
local function scriptPath()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end
local spoonPath = scriptPath()

local function includeFile(fileName)
    return dofile(spoonPath .. fileName .. '.lua')
end

local inspect = includeFile('inspect') -- This isn't *required* but helps with debugging.

local config = includeFile('config')

local gmail = includeFile('gmail')
local credFile = includeFile('gmail_creds')

local url =
    'https://bitbucket.org/api/2.0/repositories/' ..
    config.bitbucket.repo_owner ..
        '/' .. config.bitbucket.repo_slug .. '/pullrequests/?pagelen=' .. config.bitbucket.max_num_prs

hyper:bind({},
    'Down',
    function()
        hyper.triggered = true
        getPRs(config.bitbucket.username, config.bitbucket.password)

        refresh(config.bitbucket.username, config.bitbucket.password)

    end
)

hyper:bind({},
    'x',
    function()
        hs.alert.show('Reloading PRs...')

        getPRs(config.bitbucket.username, config.bitbucket.password)
        hyper.triggered = true
    end
)

hyper:bind({},
    'y',
    function()
        hs.alert.show('Reloading PRs2...')

        doMenu()
        hyper.triggered = true
    end
)

-- hyper:bind({},
--     'z',
--     function()
--         hs.alert.show('DOMenu')

--         doMenu()
--         -- hyper.triggered = true
--     end
-- )

-- hyper:bind({},
--     'a',
--     function()
--         hs.alert.show('createmenutable')

--         createMenuTable(allPRs)
--         -- hyper.triggered = true
--     end
-- )

local timerValue
local stopped = false

local menuPRs = table
local menu_copy = table


function refresh(username, password)
    print('refresh()')
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
    print('newPrEmail()')
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
    print('getURL()')
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
    print('getPRs()')
    author_name = ''
    title = ''
    num_approvals = 0
    approved_by_me = false
    otherPRs = {}
    myPRs = {}
    hs.settings.set('filteringBy', nil)
    hs.settings.set('sortingBy', nil)
    filteringBy = hs.settings.get('filteringBy')
    sortingBy = hs.settings.get('sortingBy')

    -- Change menu colour to indicate loading
    menuColour = {red = 0, blue = 1, green = 0}
    doMenu()

    getURL(url, username, password)

    hs.timer.waitUntil(
        function()
            return status ~= nil
        end,
        function()
            parseBBJson(username, password)

            local allPRs = getAllPRs()

            -- if sortingBy then
            --     sort(allPRs, sortingBy, true)
            -- end

            -- if filteringBy then
            --     filterBranches(allPRs, filteringBy)
            -- end

            if filteringBy == nil and sortingBy == nil then
                createMenuTable(allPRs)
                doMenu()
            end
        end
    )
end

function getAllPRs()
    print('getAllPRs()')
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

    return allPRs
end

function parseBBJson(username, password)
    print('parseBBJson()')
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

            created_on = value.created_on

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
                    updated = last_updated,
                    created = created_on
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

function createMenuTable(allPRs)
    print('createMenuTable()')

    prIcon = hs.image.imageFromPath(spoonPath .. '180px-Octicons-git-pull-request.png')

    size = {h = 23, w = 20}
    prIcon = prIcon:setSize(size)

    menu = {
        {
            title = 'View all open pull requests',
            fn = function()
                hs.urlevent.openURL(
                    'https://bitbucket.org/' ..
                        config.bitbucket.repo_owner .. '/' .. config.bitbucket.repo_slug .. '/pull-requests/'
                )
            end
        },
        {
            title = 'Create new pull request',
            fn = function()
                hs.urlevent.openURL(
                    'https://bitbucket.org/' ..
                        config.bitbucket.repo_owner .. '/' .. config.bitbucket.repo_slug .. '/pull-requests/new'
                )
            end
        },
        {
            title = 'Filter branches',
            menu = {
                {
                    title = 'Beta',
                    fn = function()
                        filterBranches(allPRs, 'B')
                    end,
                    checked = filteringBy == 'B',
                    tooltip = 'Show only beta branches'
                },
                {
                    title = 'Production',
                    fn = function()
                        filterBranches(allPRs, 'P')
                    end,
                    checked = filteringBy == 'P',
                    tooltip = 'Show only production branches'
                },
                {
                    title = 'X',
                    fn = function()
                        filterBranches(allPRs, 'X')
                    end,
                    checked = filteringBy == 'X',
                    tooltip = 'Show only default branches (i.e. not beta, production or development)'
                },
                {
                    title = 'All',
                    fn = function()
                        filterBranches(allPRs, 'All')
                    end,
                    checked = filteringBy == 'All',
                    tooltip = 'Show all branches'
                },
                {
                    title = 'New changes (experimental)',
                    fn = function()
                        onlyShowChanged = true
                        filterBranches(allPRs, 'changed')
                    end,
                    checked = filteringBy == 'changed',
                    tooltip = 'Show only branches with unseen changes'
                }
            }
        },
        {
            title = 'Sort by',
            menu = {
                {
                    title = 'Number of comments',
                    fn = function(keyPressed)
                        sort(allPRs, 'comments', keyPressed.cmd)
                    end,
                    checked = sortingBy == 'comments',
                    tooltip = 'Cmd-click to sort in reverse order'
                },
                {
                    title = 'Most recently updated',
                    fn = function(keyPressed)
                        sort(allPRs, 'updated', keyPressed.cmd)
                    end,
                    checked = sortingBy == 'updated',
                    tooltip = 'Cmd-click to sort in reverse order'
                },
                {
                    title = 'Most recently created',
                    fn = function(keyPressed)
                        sort(allPRs, 'created', keyPressed.cmd)
                    end,
                    checked = sortingBy == 'created',
                    tooltip = 'Cmd-click to sort in reverse order'
                }
            }
        }
    }

    table.insert(menu, {title = '-'})

    addPRsToMenu(allPRs)

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

    -- Automatic update mode on
    menuColour = {red = 0, blue = 0, green = 0}
    if stopped then
        -- Automatic update mode off
        menuColour = {red = 0.7, blue = 0, green = 0}
    end
end


function addPRsToMenu(allPRs)
    print('addPRsToMenu()')
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

        -- Add '*' to indicate a change in number of approvals
        value.approvals2 = value.approvals .. ' '
        if value.approvals ~= value.prev.approvals then
            value.approvals2 = value.approvals .. '*'
            changed = true
        end

        -- Add superscript number to show number of unseen comments
        value.comments2 = value.comments
        value.commentsDiff = ' '
        if value.comments ~= value.prev.comments then
            value.commentsDiff = value.commentsDiff .. (value.comments - value.prev.comments)
            changed = true
        end

        -- Add '*' to indicate that this PR has been updated
        value.updated2 = ' - '
        if value.updated ~= value.prev.updated then
            value.updated2 = ' * '
            changed = true
        end

        -- If author name is too long, get first initial and all of last name
        if string.len(value.author) > 15 then
            value.author = string.sub(value.author, 1, 1) .. string.match(value.author, '( .*)')
        end

        -- Make all author name 'columns' the same length
        while string.len(value.author) < 15 do
            value.author = value.author .. ' '
        end

        -- Make all title 'columns' the same length
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
                -- createMenuTable(allPRs) -- Would be better to just update this single item in the table
                -- second param = update (optional).  Not yet implemented
                -- createMenuTable(allPRs, value.url) -- Would be better to just update this single item in the table
                updateMenuItem = {approvals = value.approvals, comments = value.comments, updated = value.updated,
                            author = value.author, branch = value.branch, title = value.title}
                updatePR(updateMenuItem, value.url)

                -- doMenu()
            end,
            tooltip = 'Created: ' .. parseDate(value.created) .. '.\nUpdated: ' .. parseDate(value.updated),
            url = value.url
        }

        if onlyShowChanged == nil or (onlyShowChanged ~= nil and changed == true) then
            table.insert(menu, line)
            table.insert(menuPRs, line)
            num_prs = num_prs + 1
        end

        changed = false

        if value.approved then
            num_approved = num_approved + 1
        end
    end
end

function getTitleText(value)
    print('getTitleText()')
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

        title = hs.styledtext.new(text, {color = color, font = 'Monaco'}) ..
        hs.styledtext.new(
            value.commentsDiff,
            {color = color, baselineOffset = 3.0, font = {name = 'Monaco', size = 10}}
        )

        return title
end

-- Update single PR in menu
function updatePR(menuItem, url)
    print('updatePR()')

    -- Get menu item that matches and update it
    for k, v in pairs(menu) do
        if type(v) == 'table' and v.url == url then
            x = menu[k]
            menu[k] = nil
            menu[k] = x
            v.comments2 = menuItem.comments
            v.approvals2 = menuItem.approvals .. ' '
            v.approvals = menuItem.approvals
            v.author = menuItem.author
            v.branch = menuItem.branch
            v.updated2 = ' - '
            v.commentsDiff = ''
            v.title = menuItem.title
            v.state = 'SUCCESSFUL'
            menu[k].title = getTitleText(v)
        end
    end

    doMenu()
end

function doMenu()
    print('doMenu()')
    if num_unapproved == nil then
        menuItem:setTitle('...')
    else
        menuItem:setTitle(
            hs.styledtext.new(
                num_unapproved,
                {color = menuColour, superscript = 1, baselineOffset = -7, paragraphStyle = {alignment = 'right'}}
            ) ..
                hs.styledtext.new('/', {color = menuColour, superscript = 0, baselineOffset = 0}) ..
                    hs.styledtext.new(
                        num_prs,
                        {color = menuColour, superscript = -1, baselineOffset = 5, paragraphStyle = {alignment = 'left'}}
                    )
        )
    end

    menuItem:setIcon(prIcon)

    -- print(inspect(menu))

    menuItem:setMenu(menu)
end

function clearUpdates(allPRs)
    print('clearUpdates()')
    BBprev = hs.settings.get('BBprev')

    for key, value in pairs(allPRs) do
        bbkey = value.url:match('([^/]+)$')

        BBprev[bbkey] = {approvals = value.approvals, comments = value.comments, updated = value.updated}

        hs.settings.set('BBprev', BBprev)
        added_mine = false
    end

    createMenuTable(allPRs)
    doMenu()
end

function filterBranches(allPRs, branch)
    print('filterBranches()')
    if allPRsCopy == nil then
        allPRsCopy = table.copy(allPRs)
    else
        allPRs = table.copy(allPRsCopy)
    end

    if branch ~= 'All' and branch ~= 'changed' then
        for key, value in pairs(allPRs) do
            if value.branch ~= branch then
                allPRs[key] = nil
            end
        end
    end

    filteringBy = branch
    hs.settings.set('filteringBy', branch)
    createMenuTable(allPRs)
    doMenu()
    onlyShowChanged = nil
end

function sort(allPRs2, sortBy, reverse)
    print('sort()')
    local allPRs = allPRs2
    if reverse then
        table.sort(
            allPRs,
            function(left, right)
                return left[sortBy] > right[sortBy]
            end
        )
    else
        table.sort(
            allPRs,
            function(left, right)
                return left[sortBy] < right[sortBy]
            end
        )
    end

    sortingBy = sortBy
    hs.settings.set('sortingBy', sortBy)
    createMenuTable(allPRs)
    doMenu()
end

function tableConcat(t1, t2)
    print('tableConcat()')
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

function tablelength(T)
    print('tablelength()')
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

function table.copy(t)
    print('table.copy()')
    local t2 = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then
            t2[k] = table.copy(v)
        else
            t2[k] = v
        end
    end
    return t2
end

function parseDate(date)
    print('parseDate()')
    -- Assume format is RFC3339 (YYYY-MM-DD[T]HH:MM:SS[Z])
    day = date:sub(9, 10)
    month = date:sub(6, 7)
    year = date:sub(1, 4)
    hour = date:sub(12, 13)
    minute = date:sub(15, 16)

    return day .. '/' .. month .. '/' .. year .. ' at ' .. hour .. ':' .. minute
end

return obj

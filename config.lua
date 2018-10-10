local _M = {}

_M.bitbucket = {
    username = '',
    password = '',
    repo_owner = '',
    repo_slug = '',
    my_name = '', -- My Bitbucket name
    refresh_freq = 120, -- How frequently to refresh the menu, in seconds
    refresh_num = 300, -- How many times to refresh before stopping
    auto_refresh = true, -- Whether to keep refreshing during work hours
    work_start = 0800, -- Work start time in 24 hour format
    work_end = 1900, -- Work end time in 24 hour format
    remote_branches = {
        beta = 'B',
        development = 'D',
        master = 'M',
        production = 'P',
        default = 'X' -- Used when none of the other branches match
    },
    check_emails = true,
    gmail_prs_label = 'work-bitbucket',
    max_num_prs = 20 -- maximum number of PRs to fetch
}

return _M

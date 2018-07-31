# hammerspoon-config
My Hammerspoon config

Includes layout.lua which enables a few layout modification hotkeys

and init.lua which contains mostly testing stuff - in particular a Bitbucket pull request checker for the menu bar.  This replicates and improves upon the functionality of my Bitbar plugin https://github.com/mikeybeck/bitbar-bitbucketPRs (which I have no plans to develop further at this stage).

## How to use the Bitbucket Pull Requests module:

- Add your Bitbucket credentials, repo owner name and repo slug to the config.lua file
- Press cmd-opt-ctrl + Down to load the pull requests menu, which will auto-refresh every 5 mins for an hour
- Press cmd-opt-ctrl + X to reload the pull requests menu once
- Click on a PR in the menu to open the PR URL in your browser.  Any change indicators will be removed
- Hold cmd while clicking a PR in the menu to remove any change indicators without opening it in the browser

### Bitbucket Pull Requests Module Changelog:

- 0.4: Add gmail tag checking option - PRs are updated when a new email with specified tag received
- 0.35: Add ability to auto refresh during work hours (can set hours but not days)
- 0.341: Add default branch indicator
- 0.34: Add PR update indicator (- is replaced with *)
- 0.33: Add remote branch indicator
- 0.321: Fix bug which causes my PRs to be added to the rest when clicking on the menu,
         Fix bug which only removes one of my PRs from the unapproved list
- 0.32: Exclude own PRs from number unapproved
- 0.311: Some refactoring,
        reverse num_prs and unapproved_prs,
        add my_name, refresh_freq and refresh_num to config file,
        remove hard coded repo details
- 0.301: Fix not-updating colour bug
- 0.3: Move my PRs to the bottom of the menu and separate them from the rest
- 0.231: Fix - Actually make numbers red when no longer auto-updating
- 0.23: Make menu numbers red when no longer auto-updating
- 0.22: Actually fix auto refresh this time
- 0.21: Fix auto refresh stop
- 0.2: Fix auto refresh so it actually works
- 0.12: Add 'updated at' date
- 0.11: Add 'updated at' time
- 0.1: Initial beta release

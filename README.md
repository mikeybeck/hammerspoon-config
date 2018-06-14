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

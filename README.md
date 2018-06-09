# hammerspoon-config
My Hammerspoon config

Includes layout.lua which enables a few layout modification hotkeys

and init.lua which contains mostly testing stuff - in particular a Bitbucket pull request checker for the menu bar.  I hope to replicate my Bitbar plugin https://github.com/mikeybeck/bitbar-bitbucketPRs

## How to use the Bitbucket Pull Requests module:

- Add your Bitbucket credentials, repo owner name and repo slug to the config.lua file
- Press cmd-opt-ctrl + Down to load the pull requests menu, which will auto-refresh periodically
- Press cmd-opt-ctrl + X to reload the pull requests menu once
- Click on a PR in the menu to open the PR URL in your browser.  Any change indicators will be removed
- Hold cmd while clicking a PR in the menu to remove any change indicators without opening it in the browser

### Bitbucket Pull Requests Module Changelog:

- 0.11: Add 'updated at' time
- 0.1: Initial beta release

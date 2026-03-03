<#
#######################################################################################################################################
.SYNOPSIS
    An interactive PowerShell script to simplify a full Git workflow, from initialization to advanced operations.
.DESCRIPTION
    This script provides a user-friendly menu to perform tasks like initializing a repo, checking status,
    committing files/folders, pushing, pulling, cloning, switching branches, managing remotes, and more.
    It includes colored output for clarity and confirmation prompts for critical actions, plus:
    - Explanation blocks for each action
    - Command recaps after each action
    - GitHub CLI Pull Request management
.AUTHOR
    kossi.eglo@stackit.cloud
.DATE
    July 31, 2025 — Updated March 3, 2026 (v5: explanations, command recap, PR management)
#######################################################################################################################################
#>

# --- Helper Functions ---

function Show-Header {
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "          Interactive Git Assistant                             " -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
}

function Show-CommandRecap ($commandsUsed) {
    if ($commandsUsed.Count -gt 0) {
        Write-Host ""
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor DarkGreen
        Write-Host "  Commands used:" -ForegroundColor White
        foreach ($cmd in $commandsUsed) { Write-Host "  > $cmd" -ForegroundColor Yellow }
        Write-Host "================================================================" -ForegroundColor DarkGreen
    }
}

function Check-Remote {
    $commandsUsed = @()
    $remoteOutput = git remote -v 2>&1
    if ($LASTEXITCODE -ne 0 -or -not ($remoteOutput -match "origin")) {
        Write-Host "!! This action requires a remote 'origin' repository, which is not set." -ForegroundColor Yellow
        $confirm = Read-Host "--> Do you want to set one now? (y/n)"
        if ($confirm -eq 'y') {
            $remoteUrl = Read-Host "--> Enter the remote repository URL"
            if ($remoteUrl) {
                git remote add origin $remoteUrl
                $commandsUsed += "git remote add origin $remoteUrl"
                Write-Host "--> Remote 'origin' has been set." -ForegroundColor Green
                Show-CommandRecap $commandsUsed
                return $true
            } else {
                Write-Host "!! Remote URL cannot be empty." -ForegroundColor Red
                Show-CommandRecap $commandsUsed
                return $false
            }
        } else {
            Write-Host "!! Action canceled. A remote is required." -ForegroundColor Red
            Show-CommandRecap $commandsUsed
            return $false
        }
    }
    return $true
}

# --- Branch Sub-Menu ---
function Handle-PullRequestMenu {
    $prChoice = ""
    while ($true) {
        $commandsUsed = @()
        if ([string]::IsNullOrWhiteSpace($prChoice)) {
            Clear-Host; Show-Header

            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                      gh pr                                   ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Create, list, view, and merge Pull Requests on GitHub." -ForegroundColor Cyan
            Write-Host "  When to use  : When you want to propose changes for review before merging to main." -ForegroundColor Cyan
            Write-Host "  Requires     : GitHub CLI (gh) — install from https://cli.github.com" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • PRs allow code review before merging." -ForegroundColor DarkGray
            Write-Host "  • Always create from a feature branch, never from main." -ForegroundColor DarkGray
            Write-Host "  • Authenticate with 'gh auth login' first." -ForegroundColor DarkGray
            Write-Host ""

            Write-Host "--- Pull Request Management (GitHub CLI) ---" -ForegroundColor Green
            Write-Host "a. Create a Pull Request"
            Write-Host "b. List open Pull Requests"
            Write-Host "c. View a Pull Request"
            Write-Host "d. Merge a Pull Request"
            Write-Host "e. Check out a PR locally"
            Write-Host "f. Return to main menu"
            Write-Host "--------------------------------------------" -ForegroundColor Green
            Write-Host "--> Choose a PR option: " -ForegroundColor Yellow -NoNewline
            $prChoice = Read-Host
        }

        # Check if gh CLI is installed
        if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
            Write-Host "!! GitHub CLI (gh) is not installed." -ForegroundColor Red
            Write-Host "!! Please install it from https://cli.github.com to use this feature." -ForegroundColor White
            Write-Host "!! Returning to main menu." -ForegroundColor DarkGray
            Show-CommandRecap $commandsUsed
            return
        }

        switch ($prChoice) {
            'a' {
                Write-Host ""
                Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
                Write-Host "║                    gh pr create                              ║" -ForegroundColor Green
                Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
                Write-Host "  What it does : Creates a new Pull Request on GitHub." -ForegroundColor Cyan
                Write-Host "  When to use  : When you're ready to propose changes from your current branch for review." -ForegroundColor Cyan
                Write-Host "  Safe?        : Yes — creates a PR, doesn't directly modify code on remote." -ForegroundColor Cyan
                Write-Host ""
                Write-Host "  Hints:" -ForegroundColor White
                Write-Host "  • Ensure your branch is pushed before creating a PR." -ForegroundColor DarkGray
                Write-Host "  • Good titles are concise and informative." -ForegroundColor DarkGray
                Write-Host "  • Good bodies explain *why* the changes are needed." -ForegroundColor DarkGray
                Write-Host "  • Use --draft for PRs that are still work-in-progress." -ForegroundColor DarkGray
                Write-Host ""

                $title = Read-Host "--> PR Title"
                $body = Read-Host "--> PR Body (optional, press Enter to skip)"
                $baseBranch = Read-Host "--> Base branch (e.g., main, master, production - default: main)"
                if ([string]::IsNullOrWhiteSpace($baseBranch)) { $baseBranch = "main" }

                if ($title) {
                    gh pr create --title "$title" --body "$body" --base $baseBranch
                    $commandsUsed += "gh pr create --title '$title' --body '$body' --base $baseBranch"
                } else {
                    Write-Host "!! PR Title is required." -ForegroundColor Red
                }
            }
            'b' {
                Write-Host ""
                Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
                Write-Host "║                       gh pr list                             ║" -ForegroundColor Green
                Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
                Write-Host "  What it does : Lists active Pull Requests in the repository." -ForegroundColor Cyan
                Write-Host "  When to use  : To get an overview of ongoing work and reviews." -ForegroundColor Cyan
                Write-Host "  Safe?        : Yes — read-only." -ForegroundColor Cyan
                Write-Host ""
                Write-Host "  Hints:" -ForegroundColor White
                Write-Host "  • Shows open PRs by default." -ForegroundColor DarkGray
                Write-Host "  • Use '--state all' or '--state closed' to see others." -ForegroundColor DarkGray
                Write-Host "  • Filter by author or assignee for specific PRs." -ForegroundColor DarkGray
                Write-Host ""
                gh pr list
                $commandsUsed += "gh pr list"
            }
            'c' {
                Write-Host ""
                Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
                Write-Host "║                       gh pr view                             ║" -ForegroundColor Green
                Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
                Write-Host "  What it does : Displays details of a specific Pull Request." -ForegroundColor Cyan
                Write-Host "  When to use  : To inspect a PR's changes, comments, and status." -ForegroundColor Cyan
                Write-Host "  Safe?        : Yes — read-only." -ForegroundColor Cyan
                Write-Host ""
                Write-Host "  Hints:" -ForegroundColor White
                Write-Host "  • Use the PR number from 'gh pr list'." -ForegroundColor DarkGray
                Write-Host "  • Shows title, body, commits, and files changed." -ForegroundColor DarkGray
                Write-Host "  • Can include web link to open in browser." -ForegroundColor DarkGray
                Write-Host ""
                $prNumber = Read-Host "--> Pull Request number"
                if ($prNumber) {
                    gh pr view $prNumber
                    $commandsUsed += "gh pr view $prNumber"
                } else {
                    Write-Host "!! PR number is required." -ForegroundColor Red
                }
            }
            'd' {
                Write-Host ""
                Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
                Write-Host "║                       gh pr merge                            ║" -ForegroundColor Green
                Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
                Write-Host "  What it does : Merges a Pull Request into its base branch." -ForegroundColor Cyan
                Write-Host "  When to use  : When a PR has been approved and is ready to be integrated." -ForegroundColor Cyan
                Write-Host "  Safe?        : CAREFUL — permanently alters repository history." -ForegroundColor Red
                Write-Host ""
                Write-Host "  Hints:" -ForegroundColor White
                Write-Host "  • Ensure all checks pass and PR is approved before merging." -ForegroundColor DarkGray
                Write-Host "  • Choose merge, squash, or rebase depending on workflow." -ForegroundColor DarkGray
                Write-Host "  • Merge conflicts need to be resolved before merging." -ForegroundColor DarkGray
                Write-Host ""
                $prNumber = Read-Host "--> Pull Request number to merge"
                if ($prNumber) {
                    Write-Host "  Merge methods:" -ForegroundColor Yellow
                    Write-Host "  1. Merge commit (--merge): Keeps all commit history from the PR branch."
                    Write-Host "  2. Squash merge (--squash): Combines all PR commits into one new commit on base."
                    Write-Host "  3. Rebase merge (--rebase): Reapplies PR commits individually on top of base history."
                    $mergeMethod = Read-Host "--> Choose merge method (1, 2, or 3 - default: 1)"
                    $mergeOption = switch ($mergeMethod) {
                        '2' { "--squash" }
                        '3' { "--rebase" }
                        default { "--merge" }
                    }
                    $confirm = Read-Host "--> CONFIRM: Merge PR #$prNumber using $mergeOption? (y/n)"
                    if ($confirm -eq 'y') {
                        gh pr merge $prNumber $mergeOption
                        $commandsUsed += "gh pr merge $prNumber $mergeOption"
                    } else {
                        Write-Host "--> Merge canceled." -ForegroundColor DarkGray
                    }
                } else {
                    Write-Host "!! PR number is required." -ForegroundColor Red
                }
            }
            'e' {
                Write-Host ""
                Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
                Write-Host "║                     gh pr checkout                             ║" -ForegroundColor Green
                Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
                Write-Host "  What it does : Fetches a Pull Request's branch and checks it out locally." -ForegroundColor Cyan
                Write-Host "  When to use  : To test a PR's changes on your local machine before merging." -ForegroundColor Cyan
                Write-Host "  Safe?        : Yes — creates a local branch, doesn't modify remote." -ForegroundColor Cyan
                Write-Host ""
                Write-Host "  Hints:" -ForegroundColor White
                Write-Host "  • Allows you to run local tests or manually review code." -ForegroundColor DarkGray
                Write-Host "  • Creates a new local branch named after the PR." -ForegroundColor DarkGray
                Write-Host "  • Use 'git switch main' to return to your main branch afterward." -ForegroundColor DarkGray
                Write-Host ""
                $prNumber = Read-Host "--> Pull Request number to checkout"
                if ($prNumber) {
                    gh pr checkout $prNumber
                    $commandsUsed += "gh pr checkout $prNumber"
                } else {
                    Write-Host "!! PR number is required." -ForegroundColor Red
                }
            }
            'f' {
                Write-Host "--> Returning to main menu..."
                Show-CommandRecap $commandsUsed
                return
            }
            default { Write-Host "`n!! Invalid PR option: '$prChoice'. Please try again." -ForegroundColor Red }
        }
        Show-CommandRecap $commandsUsed
        Write-Host "`n================================================================" -ForegroundColor Green
        Write-Host "Enter next PR option (a-f) or press [Enter] for menu: " -ForegroundColor Yellow -NoNewline
        $prChoice = Read-Host
    }
}

function Handle-BranchMenu {
    $branchChoice = ""
    while ($true) {
        $commandsUsed = @()
        if ([string]::IsNullOrWhiteSpace($branchChoice)) {
            Clear-Host; Show-Header
            Write-Host "--- Branch Management ---" -ForegroundColor Green
            Write-Host "1. List All Branches"
            Write-Host "2. Create and Switch to New Branch"
            Write-Host "3. Switch to Existing Branch"
            Write-Host "4. Delete a Local Branch"
            Write-Host "5. Delete a Remote Branch"
            Write-Host "6. Rename Current Branch"
            Write-Host "7. Set Upstream Tracking Branch"
            Write-Host "8. Return to Main Menu"
            Write-Host "-----------------------" -ForegroundColor Green
            Write-Host "--> Choose a branch option: " -ForegroundColor Yellow -NoNewline
            $branchChoice = Read-Host
        }
        switch ($branchChoice) {
            '1' {
                Write-Host ""
                Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
                Write-Host "║                       git branch -a                          ║" -ForegroundColor Green
                Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
                Write-Host "  What it does : Lists all local and remote branches in your repository." -ForegroundColor Cyan
                Write-Host "  When to use  : To see available branches and your current location." -ForegroundColor Cyan
                Write-Host "  Safe?        : Yes — read-only, no changes are made." -ForegroundColor Cyan
                Write-Host ""
                Write-Host "  Hints:" -ForegroundColor White
                Write-Host "  • Local branches are shown without 'remotes/origin/'." -ForegroundColor DarkGray
                Write-Host "  • The current branch has an asterisk (*) next to it." -ForegroundColor DarkGray
                Write-Host "  • Remote branches are prefixed with 'remotes/origin/'." -ForegroundColor DarkGray
                Write-Host "  • Use 'git branch --all' (or '-a') to see both local and remote." -ForegroundColor DarkGray
                Write-Host ""
                git branch -a
                $commandsUsed += "git branch -a"
            }
            '2' {
                Write-Host ""
                Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
                Write-Host "║                    git checkout -b                           ║" -ForegroundColor Green
                Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
                Write-Host "  What it does : Creates a new branch and immediately switches to it." -ForegroundColor Cyan
                Write-Host "  When to use  : Starting work on a new feature, bug fix, or experiment." -ForegroundColor Cyan
                Write-Host "  Safe?        : Yes — doesn't affect other branches or remote." -ForegroundColor Cyan
                Write-Host ""
                Write-Host "  Hints:" -ForegroundColor White
                Write-Host "  • Branch names should be descriptive (e.g., feature/login-page)." -ForegroundColor DarkGray
                Write-Host "  • Best practice: create branches from an up-to-date 'main' or 'master'." -ForegroundColor DarkGray
                Write-Host "  • Your current working directory changes to the new branch." -ForegroundColor DarkGray
                Write-Host ""
                $nb = Read-Host "--> New branch name"
                if ($nb) {
                    git checkout -b $nb
                    $commandsUsed += "git checkout -b $nb"
                } else { Write-Host "!! Name required." -ForegroundColor Red }
            }
            '3' {
                Write-Host ""
                Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
                Write-Host "║                     git checkout / switch                    ║" -ForegroundColor Green
                Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
                Write-Host "  What it does : Switches your working directory to an existing branch." -ForegroundColor Cyan
                Write-Host "  When to use  : To work on an existing feature, review code, or prepare a merge." -ForegroundColor Cyan
                Write-Host "  Safe?        : Yes — provided your current changes are committed or stashed." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "  Hints:" -ForegroundColor White
                Write-Host "  • Always commit or stash your changes before switching branches." -ForegroundColor DarkGray
                Write-Host "  • You can use 'git switch <branch-name>' for newer Git versions." -ForegroundColor DarkGray
                Write-Host "  • Switching branches updates your files to that branch's state." -ForegroundColor DarkGray
                Write-Host ""
                Write-Host "--> Local branches:"; git branch
                $sb = Read-Host "--> Switch to branch"
                if ($sb) {
                    git checkout $sb
                    $commandsUsed += "git checkout $sb"
                } else { Write-Host "!! Name required." -ForegroundColor Red }
            }
            '4' {
                Write-Host ""
                Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
                Write-Host "║                       git branch -d                          ║" -ForegroundColor Green
                Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
                Write-Host "  What it does : Deletes a local branch from your repository." -ForegroundColor Cyan
                Write-Host "  When to use  : After a feature branch has been merged and is no longer needed." -ForegroundColor Cyan
                Write-Host "  Safe?        : Yes, if merged. Use -D to force delete unmerged work (careful!)." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "  Hints:" -ForegroundColor White
                Write-Host "  • Can only delete branches that are fully merged into another branch." -ForegroundColor DarkGray
                Write-Host "  • Use 'git branch -D' (capital D) to force delete, even if unmerged." -ForegroundColor DarkGray
                Write-Host "  • Deleting a local branch does not affect the remote branch." -ForegroundColor DarkGray
                Write-Host ""
                Write-Host "--> Local branches:"; git branch
                $db = Read-Host "--> Branch to delete"
                if ($db) {
                    $c = Read-Host "--> Delete '$db'? (y/n)"
                    if ($c -eq 'y') {
                        git branch -d $db
                        $commandsUsed += "git branch -d $db"
                        if ($LASTEXITCODE -ne 0) {
                            $force = Read-Host "--> Not fully merged. Force delete? (y/n)"
                            if ($force -eq 'y') {
                                git branch -D $db
                                $commandsUsed += "git branch -D $db"
                            }
                        }
                    }
                } else { Write-Host "!! Name required." -ForegroundColor Red }
            }
            '5' {
                Write-Host ""
                Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
                Write-Host "║                    git push origin --delete                  ║" -ForegroundColor Green
                Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
                Write-Host "  What it does : Deletes a branch from the remote repository." -ForegroundColor Cyan
                Write-Host "  When to use  : After a remote feature branch has been merged and is no longer needed." -ForegroundColor Cyan
                Write-Host "  Safe?        : CAREFUL — permanently removes the branch from the remote." -ForegroundColor Red
                Write-Host ""
                Write-Host "  Hints:" -ForegroundColor White
                Write-Host "  • This is a destructive action; ensure the branch is truly unneeded." -ForegroundColor DarkGray
                Write-Host "  • Always delete the local branch first for consistency." -ForegroundColor DarkGray
                Write-Host "  • Confirm with teammates if it's a shared branch." -ForegroundColor DarkGray
                Write-Host ""
                if (Check-Remote) {
                    Write-Host "--> Remote branches:"; git branch -r
                    $rb = Read-Host "--> Remote branch to delete (without 'origin/' prefix)"
                    if ($rb) {
                        $c = Read-Host "--> Delete 'origin/$rb' from remote? (y/n)"
                        if ($c -eq 'y') {
                            git push origin --delete $rb
                            $commandsUsed += "git push origin --delete $rb"
                            Write-Host "--> Remote branch '$rb' deleted." -ForegroundColor Green
                        } else {
                            Write-Host "--> Remote branch deletion canceled." -ForegroundColor DarkGray
                        }
                    } else { Write-Host "!! Name required." -ForegroundColor Red }
                }
            }
            '6' {
                Write-Host ""
                Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
                Write-Host "║                       git branch -m                          ║" -ForegroundColor Green
                Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
                Write-Host "  What it does : Renames your current local branch." -ForegroundColor Cyan
                Write-Host "  When to use  : To correct a typo, or update a branch name for clarity." -ForegroundColor Cyan
                Write-Host "  Safe?        : Yes — only affects your local branch name." -ForegroundColor Cyan
                Write-Host ""
                Write-Host "  Hints:" -ForegroundColor White
                Write-Host "  • Does not rename the remote branch; you'll need to push the new name." -ForegroundColor DarkGray
                Write-Host "  • Make sure you're on the branch you want to rename." -ForegroundColor DarkGray
                Write-Host "  • Consider communicating branch name changes to teammates." -ForegroundColor DarkGray
                Write-Host ""
                $current = git branch --show-current
                Write-Host "--> Current branch: $current" -ForegroundColor Cyan
                $newName = Read-Host "--> New name for current branch"
                if ($newName) {
                    git branch -m $newName
                    $commandsUsed += "git branch -m $newName"
                    Write-Host "--> Branch renamed to '$newName'." -ForegroundColor Green
                } else { Write-Host "!! Name required." -ForegroundColor Red }
            }
            '7' {
                Write-Host ""
                Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
                Write-Host "║                    git branch --set-upstream-to              ║" -ForegroundColor Green
                Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
                Write-Host "  What it does : Configures your local branch to track a remote branch." -ForegroundColor Cyan
                Write-Host "  When to use  : For new local branches or if tracking gets out of sync." -ForegroundColor Cyan
                Write-Host "  Safe?        : Yes — only configures tracking, no code changes." -ForegroundColor Cyan
                Write-Host ""
                Write-Host "  Hints:" -ForegroundColor White
                Write-Host "  • Essential for 'git pull' and 'git push' to know where to sync." -ForegroundColor DarkGray
                Write-Host "  • Typically done automatically on the first 'git push -u'." -ForegroundColor DarkGray
                Write-Host "  • Command format: 'git branch --set-upstream-to=origin/main local-branch'." -ForegroundColor DarkGray
                Write-Host ""
                $current  = git branch --show-current
                $upstream = Read-Host "--> Upstream to track (e.g. origin/main)"
                if ($upstream) {
                    git branch --set-upstream-to=$upstream $current
                    $commandsUsed += "git branch --set-upstream-to=$upstream $current"
                    Write-Host "--> '$current' now tracks '$upstream'." -ForegroundColor Green
                } else { Write-Host "!! Upstream required." -ForegroundColor Red }
            }
            '8' {
                Write-Host "--> Returning to main menu..."
                Show-CommandRecap $commandsUsed
                return
            }
            default { Write-Host "`n!! Invalid branch option: '$branchChoice'. Please try again." -ForegroundColor Red }
        }
        Show-CommandRecap $commandsUsed
        Write-Host "`n================================================================" -ForegroundColor Green
        Write-Host "Enter next branch option (1-8) or press [Enter] for menu: " -ForegroundColor Yellow -NoNewline
        $branchChoice = Read-Host
    }
}

# --- Remote Management Sub-Menu ---
function Handle-RemoteMenu {
    $remoteChoice = ""
    while ($true) {
        $commandsUsed = @()
        if ([string]::IsNullOrWhiteSpace($remoteChoice)) {
            Clear-Host; Show-Header

            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                       git remote                             ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Manages connections to your remote repositories." -ForegroundColor Cyan
            Write-Host "  When to use  : For linking your local repo to GitHub/GitLab, or changing URLs." -ForegroundColor Cyan
            Write-Host "  Safe?        : Most operations are safe, deleting/changing URLs requires care." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • 'origin' is the default name for your primary remote." -ForegroundColor DarkGray
            Write-Host "  • You can have multiple remotes (e.g., 'origin' for your fork, 'upstream' for main repo)." -ForegroundColor DarkGray
            Write-Host "  • Check 'git remote -v' to see current remotes and their URLs." -ForegroundColor DarkGray
            Write-Host ""

            Write-Host "--- Remote Management ---" -ForegroundColor Green
            Write-Host "Current remotes:" -ForegroundColor DarkGray
            git remote -v | Out-Host
            Write-Host ""
            Write-Host "1. Add a Remote"
            Write-Host "2. Change Remote URL"
            Write-Host "3. Remove a Remote"
            Write-Host "4. Show Remote Details"
            Write-Host "5. Return to Main Menu"
            Write-Host "-----------------------" -ForegroundColor Green
            Write-Host "--> Choose a remote option: " -ForegroundColor Yellow -NoNewline
            $remoteChoice = Read-Host
        }
        switch ($remoteChoice) {
            '1' {
                Write-Host ""
                Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
                Write-Host "║                    git remote add                            ║" -ForegroundColor Green
                Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
                Write-Host "  What it does : Links your local repository to a new remote repository." -ForegroundColor Cyan
                Write-Host "  When to use  : When setting up a connection to GitHub/GitLab for the first time." -ForegroundColor Cyan
                Write-Host "  Safe?        : Yes — establishes a connection, doesn't change code." -ForegroundColor Cyan
                Write-Host ""
                Write-Host "  Hints:" -ForegroundColor White
                Write-Host "  • Give it a meaningful name (e.g., 'origin' for your copy, 'upstream' for original)." -ForegroundColor DarkGray
                Write-Host "  • Use the HTTPS or SSH URL provided by your Git host." -ForegroundColor DarkGray
                Write-Host "  • After adding, you can 'git push -u <remote-name> <branch-name>'." -ForegroundColor DarkGray
                Write-Host ""
                $name = Read-Host "--> Remote name (e.g. origin)"
                $url  = Read-Host "--> Remote URL"
                if ($name -and $url) {
                    git remote add $name $url
                    $commandsUsed += "git remote add $name $url"
                    Write-Host "--> Remote '$name' added." -ForegroundColor Green
                } else { Write-Host "!! Name and URL required." -ForegroundColor Red }
            }
            '2' {
                Write-Host ""
                Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
                Write-Host "║                  git remote set-url                          ║" -ForegroundColor Green
                Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
                Write-Host "  What it does : Changes the URL of an existing remote connection." -ForegroundColor Cyan
                Write-Host "  When to use  : If the remote repository's location has changed." -ForegroundColor Cyan
                Write-Host "  Safe?        : Yes, but ensure the new URL is correct." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "  Hints:" -ForegroundColor White
                Write-Host "  • Useful when a repository is migrated to a new server or owner." -ForegroundColor DarkGray
                Write-Host "  • Verify the new URL to avoid push/pull errors later." -ForegroundColor DarkGray
                Write-Host "  • Can change both fetch and push URLs or just one specific." -ForegroundColor DarkGray
                Write-Host ""
                git remote -v | Out-Host; Write-Host ""
                $name = Read-Host "--> Remote name to update (e.g. origin)"
                $url  = Read-Host "--> New URL"
                if ($name -and $url) {
                    git remote set-url $name $url
                    $commandsUsed += "git remote set-url $name $url"
                    Write-Host "--> Remote '$name' URL updated." -ForegroundColor Green
                } else { Write-Host "!! Name and URL required." -ForegroundColor Red }
            }
            '3' {
                Write-Host ""
                Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
                Write-Host "║                   git remote remove                          ║" -ForegroundColor Green
                Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
                Write-Host "  What it does : Deletes a remote connection from your local repository." -ForegroundColor Cyan
                Write-Host "  When to use  : When a remote repository is no longer needed or has been deleted." -ForegroundColor Cyan
                Write-Host "  Safe?        : CAREFUL — removes the link, may prevent pushing/pulling." -ForegroundColor Red
                Write-Host ""
                Write-Host "  Hints:" -ForegroundColor White
                Write-Host "  • Only removes the local reference, doesn't delete the remote repo itself." -ForegroundColor DarkGray
                Write-Host "  • Ensure no active branches are tracking this remote before removal." -ForegroundColor DarkGray
                Write-Host "  • You can always add the remote back later if needed." -ForegroundColor DarkGray
                Write-Host ""
                git remote -v | Out-Host; Write-Host ""
                $name = Read-Host "--> Remote name to remove"
                if ($name) {
                    $c = Read-Host "--> Remove remote '$name'? (y/n)"
                    if ($c -eq 'y') {
                        git remote remove $name
                        $commandsUsed += "git remote remove $name"
                        Write-Host "--> Remote '$name' removed." -ForegroundColor Green
                    } else {
                        Write-Host "--> Remote removal canceled." -ForegroundColor DarkGray
                    }
                } else { Write-Host "!! Name required." -ForegroundColor Red }
            }
            '4' {
                Write-Host ""
                Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
                Write-Host "║                    git remote show                           ║" -ForegroundColor Green
                Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
                Write-Host "  What it does : Displays detailed information about a specific remote." -ForegroundColor Cyan
                Write-Host "  When to use  : To inspect the URLs, branches, and fetch configurations." -ForegroundColor Cyan
                Write-Host "  Safe?        : Yes — read-only." -ForegroundColor Cyan
                Write-Host ""
                Write-Host "  Hints:" -ForegroundColor White
                Write-Host "  • Shows remote name, URL, tracked branches, and more." -ForegroundColor DarkGray
                Write-Host "  • Helps debug issues with remote connections or branch tracking." -ForegroundColor DarkGray
                Write-Host "  • Can run 'git remote show origin' (or other remote name)." -ForegroundColor DarkGray
                Write-Host ""
                $name = Read-Host "--> Remote name (e.g. origin)"
                if ($name) {
                    git remote show $name
                    $commandsUsed += "git remote show $name"
                } else { Write-Host "!! Name required." -ForegroundColor Red }
            }
            '5' {
                Write-Host "--> Returning to main menu..."
                Show-CommandRecap $commandsUsed
                return
            }
            default { Write-Host "`n!! Invalid option: '$remoteChoice'. Please try again." -ForegroundColor Red }
        }
        Show-CommandRecap $commandsUsed
        Write-Host "`n================================================================" -ForegroundColor Green
        Write-Host "Enter next remote option (1-5) or press [Enter] for menu: " -ForegroundColor Yellow -NoNewline
        $remoteChoice = Read-Host
    }
}

# --- Main Script Logic ---
$choice = ""
while ($true) {
    if ([string]::IsNullOrWhiteSpace($choice)) {
        Clear-Host; Show-Header
        Write-Host "What task would you like to perform?" -ForegroundColor Yellow
        Write-Host ""

        Write-Host "--- Local Repository ---" -ForegroundColor Green
        Write-Host "1.  Initialize New Repository (git init)"
        Write-Host "2.  Format Terraform Files (terraform fmt)"
        Write-Host "3.  Add All and Initial Commit"
        Write-Host "4.  Check Repository Status"
        Write-Host "5.  Add File and Commit"
        Write-Host "6.  Add Folder and Commit"
        Write-Host "7.  Add All and Commit"
        Write-Host "8.  View Changes / Diff"
        Write-Host "9.  Discard Uncommitted Changes"
        Write-Host ""

        Write-Host "--- Remote and Sync ---" -ForegroundColor Green
        Write-Host "10. Clone a Repository"
        Write-Host "11. Push Changes to Remote"
        Write-Host "12. Pull Changes from Remote"
        Write-Host "13. Fetch from Remote (no merge)"
        Write-Host "14. Manage Pull Requests (GitHub CLI)"
        Write-Host "15. Manage Remotes (Sub-Menu)"
        Write-Host ""

        Write-Host "--- History ---" -ForegroundColor Green
        Write-Host "16. View Commit Log"
        Write-Host "17. Stash Uncommitted Changes"
        Write-Host "18. Apply Stashed Changes"
        Write-Host ""

        Write-Host "--- Branch Operations ---" -ForegroundColor Green
        Write-Host "19. Branch Management (Sub-Menu)"
        Write-Host "20. Merge a Branch"
        Write-Host "21. Rebase Current Branch"
        Write-Host ""

        Write-Host "--- Advanced Operations ---" -ForegroundColor Green
        Write-Host "22. Cherry-Pick a Commit"
        Write-Host "23. Revert a Commit"
        Write-Host "24. Create a Version Tag"
        Write-Host ""

        Write-Host "25. Exit" -ForegroundColor Green
        Write-Host ""

        Write-Host "--> Choose an option (1-25): " -ForegroundColor Yellow -NoNewline
        $choice = Read-Host
    }

    $commandsUsed = @() # Initialize for each action

    switch ($choice) {
        '1' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                       git init                               ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Creates a new, empty Git repository in the current directory." -ForegroundColor Cyan
            Write-Host "  When to use  : When starting a brand new project that you want to version control." -ForegroundColor Cyan
            Write-Host "  Safe?        : Yes — it just creates a hidden .git folder; no data is lost." -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • Run this command in the root folder of your project." -ForegroundColor DarkGray
            Write-Host "  • Avoid initializing a Git repo inside another existing Git repo." -ForegroundColor DarkGray
            Write-Host "  • After init, use 'git add' and 'git commit' to start tracking files." -ForegroundColor DarkGray
            Write-Host ""

            if (Test-Path ".git") {
                Write-Host "!! Already a Git repository." -ForegroundColor Yellow
            } else {
                $c = Read-Host "--> Initialize here? (y/n)"
                if ($c -eq 'y') {
                    git init
                    $commandsUsed += "git init"
                } else {
                    Write-Host "--> Initialization canceled." -ForegroundColor DarkGray
                }
            }
        }

        '2' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                    terraform fmt                             ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Formats all Terraform .tf files to a canonical style." -ForegroundColor Cyan
            Write-Host "  When to use  : Before committing Terraform code to ensure consistent formatting." -ForegroundColor Cyan
            Write-Host "  Safe?        : Yes — only reformats whitespace and indentation; no functional changes." -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • Requires Terraform CLI to be installed and available in your PATH." -ForegroundColor DarkGray
            Write-Host "  • Run this command from the root of your Terraform module." -ForegroundColor DarkGray
            Write-Host "  • Use 'terraform fmt -check' to only validate formatting without changing files." -ForegroundColor DarkGray
            Write-Host "  • Improves code readability and reduces merge conflicts related to formatting." -ForegroundColor DarkGray
            Write-Host ""

            if (Get-Command terraform -ErrorAction SilentlyContinue) {
                terraform fmt -recursive
                $commandsUsed += "terraform fmt -recursive"
            } else {
                Write-Host "!! Warning: Terraform CLI not found. Please install it to use this feature." -ForegroundColor Red
            }
        }

        '3' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                   git add . && git commit                    ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Stages all current changes and creates the initial commit." -ForegroundColor Cyan
            Write-Host "  When to use  : After 'git init' to create the very first save point of your project." -ForegroundColor Cyan
            Write-Host "  Safe?        : Yes, for initial commit. Subsequent commits override history." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • This command uses 'git add .' to stage all files." -ForegroundColor DarkGray
            Write-Host "  • Write a meaningful commit message, even if it's "Initial commit"." -ForegroundColor DarkGray
            Write-Host "  • This commit forms the foundation of your repository's history." -ForegroundColor DarkGray
            Write-Host ""
            $c = Read-Host "--> Stage all files and create 'Initial commit'? (y/n)"
            if ($c -eq 'y') {
                git add .
                $commandsUsed += "git add ."
                git commit -m "Initial commit"
                $commandsUsed += "git commit -m '"Initial commit"'"
            } else { Write-Host "--> Canceled." -ForegroundColor DarkGray }
        }

        '4' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                       git status                             ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Shows the state of your working directory and staging area." -ForegroundColor Cyan
            Write-Host "  When to use  : Anytime to see what's changed, staged, or untracked." -ForegroundColor Cyan
            Write-Host "  Safe?        : Yes — read-only, makes no changes to your repository." -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • Run this command frequently, especially before making a commit." -ForegroundColor DarkGray
            Write-Host "  • Files in red are modified but unstaged; files in green are staged." -ForegroundColor DarkGray
            Write-Host "  • '??' prefix indicates untracked files (not yet added to Git)." -ForegroundColor DarkGray
            Write-Host "  • Helps keep track of your progress and identify files for committing." -ForegroundColor DarkGray
            Write-Host ""
            git status
            $commandsUsed += "git status"
        }

        '5' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                git add <file> && git commit                  ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Stages a specific file and creates a commit." -ForegroundColor Cyan
            Write-Host "  When to use  : For focused changes affecting only one file." -ForegroundColor Cyan
            Write-Host "  Safe?        : Yes, if you intend to commit that file's changes." -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • Use tab-completion for the file path to avoid typos." -ForegroundColor DarkGray
            Write-Host "  • The commit message should clearly explain the changes made to that file." -ForegroundColor DarkGray
            Write-Host "  • Useful for isolating changes and creating atomic commits." -ForegroundColor DarkGray
            Write-Host ""
            $fp = Read-Host "--> File path to add and commit"
            if ($fp) {
                if (-not (Test-Path $fp)) {
                    Write-Host "!! File '$fp' not found. Please enter a valid path." -ForegroundColor Red
                } else {
                    $msg = Read-Host "--> Commit message (leave blank for default: 'Update $fp')"
                    if ([string]::IsNullOrWhiteSpace($msg)) { $msg = "Update $fp" }
                    git add $fp
                    $commandsUsed += "git add $fp"
                    git commit -m "$msg"
                    $commandsUsed += "git commit -m '$msg'"
                }
            } else { Write-Host "!! File path required." -ForegroundColor Red }
        }

        '6' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║               git add <folder> && git commit                 ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Stages all changes within a specific folder and creates a commit." -ForegroundColor Cyan
            Write-Host "  When to use  : When a feature or fix spans multiple files within a single folder." -ForegroundColor Cyan
            Write-Host "  Safe?        : Yes, if you intend to commit all changes in that folder." -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • Git tracks files, not folders directly. This will stage all files in the folder." -ForegroundColor DarkGray
            Write-Host "  • The commit message should describe the collective changes in the folder." -ForegroundColor DarkGray
            Write-Host "  • Use 'git status' before to confirm all intended changes are within this folder." -ForegroundColor DarkGray
            Write-Host ""
            $fp = Read-Host "--> Folder path to add and commit"
            if ($fp) {
                if (-not (Test-Path $fp -PathType Container)) {
                    Write-Host "!! Folder '$fp' not found. Please enter a valid path." -ForegroundColor Red
                } else {
                    $msg = Read-Host "--> Commit message (leave blank for default: 'Update folder $fp')"
                    if ([string]::IsNullOrWhiteSpace($msg)) { $msg = "Update folder $fp" }
                    git add $fp
                    $commandsUsed += "git add $fp"
                    git commit -m "$msg"
                    $commandsUsed += "git commit -m '$msg'"
                }
            } else { Write-Host "!! Folder path required." -ForegroundColor Red }
        }

        '7' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                     git add . && git commit                  ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Stages ALL modified and new files, then creates a commit." -ForegroundColor Cyan
            Write-Host "  When to use  : For collective changes that logically belong together and you're sure about." -ForegroundColor Cyan
            Write-Host "  Safe?        : Use with caution — ensures *all* changes are included. Check 'git status' first." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • Always run 'git status' immediately before this to review all changes." -ForegroundColor DarkGray
            Write-Host "  • Avoid committing unrelated changes together (mixes concerns, harder to revert)." -ForegroundColor DarkGray
            Write-Host "  • A clear, concise commit message is crucial for documenting these broad changes." -ForegroundColor DarkGray
            Write-Host ""
            $c = Read-Host "--> Stage ALL changes and commit? (y/n)"
            if ($c -eq 'y') {
                $msg = Read-Host "--> Commit message (leave blank for default: 'General update')"
                if ([string]::IsNullOrWhiteSpace($msg)) { $msg = "General update" }
                git add .
                $commandsUsed += "git add ."
                git commit -m "$msg"
                $commandsUsed += "git commit -m '$msg'"
            } else { Write-Host "--> Canceled." -ForegroundColor DarkGray }
        }

        '8' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                        git diff                              ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Shows exactly what changed, line by line, between versions." -ForegroundColor Cyan
            Write-Host "  When to use  : Before committing, to review your own work; or to compare branches." -ForegroundColor Cyan
            Write-Host "  Safe?        : Yes — read-only, makes no changes to your repository." -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • Red lines show removed content, green lines show added content." -ForegroundColor DarkGray
            Write-Host "  • Press 'q' to exit the diff view in the terminal." -ForegroundColor DarkGray
            Write-Host "  • Use 'git diff --staged' to see changes already moved to the staging area." -ForegroundColor DarkGray
            Write-Host "  • Essential for code review and understanding changes." -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "a. Unstaged changes (working tree)" -ForegroundColor Yellow
            Write-Host "b. Staged changes (ready to commit)"
            Write-Host "c. Compare two branches"
            Write-Host "--> Choose: " -NoNewline
            $d = Read-Host
            switch ($d) {
                'a' {
                    git diff
                    $commandsUsed += "git diff"
                }
                'b' {
                    git diff --staged
                    $commandsUsed += "git diff --staged"
                }
                'c' {
                    git branch -a | Out-Host; Write-Host ""
                    $b1 = Read-Host "--> First branch (e.g., main)"
                    $b2 = Read-Host "--> Second branch (e.g., feature/my-new-thing)"
                    if ($b1 -and $b2) {
                        git diff "${b1}..${b2}"
                        $commandsUsed += "git diff '${b1}..${b2}'"
                    } else {
                        Write-Host "!! Both branch names are required." -ForegroundColor Red
                    }
                }
                default { Write-Host "!! Invalid option." -ForegroundColor Red }
            }
        }

        '9' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║              git checkout -- / git reset HEAD                ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Discards uncommitted changes in your working directory or unstages files." -ForegroundColor Cyan
            Write-Host "  When to use  : When you want to revert changes you've made but haven't committed yet." -ForegroundColor Cyan
            Write-Host "  Safe?        : CAREFUL — discarded changes cannot be easily recovered." -ForegroundColor Red
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • Consider using 'git stash' instead if you might want changes back later." -ForegroundColor DarkGray
            Write-Host "  • Always run 'git status' first to clearly understand what will be discarded." -ForegroundColor DarkGray
            Write-Host "  • 'git checkout -- <file>' discards changes to a specific file." -ForegroundColor DarkGray
            Write-Host "  • 'git reset HEAD <file>' unstages changes, but keeps them in your working directory." -ForegroundColor DarkGray
            Write-Host ""
            git status | Out-Host; Write-Host ""
            Write-Host "a. Discard ALL uncommitted changes" -ForegroundColor Yellow
            Write-Host "b. Discard changes in a specific file"
            Write-Host "c. Unstage a file (keep changes, remove from staging only)"
            Write-Host "--> Choose: " -NoNewline
            $d = Read-Host
            switch ($d) {
                'a' {
                    $c = Read-Host "--> DISCARD ALL uncommitted changes? (y/n)"
                    if ($c -eq 'y') {
                        git checkout -- .
                        $commandsUsed += "git checkout -- ."
                        Write-Host "--> All uncommitted changes discarded." -ForegroundColor Green
                    } else {
                        Write-Host "--> Discard operation canceled." -ForegroundColor DarkGray
                    }
                }
                'b' {
                    $fn = Read-Host "--> File path to discard changes from"
                    if ($fn) {
                        if (-not (Test-Path $fn)) {
                            Write-Host "!! File '$fn' not found. Please enter a valid path." -ForegroundColor Red
                        } else {
                            $c = Read-Host "--> Discard changes in '$fn'? (y/n)"
                            if ($c -eq 'y') {
                                git checkout -- $fn
                                $commandsUsed += "git checkout -- $fn"
                                Write-Host "--> Changes in '$fn' discarded." -ForegroundColor Green
                            } else {
                                Write-Host "--> Discard operation canceled." -ForegroundColor DarkGray
                            }
                        }
                    } else { Write-Host "!! File path required." -ForegroundColor Red }
                }
                'c' {
                    git diff --staged --name-only | Out-Host; Write-Host ""
                    $fn = Read-Host "--> File to unstage (changes will be kept in working directory)"
                    if ($fn) {
                        if (-not (Test-Path $fn)) {
                            Write-Host "!! File '$fn' not found. Please enter a valid path." -ForegroundColor Red
                        } else {
                            $c = Read-Host "--> Unstage '$fn'? (y/n)"
                            if ($c -eq 'y') {
                                git reset HEAD $fn
                                $commandsUsed += "git reset HEAD $fn"
                                Write-Host "--> '$fn' unstaged (changes kept in working tree)." -ForegroundColor Green
                            } else {
                                Write-Host "--> Unstage operation canceled." -ForegroundColor DarkGray
                            }
                        }
                    } else { Write-Host "!! File path required." -ForegroundColor Red }
                }
                default { Write-Host "!! Invalid option." -ForegroundColor Red }
            }
        }

        '10' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                          git clone                           ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Downloads a remote repository to your local machine." -ForegroundColor Cyan
            Write-Host "  When to use  : When you're starting work on an existing project for the first time." -ForegroundColor Cyan
            Write-Host "  Safe?        : Yes — read-only from the remote; nothing on remote is changed." -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • URL format: https://github.com/user/repo.git or git@github.com:user/repo.git" -ForegroundColor DarkGray
            Write-Host "  • After cloning, use 'cd' into the new folder, then 'npm install' / 'pip install', etc." -ForegroundColor DarkGray
            Write-Host "  • For private repositories, ensure you're authenticated (e.g., 'gh auth login' or SSH key)." -ForegroundColor DarkGray
            Write-Host "  • Use '--depth 1' for shallow clones if you only need the latest commit history." -ForegroundColor DarkGray
            Write-Host ""

            $repoUrl = Read-Host "--> Repository URL to clone"
            if ($repoUrl) {
                $cloneDir = Read-Host "--> Local folder name (leave blank for default, uses repo name)"
                if ($cloneDir) {
                    git clone $repoUrl $cloneDir
                    $commandsUsed += "git clone $repoUrl $cloneDir"
                } else {
                    git clone $repoUrl
                    $commandsUsed += "git clone $repoUrl"
                }
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "--> Repository cloned successfully." -ForegroundColor Green
                    if ($cloneDir) {
                        $goIn = Read-Host "--> cd into '$cloneDir'? (y/n)"
                        if ($goIn -eq 'y') {
                            Set-Location $cloneDir
                            $commandsUsed += "cd $cloneDir"
                            Write-Host "--> Now in: $(Get-Location)" -ForegroundColor Green
                        }
                    }
                } else {
                    Write-Host "!! Git clone failed. Check the URL and your network connection." -ForegroundColor Red
                }
            } else { Write-Host "!! Repository URL is required." -ForegroundColor Red }
        }

        '11' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                        git push                              ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Uploads your local commits to the remote repository." -ForegroundColor Cyan
            Write-Host "  When to use  : After committing changes locally, to share your work with others." -ForegroundColor Cyan
            Write-Host "  Safe?        : Yes, for normal pushes. Force pushing can rewrite history (be careful!)." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • Always pull the latest changes before pushing to avoid conflicts." -ForegroundColor DarkGray
            Write-Host "  • Use '-u origin <branch>' to set the upstream tracking branch for new branches." -ForegroundColor DarkGray
            Write-Host "  • '--force' or '--force-with-lease' should be used with extreme caution on shared branches." -ForegroundColor DarkGray
            Write-Host "  • Pushes local branches to their corresponding remote branches." -ForegroundColor DarkGray
            Write-Host ""

            if (Check-Remote) {
                $currentBranch = git branch --show-current
                Write-Host "--> Current branch: $currentBranch" -ForegroundColor Cyan
                Write-Host "a. Push to origin/$currentBranch"
                Write-Host "b. Push and set upstream (first push of a new branch)"
                Write-Host "c. Force push (use with caution!)"
                Write-Host "--> Choose (or press [Enter] for default push 'a'): " -NoNewline
                $pc = Read-Host
                switch ($pc) {
                    'b' {
                        git push --set-upstream origin $currentBranch
                        $commandsUsed += "git push --set-upstream origin $currentBranch"
                        Write-Host "--> Pushed and upstream set for '$currentBranch'." -ForegroundColor Green
                    }
                    'c' {
                        $confirmForce = Read-Host "--> WARNING: Force push can overwrite remote history. Are you sure? (y/n)"
                        if ($confirmForce -eq 'y') {
                            git push --force origin $currentBranch
                            $commandsUsed += "git push --force origin $currentBranch"
                            Write-Host "--> Force pushed to origin/$currentBranch." -ForegroundColor Yellow
                        } else {
                            Write-Host "--> Force push canceled." -ForegroundColor DarkGray
                        }
                    }
                    default {
                        $c = Read-Host "--> Push current branch '$currentBranch' to remote? (y/n)"
                        if ($c -eq 'y') {
                            git push
                            $commandsUsed += "git push"
                        } else {
                            Write-Host "--> Push canceled." -ForegroundColor DarkGray
                        }
                    }
                }
            }
        }

        '12' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                        git pull                              ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Downloads changes from a remote repository and merges them into your current branch." -ForegroundColor Cyan
            Write-Host "  When to use  : To synchronize your local repository with changes made by teammates." -ForegroundColor Cyan
            Write-Host "  Safe?        : Yes, for most cases. Conflicts may require manual resolution." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • Always pull before starting work each day or before pushing your own changes." -ForegroundColor DarkGray
            Write-Host "  • 'git pull' is essentially 'git fetch' followed by 'git merge'." -ForegroundColor DarkGray
            Write-Host "  • Be prepared to resolve merge conflicts if your local changes overlap with remote changes." -ForegroundColor DarkGray
            Write-Host "  • Helps keep your local branch up-to-date with the remote." -ForegroundColor DarkGray
            Write-Host ""

            if (Check-Remote) {
                $c = Read-Host "--> Pull changes from remote? (y/n)"
                if ($c -eq 'y') {
                    git pull
                    $commandsUsed += "git pull"
                } else {
                    Write-Host "--> Pull canceled." -ForegroundColor DarkGray
                }
            }
        }

        '13' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                        git fetch                             ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Downloads changes from the remote repository but DOES NOT merge them." -ForegroundColor Cyan
            Write-Host "  When to use  : To see what changes have occurred on the remote before deciding to merge." -ForegroundColor Cyan
            Write-Host "  Safe?        : Yes — read-only, your local code and branches remain untouched." -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • Use 'git log origin/main' (assuming 'main' is your main branch) after fetching to inspect changes." -ForegroundColor DarkGray
            Write-Host "  • '--prune' option removes references to remote-tracking branches that no longer exist on the remote." -ForegroundColor DarkGray
            Write-Host "  • Allows you to review incoming changes without applying them, offering more control than 'git pull'." -ForegroundColor DarkGray
            Write-Host ""

            if (Check-Remote) {
                Write-Host "a. Fetch all remotes (+ prune stale branches)"
                Write-Host "b. Fetch a specific remote"
                Write-Host "--> Choose (or press [Enter] for default 'a'): " -NoNewline
                $fc = Read-Host
                switch ($fc) {
                    'b' {
                        $rn = Read-Host "--> Remote name (e.g. origin)"
                        if ($rn) {
                            git fetch $rn --prune
                            $commandsUsed += "git fetch $rn --prune"
                            Write-Host "--> Fetched from '$rn'." -ForegroundColor Green
                        } else {
                            Write-Host "!! Remote name required." -ForegroundColor Red
                        }
                    }
                    default {
                        git fetch --all --prune
                        $commandsUsed += "git fetch --all --prune"
                        Write-Host "--> Fetched all remotes. Use 'git log origin/main' to inspect." -ForegroundColor Green
                    }
                }
            }
        }

        '14' {
            Handle-PullRequestMenu
            $choice = "" # Clear choice to display main menu after sub-menu exit
        }

        '15' {
            Handle-RemoteMenu
            $choice = "" # Clear choice to display main menu after sub-menu exit
        }

        '16' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                         git log                              ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Displays the commit history of your repository." -ForegroundColor Cyan
            Write-Host "  When to use  : To review past changes, find specific commits, or understand branch lineage." -ForegroundColor Cyan
            Write-Host "  Safe?        : Yes — read-only, makes no changes to your repository." -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • Use '--oneline' for a compact, single-line summary of each commit." -ForegroundColor DarkGray
            Write-Host "  • '--graph' visualizes the branch and merge history with ASCII art." -ForegroundColor DarkGray
            Write-Host "  • Press 'q' to exit the log view." -ForegroundColor DarkGray
            Write-Host "  • Each commit has a unique hash (SHA-1) that identifies it." -ForegroundColor DarkGray
            Write-Host ""

            Write-Host "a. Graph view (compact, with branch history)" -ForegroundColor Yellow
            Write-Host "b. Full log (detailed view, latest 10 commits)"
            Write-Host "c. Compact one-line (latest 20 commits)"
            Write-Host "--> Choose (or [Enter] for default 'a'): " -NoNewline
            $lc = Read-Host
            switch ($lc) {
                'b' {
                    git log -10
                    $commandsUsed += "git log -10"
                }
                'c' {
                    git log --oneline -20
                    $commandsUsed += "git log --oneline -20"
                }
                default {
                    git log --oneline --graph -15
                    $commandsUsed += "git log --oneline --graph -15"
                }
            }
        }

        '17' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                       git stash                              ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Temporarily saves uncommitted changes and reverts your working directory." -ForegroundColor Cyan
            Write-Host "  When to use  : When you need to switch branches quickly but aren't ready to commit your current work." -ForegroundColor Cyan
            Write-Host "  Safe?        : Yes — saves your changes in a hidden area, but conflicts can occur on apply." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • 'stash' acts like a stack (Last In, First Out) for your changes." -ForegroundColor DarkGray
            Write-Host "  • You can list stashes with 'git stash list' and give them names." -ForegroundColor DarkGray
            Write-Host "  • Stashed changes include both staged and unstaged modifications." -ForegroundColor DarkGray
            Write-Host "  • Helps keep your working directory clean when switching context." -ForegroundColor DarkGray
            Write-Host ""

            $c = Read-Host "--> Stash current uncommitted changes? (y/n)"
            if ($c -eq 'y') {
                $stashMessage = Read-Host "--> Optional: Enter a message for this stash (e.g., 'WIP: login form')"
                if ([string]::IsNullOrWhiteSpace($stashMessage)) {
                    git stash
                    $commandsUsed += "git stash"
                } else {
                    git stash save "$stashMessage"
                    $commandsUsed += "git stash save '$stashMessage'"
                }
                Write-Host "--> Changes stashed successfully." -ForegroundColor Green
            } else {
                Write-Host "--> Stash operation canceled." -ForegroundColor DarkGray
            }
        }

        '18' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                     git stash pop / apply                    ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Restores previously stashed changes to your working directory." -ForegroundColor Cyan
            Write-Host "  When to use  : After completing other tasks, to return to your saved work." -ForegroundColor Cyan
            Write-Host "  Safe?        : Yes, but conflicting changes might require manual resolution." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • 'pop' removes the stash from the list after applying; 'apply' keeps it." -ForegroundColor DarkGray
            Write-Host "  • Conflicts can occur if the code has changed significantly since stashing." -ForegroundColor DarkGray
            Write-Host "  • Use 'git stash list' to see all available stashes and their indices." -ForegroundColor DarkGray
            Write-Host "  • After applying, review changes with 'git status' and 'git diff'." -ForegroundColor DarkGray
            Write-Host ""

            git stash list | Out-Host; Write-Host ""
            Write-Host "a. Apply latest stash (keep in list)" -ForegroundColor Yellow
            Write-Host "b. Pop latest stash (remove from list)"
            Write-Host "c. Apply specific stash by index"
            Write-Host "--> Choose (or [Enter] for default 'b'): " -NoNewline
            $sc = Read-Host
            switch ($sc) {
                'a' {
                    git stash apply
                    $commandsUsed += "git stash apply"
                    Write-Host "--> Latest stash applied." -ForegroundColor Green
                }
                'c' {
                    $idx = Read-Host "--> Stash index to apply (e.g. 0 for 'stash@{0}')"
                    if ([string]::IsNullOrWhiteSpace($idx)) {
                        Write-Host "!! Stash index required." -ForegroundColor Red
                    } elseif ($idx -match "^\d+$") {
                        git stash apply "stash@{$idx}"
                        $commandsUsed += "git stash apply 'stash@{$idx}'"
                        Write-Host "--> Stash $idx applied." -ForegroundColor Green
                    } else {
                        Write-Host "!! Invalid index format. Please enter a number." -ForegroundColor Red
                    }
                }
                default { # Default to pop
                    $c = Read-Host "--> Pop latest stash (apply and remove from list)? (y/n)"
                    if ($c -eq 'y') {
                        git stash pop
                        $commandsUsed += "git stash pop"
                        Write-Host "--> Latest stash popped and applied." -ForegroundColor Green
                    } else {
                        Write-Host "--> Stash pop canceled." -ForegroundColor DarkGray
                    }
                }
            }
        }

        '19' {
            Handle-BranchMenu
            $choice = "" # Clear choice to display main menu after sub-menu exit
        }

        '20' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                        git merge                             ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Combines the history of another branch into your current branch." -ForegroundColor Cyan
            Write-Host "  When to use  : After a feature is complete and reviewed, to integrate it into a main branch." -ForegroundColor Cyan
            Write-Host "  Safe?        : Yes, but be prepared to resolve merge conflicts if branches diverge." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • Always pull the latest changes from the target branch before merging." -ForegroundColor DarkGray
            Write-Host "  • If conflicts arise, Git will pause the merge, allowing you to resolve them manually." -ForegroundColor DarkGray
            Write-Host "  • Use 'git merge --abort' to cancel a merge with conflicts." -ForegroundColor DarkGray
            Write-Host "  • Creates a new 'merge commit' by default, showing where histories combine." -ForegroundColor DarkGray
            Write-Host ""

            if (Check-Remote) {
                Write-Host "--> Available branches (local):"; git branch | Out-Host
                $b = Read-Host "--> Branch to merge INTO your current branch"
                if ($b) {
                    $c = Read-Host "--> Confirm merging '$b' into '$(git branch --show-current)'? (y/n)"
                    if ($c -eq 'y') {
                        git merge $b
                        $commandsUsed += "git merge $b"
                    } else {
                        Write-Host "--> Merge operation canceled." -ForegroundColor DarkGray
                    }
                } else { Write-Host "!! Branch name required." -ForegroundColor Red }
            }
        }

        '21' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                        git rebase                            ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Rewrites your branch's history by moving/combining commits." -ForegroundColor Cyan
            Write-Host "  When to use  : To create a cleaner, linear history by replaying your commits on a new base." -ForegroundColor Cyan
            Write-Host "  Safe?        : CAREFUL — rewrites commit hashes. NEVER rebase public/shared branches." -ForegroundColor Red
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • Rebase before merging often leads to a tidier commit graph." -ForegroundColor DarkGray
            Write-Host "  • Use 'git rebase --abort' to stop a rebase in progress." -ForegroundColor DarkGray
            Write-Host "  • Best applied to your own private feature branches before they are shared." -ForegroundColor DarkGray
            Write-Host "  • Interactive rebase ('-i') allows for advanced editing like squashing or reordering commits." -ForegroundColor DarkGray
            Write-Host ""

            if (Check-Remote) {
                Write-Host "--> Available branches (local):"; git branch | Out-Host
                $b = Read-Host "--> Branch to rebase your current branch ONTO (e.g., main)"
                if ($b) {
                    $c = Read-Host "--> WARNING: Rebase current branch onto '$b'? This rewrites history! (y/n)"
                    if ($c -eq 'y') {
                        git rebase $b
                        $commandsUsed += "git rebase $b"
                    } else {
                        Write-Host "--> Rebase operation canceled." -ForegroundColor DarkGray
                    }
                } else { Write-Host "!! Branch name required." -ForegroundColor Red }
            }
        }

        '22' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                       git cherry-pick                        ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Applies a specific commit from one branch onto another." -ForegroundColor Cyan
            Write-Host "  When to use  : To port a single bug fix or small feature commit to another branch without merging entire branches." -ForegroundColor Cyan
            Write-Host "  Safe?        : Yes, but conflicts can occur if the changes don't apply cleanly." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • You'll need the commit hash (the unique identifier) of the commit you want to pick." -ForegroundColor DarkGray
            Write-Host "  • Commit hashes can be found using 'git log'." -ForegroundColor DarkGray
            Write-Host "  • Can cherry-pick multiple commits in a row." -ForegroundColor DarkGray
            Write-Host "  • A new commit is created on the current branch with the changes from the picked commit." -ForegroundColor DarkGray
            Write-Host ""

            $h = Read-Host "--> Commit hash to cherry-pick"
            if ($h) {
                $c = Read-Host "--> Cherry-pick commit '$h' onto current branch? (y/n)"
                if ($c -eq 'y') {
                    git cherry-pick $h
                    $commandsUsed += "git cherry-pick $h"
                } else {
                    Write-Host "--> Cherry-pick canceled." -ForegroundColor DarkGray
                }
            } else { Write-Host "!! Commit hash required." -ForegroundColor Red }
        }

        '23' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                        git revert                            ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Creates a new commit that undoes the changes of a previous commit." -ForegroundColor Cyan
            Write-Host "  When to use  : To safely undo changes that have already been pushed to a shared branch." -ForegroundColor Cyan
            Write-Host "  Safe?        : Yes — it doesn't rewrite history, making it safer for shared branches than rebase/reset." -ForegroundColor Green
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • You'll need the commit hash of the commit you want to revert." -ForegroundColor DarkGray
            Write-Host "  • The new 'revert' commit will appear in your history, clearly showing the undo." -ForegroundColor DarkGray
            Write-Host "  • Use '--no-edit' to skip opening the commit message editor for the revert commit." -ForegroundColor DarkGray
            Write-Host "  • Safer than 'git reset' when working collaboratively." -ForegroundColor DarkGray
            Write-Host ""

            $h = Read-Host "--> Commit hash to revert"
            if ($h) {
                $c = Read-Host "--> Revert commit '$h' (creates a new commit to undo it)? (y/n)"
                if ($c -eq 'y') {
                    git revert --no-edit $h
                    $commandsUsed += "git revert --no-edit $h"
                } else {
                    Write-Host "--> Revert operation canceled." -ForegroundColor DarkGray
                }
            } else { Write-Host "!! Commit hash required." -ForegroundColor Red }
        }

        '24' {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║                         git tag                              ║" -ForegroundColor Green
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "  What it does : Marks a specific commit in your history with a permanent label (tag)." -ForegroundColor Cyan
            Write-Host "  When to use  : To mark release points (e.g., v1.0, v2.0) or significant milestones." -ForegroundColor Cyan
            Write-Host "  Safe?        : Yes — creates a reference, doesn't change code or history." -ForegroundColor Green
            Write-Host ""
            Write-Host "  Hints:" -ForegroundColor White
            Write-Host "  • Annotated tags ('git tag -a') are recommended as they include a tag message, author, and date." -ForegroundColor DarkGray
            Write-Host "  • Tags are not pushed to remote automatically; use 'git push origin <tagname>' to share them." -ForegroundColor DarkGray
            Write-Host "  • Commonly used for semantic versioning (e.g., v1.2.3)." -ForegroundColor DarkGray
            Write-Host "  • You can view existing tags with 'git tag'." -ForegroundColor DarkGray
            Write-Host ""

            $t = Read-Host "--> Tag name (e.g., v1.0.0)"
            if ($t) {
                $m = Read-Host "--> Tag message (e.g., 'Release version 1.0.0')"
                if ([string]::IsNullOrWhiteSpace($m)) { $m = "$t release" }
                git tag -a $t -m "$m"
                $commandsUsed += "git tag -a $t -m '$m'"
                Write-Host "--> Tag '$t' created." -ForegroundColor Green
            } else { Write-Host "!! Tag name required." -ForegroundColor Red }
        }

        '25' {
            Write-Host "`nExiting Git Assistant. Goodbye!" -ForegroundColor Green
            break
        }

        default { Write-Host "`n!! Invalid option: '$choice'. Please try again." -ForegroundColor Red }
    }

    Show-CommandRecap $commandsUsed

    # After returning from sub-menus, clear choice to show main menu (your original pattern)
    if ($choice -ne '14' -and $choice -ne '15' -and $choice -ne '19') { # Updated to include new option 14
        Write-Host "`n================================================================" -ForegroundColor Green
        Write-Host "Enter next option (1-25) or press [Enter] for menu: " -ForegroundColor Yellow -NoNewline
        $choice = Read-Host
    }
}

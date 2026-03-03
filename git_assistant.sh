#!/bin/bash
#
#######################################################################################################################################
# .SYNOPSIS
#     An interactive Bash script to simplify a full Git workflow, from initialization to advanced operations.
# .DESCRIPTION
#     This script provides a user-friendly menu to perform tasks like initializing a repo, checking status,
#     committing files/folders, pushing, pulling, cloning, switching branches, managing remotes, and more.
#     It includes colored output for clarity, explanation blocks, command recaps, and confirmation prompts for critical actions.
# .AUTHOR
#     kossi.eglo@stackit.cloud
# .DATE
#     July 31, 2025 — Updated March 3, 2026 (Shell version with explanations, command recap, PR management)
#######################################################################################################################################

# --- Colors and Styling ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
DARK_GRAY='\033[0;90m'
NOCOLOR='\033[0m'

# --- Helper Functions ---

# Displays the consistent header at the top of the screen.
show_header() {
    echo -e "${GREEN}================================================================${NOCOLOR}"
    echo -e "${WHITE}          Interactive Git Assistant                             ${NOCOLOR}"
    echo -e "${GREEN}================================================================${NOCOLOR}"
    echo -e ""
}

# Displays explanation block for a given command.
show_explanation() {
    local command_name="$1"
    local description="$2"
    local when_to_use="$3"
    local safe_status="$4"
    shift 4
    local hints=("$@")

    echo -e ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NOCOLOR}"
    echo -e "${GREEN}║  ${command_name:-N/A}                                                   ║${NOCOLOR}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NOCOLOR}"
    echo -e "  ${CYAN}What it does :${NOCOLOR} ${description}"
    echo -e "  ${CYAN}When to use  :${NOCOLOR} ${when_to_use}"
    echo -e "  ${CYAN}Safe?        :${NOCOLOR} ${safe_status}"
    echo -e ""
    echo -e "  ${WHITE}Hints:${NOCOLOR}"
    for hint in "${hints[@]}"; do
        echo -e "  ${DARK_GRAY}• ${hint}${NOCOLOR}"
    done
    echo -e ""
}

# Displays the commands used.
show_command_recap() {
    local commands=("$@")
    echo -e ""
    echo -e ""
    echo -e "${GREEN}================================================================${NOCOLOR}"
    echo -e "${WHITE}  Commands used:${NOCOLOR}"
    for cmd in "${commands[@]}"; do
        echo -e "  ${YELLOW}> ${cmd}${NOCOLOR}"
    done
    echo -e "${GREEN}================================================================${NOCOLOR}"
}

# Checks if a Git remote named 'origin' is configured.
check_remote() {
    git remote -v 2>&1 | grep -q "origin"
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}!! This action requires a remote 'origin' repository, which is not set.${NOCOLOR}"
        read -rp "--> Do you want to set one now? (y/n): " confirm
        if [[ "$confirm" == "y" ]]; then
            read -rp "--> Enter the remote repository URL: " remoteUrl
            if [ -n "$remoteUrl" ]; then
                git remote add origin "$remoteUrl"
                echo -e "${GREEN}--> Remote 'origin' has been set.${NOCOLOR}"
                return 0
            else
                echo -e "${RED}!! URL required. Action canceled.${NOCOLOR}"
                return 1
            fi
        else
            echo -e "${RED}!! Action canceled. A remote is required.${NOCOLOR}"
            return 1
        fi
    fi
    return 0
}

# Checks if current directory is inside a Git repository.
check_git_repo() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${RED}!! Not inside a Git repository. Please initialize or clone one first.${NOCOLOR}"
        return 1
    fi
    return 0
}

# Displays the current branch name as a status line.
show_current_branch() {
    local branch=$(git branch --show-current 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$branch" ]; then
        echo -e "  ${DARK_GRAY}Current branch:${NOCOLOR} ${CYAN}$branch${NOCOLOR}"
        echo -e ""
    fi
}

# Displays the list of available menu options.
show_menu_options() {
    echo -e "${YELLOW}What task would you like to perform?${NOCOLOR}"
    echo -e ""

    echo -e "${GREEN}--- Local Repository ---${NOCOLOR}"
    echo -e "1.  Initialize New Repository (git init)"
    echo -e "2.  Format Terraform Files (terraform fmt)"
    echo -e "3.  Add All and Initial Commit"
    echo -e "4.  Check Repository Status"
    echo -e "5.  Add File and Commit"
    echo -e "6.  Add Folder and Commit"
    echo -e "7.  Add All and Commit"
    echo -e "8.  View Changes / Diff"
    echo -e "9.  Discard Uncommitted Changes"
    echo -e ""

    echo -e "${GREEN}--- Remote and Sync ---${NOCOLOR}"
    echo -e "10. Clone a Repository"
    echo -e "11. Push Changes to Remote"
    echo -e "12. Pull Changes from Remote"
    echo -e "13. Fetch from Remote (no merge)"
    echo -e "14. Manage Pull Requests (GitHub CLI)"
    echo -e "15. Manage Remotes (Sub-Menu)"
    echo -e ""

    echo -e "${GREEN}--- History ---${NOCOLOR}"
    echo -e "16. View Commit Log"
    echo -e "17. Stash Uncommitted Changes"
    echo -e "18. Apply Stashed Changes"
    echo -e ""

    echo -e "${GREEN}--- Advanced Operations ---${NOCOLOR}"
    echo -e "19. Branch Management (Sub-Menu)"
    echo -e "20. Merge a Branch"
    echo -e "21. Rebase Current Branch"
    echo -e "22. Cherry-Pick a Commit"
    echo -e "23. Revert a Commit"
    echo -e "24. Create a Version Tag"
    echo -e ""

    echo -e "25. Exit"
    echo -e ""
}

# --- Sub-Menus ---

# Handles the sub-menu for branch operations with its own persistent loop.
handle_branch_menu() {
    local branchChoice=""
    while true; do
        if [[ -z "$branchChoice" ]]; then
            clear; show_header
            echo -e "${GREEN}--- Branch Management ---${NOCOLOR}"
            echo -e "${WHITE}1. List All Branches${NOCOLOR}"
            echo -e "${WHITE}2. Create and Switch to New Branch${NOCOLOR}"
            echo -e "${WHITE}3. Switch to Existing Branch${NOCOLOR}"
            echo -e "${WHITE}4. Delete a Local Branch${NOCOLOR}"
            echo -e "${WHITE}5. Delete a Remote Branch${NOCOLOR}"
            echo -e "${WHITE}6. Rename Current Branch${NOCOLOR}"
            echo -e "${WHITE}7. Set Upstream Tracking Branch${NOCOLOR}"
            echo -e "${WHITE}8. Return to Main Menu${NOCOLOR}"
            echo -e "${GREEN}-----------------------${NOCOLOR}"
            read -rp "--> Choose a branch option: " branchChoice
        fi

        commandsUsed=() # Reset for sub-menu actions

        case "$branchChoice" in
            1)
                show_explanation "git branch -a" \
                    "Lists all local and remote branches." \
                    "To see what branches are available in your repository." \
                    "Yes — read-only." \
                    "Local branches are white, remote tracking branches are red." \
                    "The currently active branch is marked with an asterisk."
                git branch -a
                commandsUsed+=("git branch -a")
                ;;
            2)
                show_explanation "git checkout -b <new-branch>" \
                    "Creates a new branch and switches to it immediately." \
                    "When starting work on a new feature, bug fix, or experiment." \
                    "Yes — local changes only." \
                    "Use descriptive names like 'feature/login-page' or 'fix/button-bug'." \
                    "Always create new branches from an up-to-date 'main' or 'dev' branch."
                read -rp "--> New branch name (e.g., feature/my-new-feature): " nb
                if [ -n "$nb" ]; then
                    git checkout -b "$nb"
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}--> Created and switched to '$nb'.${NOCOLOR}"
                        commandsUsed+=("git checkout -b $nb")
                    else
                        echo -e "${RED}!! Failed to create/switch branch. Check for uncommitted changes or invalid name.${NOCOLOR}"
                    fi
                else
                    echo -e "${RED}!! Name required.${NOCOLOR}"
                fi
                ;;
            3)
                show_explanation "git checkout <existing-branch>" \
                    "Switches your working directory to another existing branch." \
                    "When you need to work on a different feature or bug, or inspect another branch's code." \
                    "Yes — local changes only, but requires clean working directory or stashing." \
                    "Run 'git status' first to ensure no pending changes will be lost." \
                    "If you have uncommitted changes, you'll need to stash or commit them first."
                echo -e "${WHITE}--> Available branches:${NOCOLOR}"
                git branch -a
                read -rp "--> Switch to branch: " sb
                if [ -n "$sb" ]; then
                    git checkout "$sb"
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}--> Switched to '$sb'.${NOCOLOR}"
                        commandsUsed+=("git checkout $sb")
                    else
                        echo -e "${RED}!! Could not switch. Commit or stash your changes first.${NOCOLOR}"
                    fi
                else
                    echo -e "${RED}!! Name required.${NOCOLOR}"
                fi
                ;;
            4)
                show_explanation "git branch -d <branch-name>" \
                    "Deletes a local branch from your repository." \
                    "When a feature branch has been merged and is no longer needed locally." \
                    "CAREFUL: Deletes local history for that branch. Use '-D' for force delete." \
                    "Only delete branches that are fully merged to avoid losing work." \
                    "You cannot delete the currently active branch."
                echo -e "${WHITE}--> Local branches:${NOCOLOR}"
                git branch
                read -rp "--> Branch to delete (local): " db
                if [ -n "$db" ]; then
                    read -rp "--> Delete '$db'? (y/n): " c
                    if [[ "$c" == "y" ]]; then
                        git branch -d "$db"
                        commandsUsed+=("git branch -d $db")
                        if [ $? -ne 0 ]; then
                            read -rp "--> Not fully merged. Force delete? (y/n): " force
                            if [[ "$force" == "y" ]]; then
                                git branch -D "$db"
                                commandsUsed+=("git branch -D $db")
                            fi
                        fi
                    fi
                else
                    echo -e "${RED}!! Name required.${NOCOLOR}"
                fi
                ;;
            5)
                show_explanation "git push origin --delete <remote-branch>" \
                    "Deletes a branch on the remote repository (e.g., GitHub)." \
                    "When a feature branch has been fully merged and is no longer needed on the remote." \
                    "CAREFUL: Deletes the branch for everyone. Ensure it's not needed." \
                    "Make sure the branch is merged into 'main' before deleting to preserve history."
                if check_remote; then
                    echo -e "${WHITE}--> Remote branches:${NOCOLOR}"
                    git branch -r
                    read -rp "--> Remote branch to delete (e.g., 'your-feature' for 'origin/your-feature'): " rb
                    if [ -n "$rb" ]; then
                        read -rp "--> Delete 'origin/$rb' from remote? (y/n): " c
                        if [[ "$c" == "y" ]]; then
                            git push origin --delete "$rb"
                            echo -e "${GREEN}--> Remote branch '$rb' deleted.${NOCOLOR}"
                            commandsUsed+=("git push origin --delete $rb")
                        fi
                    else
                        echo -e "${RED}!! Name required.${NOCOLOR}"
                    fi
                fi
                ;;
            6)
                show_explanation "git branch -m <new-name>" \
                    "Renames the currently active local branch." \
                    "To correct a typo in a branch name, or update it to reflect new feature scope." \
                    "Yes — local changes only. Remote is unaffected (you'll need to push new name and delete old remote)." \
                    "If you've pushed the old branch to remote, you'll need to push the new name and delete the old remote branch."
                local current_branch=$(git branch --show-current)
                echo -e "${WHITE}--> Current branch:${NOCOLOR} ${CYAN}$current_branch${NOCOLOR}"
                read -rp "--> New name for current branch: " newName
                if [ -n "$newName" ]; then
                    git branch -m "$newName"
                    echo -e "${GREEN}--> Branch renamed to '$newName'.${NOCOLOR}"
                    commandsUsed+=("git branch -m $newName")
                else
                    echo -e "${RED}!! Name required.${NOCOLOR}"
                fi
                ;;
            7)
                show_explanation "git branch --set-upstream-to=<remote>/<branch>" \
                    "Configures your local branch to track a specific remote branch." \
                    "Essential for new local branches before 'git pull' or 'git push' works without specifying remote." \
                    "Yes — local configuration only." \
                    "This links your local branch to its corresponding remote branch, simplifying sync." \
                    "Run this after creating a new local branch and before its first push."
                local current_branch=$(git branch --show-current)
                echo -e "${WHITE}--> Current branch:${NOCOLOR} ${CYAN}$current_branch${NOCOLOR}"
                read -rp "--> Upstream branch to track (e.g., origin/main): " upstream
                if [ -n "$upstream" ]; then
                    git branch --set-upstream-to="$upstream" "$current_branch"
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}--> '$current_branch' now tracks '$upstream'.${NOCOLOR}"
                        commandsUsed+=("git branch --set-upstream-to=$upstream $current_branch")
                    else
                        echo -e "${RED}!! Failed to set upstream. Check remote/branch names.${NOCOLOR}"
                    fi
                else
                    echo -e "${RED}!! Upstream name required.${NOCOLOR}"
                fi
                ;;
            8)
                echo -e "${YELLOW}--> Returning to main menu...${NOCOLOR}"
                return
                ;;
            *)
                echo -e "${RED}!! Invalid branch option: '$branchChoice'. Please try again.${NOCOLOR}"
                ;;
        esac
        show_command_recap "${commandsUsed[@]}" # Show recap after each action
        echo -e "${GREEN}================================================================${NOCOLOR}"
        read -rp "Enter next branch option (1-8) or press [Enter] for menu: " branchChoice
    done
}


# Handles the sub-menu for remote operations.
handle_remote_menu() {
    local remoteChoice=""
    while true; do
        if [[ -z "$remoteChoice" ]]; then
            clear; show_header
            echo -e "${GREEN}--- Remote Management ---${NOCOLOR}"
            echo -e "${WHITE}Current remotes:${NOCOLOR}"
            git remote -v
            echo -e ""
            echo -e "${WHITE}1. Add a Remote${NOCOLOR}"
            echo -e "${WHITE}2. Change Remote URL${NOCOLOR}"
            echo -e "${WHITE}3. Remove a Remote${NOCOLOR}"
            echo -e "${WHITE}4. Show Remote Details${NOCOLOR}"
            echo -e "${WHITE}5. Return to Main Menu${NOCOLOR}"
            echo -e "${GREEN}-----------------------${NOCOLOR}"
            read -rp "--> Choose a remote option: " remoteChoice
        fi

        commandsUsed=() # Reset for sub-menu actions

        case "$remoteChoice" in
            1)
                show_explanation "git remote add <name> <url>" \
                    "Links your local repository to a new remote repository." \
                    "When setting up a new repository or adding another remote source (e.g., 'upstream' for a fork)." \
                    "Yes — local configuration only." \
                    "The name 'origin' is conventional for your primary remote." \
                    "Use HTTPS for simplicity or SSH for key-based authentication."
                read -rp "--> Remote name (e.g., origin or upstream): " name
                read -rp "--> Remote URL: " url
                if [ -n "$name" ] && [ -n "$url" ]; then
                    git remote add "$name" "$url"
                    echo -e "${GREEN}--> Remote '$name' added.${NOCOLOR}"
                    commandsUsed+=("git remote add $name $url")
                else
                    echo -e "${RED}!! Name and URL required.${NOCOLOR}"
                fi
                ;;
            2)
                show_explanation "git remote set-url <name> <new-url>" \
                    "Updates the URL of an existing remote repository." \
                    "If a remote repository's URL changes (e.g., moving from HTTP to SSH)." \
                    "Yes — local configuration only." \
                    "Always verify the new URL is correct to prevent connection issues."
                echo -e "${WHITE}Current remotes:${NOCOLOR}"
                git remote -v
                read -rp "--> Remote name to update (e.g., origin): " name
                read -rp "--> New URL: " url
                if [ -n "$name" ] && [ -n "$url" ]; then
                    git remote set-url "$name" "$url"
                    echo -e "${GREEN}--> Remote '$name' URL updated to: $url${NOCOLOR}"
                    commandsUsed+=("git remote set-url $name $url")
                else
                    echo -e "${RED}!! Name and URL required.${NOCOLOR}"
                fi
                ;;
            3)
                show_explanation "git remote remove <name>" \
                    "Removes a remote link from your local repository." \
                    "When you no longer need to interact with a specific remote repository." \
                    "Yes — local configuration only." \
                    "This only removes the local reference; it does not affect the actual remote repository."
                echo -e "${WHITE}Current remotes:${NOCOLOR}"
                git remote -v
                read -rp "--> Remote name to remove: " name
                if [ -n "$name" ]; then
                    read -rp "--> Remove remote '$name'? (y/n): " c
                    if [[ "$c" == "y" ]]; then
                        git remote remove "$name"
                        echo -e "${GREEN}--> Remote '$name' removed.${NOCOLOR}"
                        commandsUsed+=("git remote remove $name")
                    fi
                else
                    echo -e "${RED}!! Name required.${NOCOLOR}"
                fi
                ;;
            4)
                show_explanation "git remote show <name>" \
                    "Displays detailed information about a specific remote repository." \
                    "To check the remote's URL, branches it tracks, and related settings." \
                    "Yes — read-only." \
                    "Provides insights into fetch/push URLs, local tracking branches, and untracked remote branches."
                read -rp "--> Remote name (e.g., origin): " name
                if [ -n "$name" ]; then
                    git remote show "$name"
                    commandsUsed+=("git remote show $name")
                else
                    echo -e "${RED}!! Name required.${NOCOLOR}"
                fi
                ;;
            5)
                echo -e "${YELLOW}--> Returning to main menu...${NOCOLOR}"
                return
                ;;
            *)
                echo -e "${RED}!! Invalid option: '$remoteChoice'. Please try again.${NOCOLOR}"
                ;;
        esac
        show_command_recap "${commandsUsed[@]}"
        echo -e "${GREEN}================================================================${NOCOLOR}"
        read -rp "Enter next remote option (1-5) or press [Enter] for menu: " remoteChoice
    done
}

# --- Pull Request (GitHub CLI) Menu ---
handle_pr_menu() {
    local prChoice=""
    if ! command -v gh >/dev/null; then
        clear; show_header
        echo -e "${RED}!! GitHub CLI (gh) not found.${NOCOLOR}"
        echo -e "${WHITE}To use Pull Request features, please install GitHub CLI:${NOCOLOR}"
        echo -e "${DARK_GRAY}• Instructions: https://cli.github.com/${NOCOLOR}"
        echo -e "${DARK_GRAY}• After install, run: gh auth login${NOCOLOR}"
        read -rp "--> Press Enter to return to the main menu: "
        return
    fi

    local current_repo=$(git remote get-url origin 2>/dev/null | sed -n 's/.*github.com[:/]\([^/]*\)\/\(.*\)\.git/\1\/\2/p')
    if [[ -z "$current_repo" ]]; then
        echo -e "${RED}!! Not a GitHub repository (origin remote not found or invalid URL).${NOCOLOR}"
        read -rp "--> Press Enter to return to the main menu: "
        return
    fi

    while true; do
        if [[ -z "$prChoice" ]]; then
            clear; show_header
            echo -e "${GREEN}--- Pull Request Management (${current_repo}) ---${NOCOLOR}"
            echo -e "${WHITE}1. Create a New Pull Request${NOCOLOR}"
            echo -e "${WHITE}2. List Open Pull Requests${NOCOLOR}"
            echo -e "${WHITE}3. View a Pull Request${NOCOLOR}"
            echo -e "${WHITE}4. Merge a Pull Request${NOCOLOR}"
            echo -e "${WHITE}5. Check out a Pull Request Locally${NOCOLOR}"
            echo -e "${WHITE}6. Return to Main Menu${NOCOLOR}"
            echo -e "${GREEN}-----------------------${NOCOLOR}"
            read -rp "--> Choose a PR option: " prChoice
        fi

        commandsUsed=() # Reset for sub-menu actions

        case "$prChoice" in
            1)
                show_explanation "gh pr create" \
                    "Creates a new Pull Request on GitHub from your current branch." \
                    "When you have completed a feature or fix on a branch and want it reviewed and merged." \
                    "Yes — proposes changes, doesn't directly alter 'main' branch." \
                    "Always create PRs from a well-named feature branch (e.g., 'feature/my-new-feature')." \
                    "Ensure your branch is pushed to remote before creating the PR." \
                    "You will be prompted for title, body, and base branch."
                gh pr create
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}--> Pull Request created successfully.${NOCOLOR}"
                    commandsUsed+=("gh pr create")
                else
                    echo -e "${RED}!! Failed to create Pull Request. Ensure 'gh auth login' is done and branch is pushed.${NOCOLOR}"
                fi
                ;;
            2)
                show_explanation "gh pr list" \
                    "Lists all open Pull Requests for the current repository on GitHub." \
                    "To quickly see what changes are awaiting review or are currently in progress." \
                    "Yes — read-only." \
                    "Shows PR number, title, and author. Filter with '--state merged' or '--state closed'."
                gh pr list
                commandsUsed+=("gh pr list")
                ;;
            3)
                show_explanation "gh pr view <number>" \
                    "Displays details of a specific Pull Request from GitHub." \
                    "To review a teammate's changes, check comments, or see CI/CD status on a PR." \
                    "Yes — read-only." \
                    "Use the PR number (e.g., '123') to view its details." \
                    "You can also specify a branch name instead of a number for open PRs."
                read -rp "--> Pull Request number or branch name: " prNum
                if [ -n "$prNum" ]; then
                    gh pr view "$prNum"
                    commandsUsed+=("gh pr view $prNum")
                else
                    echo -e "${RED}!! PR number or branch name required.${NOCOLOR}"
                fi
                ;;
            4)
                show_explanation "gh pr merge <number>" \
                    "Merges a Pull Request from GitHub into the base branch (usually 'main')." \
                    "When a Pull Request has been approved and is ready to be integrated into the main codebase." \
                    "CAREFUL: This is a destructive action that alters the base branch's history." \
                    "Ensure all tests pass and team approval before merging." \
                    "Use '--merge', '--squash', or '--rebase' for different merge strategies."
                read -rp "--> Pull Request number to merge: " prNum
                if [ -n "$prNum" ]; then
                    echo -e "${WHITE}Choose merge strategy:${NOCOLOR}"
                    echo -e "a. Merge commit (default) — Preserves all commits in history."
                    echo -e "b. Squash and merge — Squashes all PR commits into a single commit on base branch."
                    echo -e "c. Rebase and merge — Rebases PR commits on top of base, keeping linear history (no merge commit)."
                    read -rp "--> Choice (a/b/c, default is a): " mergeStrategy
                    mergeCmd=""
                    case "$mergeStrategy" in
                        b) mergeCmd="--squash" ;;
                        c) mergeCmd="--rebase" ;;
                        *) mergeCmd="--merge" ;;
                    esac
                    
                    gh pr merge "$prNum" "$mergeCmd"
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}--> Pull Request merged successfully.${NOCOLOR}"
                        commandsUsed+=("gh pr merge $prNum $mergeCmd")
                    else
                        echo -e "${RED}!! Failed to merge Pull Request. Check conflicts or current branch.${NOCOLOR}"
                    fi
                else
                    echo -e "${RED}!! PR number required.${NOCOLOR}"
                fi
                ;;
            5)
                show_explanation "gh pr checkout <number>" \
                    "Checks out a Pull Request from GitHub as a local branch." \
                    "To test a PR's changes locally before approving, or work on it directly." \
                    "Yes — local changes only." \
                    "Creates a new local branch named after the PR, allowing you to inspect code and run tests."
                read -rp "--> Pull Request number to checkout: " prNum
                if [ -n "$prNum" ]; then
                    gh pr checkout "$prNum"
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}--> Checked out PR #$prNum locally.${NOCOLOR}"
                        commandsUsed+=("gh pr checkout $prNum")
                    else
                        echo -e "${RED}!! Failed to checkout PR. Ensure 'gh auth login' or correct PR number.${NOCOLOR}"
                    fi
                else
                    echo -e "${RED}!! PR number required.${NOCOLOR}"
                fi
                ;;
            6)
                echo -e "${YELLOW}--> Returning to main menu...${NOCOLOR}"
                return
                ;;
            *)
                echo -e "${RED}!! Invalid PR option: '$prChoice'. Please try again.${NOCOLOR}"
                ;;
        esac
        show_command_recap "${commandsUsed[@]}"
        echo -e "${GREEN}================================================================${NOCOLOR}"
        read -rp "Enter next PR option (1-6) or press [Enter] for menu: " prChoice
    done
}


# --- Main Script Logic ---
choice=""
while true; do
    if [[ -z "$choice" ]]; then
        clear; show_header; show_current_branch; show_menu_options
        read -rp "--> Choose an option (1-25): " choice
    fi

    commandsUsed=() # Reset for main menu actions

    case "$choice" in
        1)
            show_explanation "git init" \
                "Initializes a new empty Git repository in the current directory." \
                "When starting a brand new project that you want to track with Git." \
                "Yes — creates a hidden .git folder, nothing else on remote is changed." \
                "Run this in the root folder of your new project." \
                "Do not initialize a Git repository inside another existing Git repository." \
                "Git automatically adds a hidden '.git' subfolder to store its history."
            read -rp "--> Initialize here? (y/n): " c
            if [[ "$c" == "y" ]]; then
                if [ -d ".git" ]; then
                    echo -e "${YELLOW}!! Already a Git repository.${NOCOLOR}"
                else
                    git init
                    echo -e "${GREEN}--> Repository initialized.${NOCOLOR}"
                    commandsUsed+=("git init")
                fi
            fi
            ;;
        2)
            show_explanation "terraform fmt -recursive" \
                "Formats all Terraform (.tf) configuration files to a canonical, consistent style." \
                "Always run this before committing Terraform code to ensure consistent formatting." \
                "Yes — only reformats whitespace and indentation, does not change logic." \
                "Requires 'terraform' CLI to be installed and available in your PATH." \
                "Run from the root directory of your Terraform module." \
                "Use 'terraform fmt -check' to just validate formatting without applying changes."
            if command -v terraform &>/dev/null; then
                terraform fmt -recursive
                echo -e "${GREEN}--> Terraform files formatted.${NOCOLOR}"
                commandsUsed+=("terraform fmt -recursive")
            else
                echo -e "${RED}Warning: Terraform CLI not found. Please install it to use this option.${NOCOLOR}"
            fi
            ;;
        3)
            show_explanation "git add . && git commit -m \"Initial commit\"" \
                "Stages all current files in the repository and creates the very first commit." \
                "Once after initializing a new repository, to save the initial state of your project." \
                "Yes — creates local history. No remote changes." \
                "This is the foundation of your project's version control history." \
                "Ensure all desired files are in the directory before the initial commit." \
                "Future commits will build upon this initial snapshot."
            read -rp "--> Stage all files and create initial commit? (y/n): " c
            if [[ "$c" == "y" ]]; then
                git add .
                read -rp "--> Initial commit message (default: 'Initial commit'): " message
                if [[ -z "$message" ]]; then
                    message="Initial commit"
                fi
                git commit -m "$message"
                echo -e "${GREEN}--> Initial commit created.${NOCOLOR}"
                commandsUsed+=("git add .")
                commandsUsed+=("git commit -m \"$message\"")
            fi
            ;;
        4)
            show_explanation "git status" \
                "Shows the current state of your working directory, staging area, and untracked files." \
                "Use anytime to get an overview of what changes are present, staged, or yet to be tracked." \
                "Yes — read-only, purely informative." \
                "Run this frequently, especially before adding or committing changes, to orient yourself." \
                "Files in red are modified but not staged; files in green are staged and ready for commit." \
                "'??' indicates untracked files that Git is currently ignoring."
            git status
            commandsUsed+=("git status")
            ;;
        5)
            show_explanation "git add <file> && git commit -m \"Message\"" \
                "Stages a specific file to be included in the next commit and then commits it." \
                "For focused, single-file changes that logically belong together in one commit." \
                "Yes — commits changes locally. No remote changes until 'git push'." \
                "Use tab completion for file paths to avoid typos." \
                "The commit message should explain the 'why' behind the change, not just the 'what'." \
                "Only stage and commit files related to a single, logical change."
            git status
            echo -e ""
            read -rp "--> Enter file name/path to add: " fileName
            if [ -n "$fileName" ]; then
                read -rp "--> Commit message: " message
                if [[ -z "$message" ]]; then
                    message="Update $fileName"
                fi
                git add "$fileName"
                git commit -m "$message"
                echo -e "${GREEN}--> File '$fileName' committed.${NOCOLOR}"
                commandsUsed+=("git add $fileName")
                commandsUsed+=("git commit -m \"$message\"")
            else
                echo -e "${RED}!! File name/path required.${NOCOLOR}"
            fi
            ;;
        6)
            show_explanation "git add <folder> && git commit -m \"Message\"" \
                "Stages all files within a specific folder to be included in the next commit and then commits them." \
                "When a feature or bug fix primarily involves multiple files within a single directory." \
                "Yes — commits changes locally. No remote changes until 'git push'." \
                "Git tracks files, not empty folders. An empty folder cannot be added." \
                "Trailing slash not needed for folder paths (e.g., 'src/components' is fine)." \
                "Ensure all changes within the folder are intended for this specific commit."
            read -rp "--> Enter folder path to add: " folderName
            if [ -n "$folderName" ]; then
                read -rp "--> Commit message: " message
                if [[ -z "$message" ]]; then
                    message="Update folder $folderName"
                fi
                git add "$folderName"
                git commit -m "$message"
                echo -e "${GREEN}--> Folder '$folderName' committed.${NOCOLOR}"
                commandsUsed+=("git add $folderName")
                commandsUsed+=("git commit -m \"$message\"")
            else
                echo -e "${RED}!! Folder path required.${NOCOLOR}"
            fi
            ;;
        7)
            show_explanation "git add . && git commit -m \"Message\"" \
                "Stages all modified, new, and deleted files in the repository and then commits them." \
                "For broader changes across multiple files or when finishing a distinct logical unit of work." \
                "Yes — commits changes locally. No remote changes until 'git push'." \
                "Always run 'git status' immediately before 'git add .' to review exactly what will be committed." \
                "Avoid committing unrelated or incomplete changes together; keep commits focused." \
                "A descriptive commit message is crucial for understanding the collective changes."
            git status
            echo -e ""
            read -rp "--> Commit message (default: 'General update'): " message
            if [[ -z "$message" ]]; then
                message="General update"
            fi
            git add .
            git commit -m "$message"
            echo -e "${GREEN}--> All changes committed.${NOCOLOR}"
            commandsUsed+=("git add .")
            commandsUsed+=("git commit -m \"$message\"")
            ;;
        8)
            show_explanation "git diff" \
                "Displays line-by-line changes between different states of your repository (e.g., working directory vs. staged, or two branches)." \
                "Use before committing to review your own work, or to understand changes between branches." \
                "Yes — read-only, purely informative." \
                "Press 'q' to exit the diff view (it uses a pager like 'less')." \
                "Lines in red with a '-' are removed; lines in green with a '+' are added." \
                "'git diff --staged' shows changes in the staging area that are ready to be committed."
            echo -e "${YELLOW}a. Unstaged changes (working tree)${NOCOLOR}"
            echo -e "${WHITE}b. Staged changes (ready to commit)${NOCOLOR}"
            echo -e "${WHITE}c. Compare two branches${NOCOLOR}"
            read -rp "--> Choose: " diffChoice
            case "$diffChoice" in
                a)
                    git diff
                    commandsUsed+=("git diff")
                    ;;
                b)
                    git diff --staged
                    commandsUsed+=("git diff --staged")
                    ;;
                c)
                    git branch -a; echo -e ""
                    read -rp "--> First branch: " b1
                    read -rp "--> Second branch: " b2
                    if [ -n "$b1" ] && [ -n "$b2" ]; then
                        git diff "${b1}..${b2}"
                        commandsUsed+=("git diff ${b1}..${b2}")
                    else
                        echo -e "${RED}!! Both branch names required.${NOCOLOR}"
                    fi
                    ;;
                *)
                    echo -e "${RED}!! Invalid option.${NOCOLOR}"
                    ;;
            esac
            ;;
        9)
            show_explanation "git checkout -- <file> / git reset HEAD <file>" \
                "Discards unwanted changes in your working directory or unstages files from the staging area." \
                "Use when you've made accidental changes you want to revert, or staged a file by mistake." \
                "CAREFUL: Discarded changes CANNOT be recovered. Use 'git stash' if unsure." \
                "Always run 'git status' first to clearly understand what changes will be affected." \
                "Discarding changes in the working tree is irreversible if not stashed." \
                "'git reset HEAD <file>' unstages a file but keeps the changes in your working directory."
            git status; echo -e ""
            echo -e "${YELLOW}a. Discard ALL uncommitted changes${NOCOLOR}"
            echo -e "${WHITE}b. Discard changes in a specific file${NOCOLOR}"
            echo -e "${WHITE}c. Unstage a file (keep changes, remove from staging only)${NOCOLOR}"
            read -rp "--> Choose: " discardChoice
            case "$discardChoice" in
                a)
                    read -rp "--> This will DISCARD ALL uncommitted changes. Are you sure? (y/n): " c
                    if [[ "$c" == "y" ]]; then
                        git checkout -- .
                        echo -e "${GREEN}--> All uncommitted changes discarded.${NOCOLOR}"
                        commandsUsed+=("git checkout -- .")
                    fi
                    ;;
                b)
                    read -rp "--> File path to discard changes in: " fn
                    if [ -n "$fn" ]; then
                        git checkout -- "$fn"
                        echo -e "${GREEN}--> Changes in '$fn' discarded.${NOCOLOR}"
                        commandsUsed+=("git checkout -- $fn")
                    else
                        echo -e "${RED}!! File path required.${NOCOLOR}"
                    fi
                    ;;
                c)
                    git diff --staged --name-only; echo -e ""
                    read -rp "--> File to unstage: " fn
                    if [ -n "$fn" ]; then
                        git reset HEAD "$fn"
                        echo -e "${GREEN}--> '$fn' unstaged (changes preserved in working tree).${NOCOLOR}"
                        commandsUsed+=("git reset HEAD $fn")
                    else
                        echo -e "${RED}!! File name required.${NOCOLOR}"
                    fi
                    ;;
                *)
                    echo -e "${RED}!! Invalid option.${NOCOLOR}"
                    ;;
            esac
            ;;
        10)
            show_explanation "git clone <repo-url> [directory]" \
                "Downloads a remote repository to your local machine, creating a new directory." \
                "When starting work on an existing project for the first time, or getting a fresh copy." \
                "Yes — read-only, nothing on the remote repository is changed." \
                "URL format: 'https://github.com/user/repo.git' (HTTPS) or 'git@github.com:user/repo.git' (SSH)." \
                "After cloning, navigate into the new project folder (e.g., 'cd repo-name') and install dependencies." \
                "For private repositories, ensure you are authenticated (via 'gh auth login' or configured SSH key)." \
                "Use '--depth 1' for a shallow clone to download only the latest commit, saving bandwidth and time."
            read -rp "--> Repository URL to clone: " repoUrl
            if [ -n "$repoUrl" ]; then
                read -rp "--> Local folder name (leave blank for repository name): " cloneDir
                if [ -n "$cloneDir" ]; then
                    git clone "$repoUrl" "$cloneDir"
                    commandsUsed+=("git clone $repoUrl $cloneDir")
                else
                    git clone "$repoUrl"
                    commandsUsed+=("git clone $repoUrl")
                fi
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}--> Repository cloned successfully.${NOCOLOR}"
                    if [ -n "$cloneDir" ]; then
                        read -rp "--> Change directory into '$cloneDir'? (y/n): " goIn
                        if [[ "$goIn" == "y" ]]; then
                            pushd "$cloneDir" >/dev/null # Use pushd for easy popd later
                            commandsUsed+=("cd $cloneDir")
                            echo -e "${GREEN}--> Now in: $(pwd)${NOCOLOR}"
                        fi
                    fi
                else
                    echo -e "${RED}!! Failed to clone repository. Check URL or network connection.${NOCOLOR}"
                fi
            else
                echo -e "${RED}!! Repository URL required.${NOCOLOR}"
            fi
            ;;
        11)
            show_explanation "git push [options]" \
                "Uploads your local commits to the remote repository, sharing your work with others." \
                "After you have committed changes locally and are ready to update the remote version." \
                "CAREFUL: '--force' rewrites history and can cause issues for collaborators." \
                "Always run 'git pull' before pushing to ensure you have the latest changes and avoid conflicts." \
                "Use '-u origin <branch>' (or '--set-upstream origin <branch>') for the first push of a new branch." \
                "If pushing to a different branch on the remote, specify both local and remote branches (e.g., 'git push origin local:remote')."
            if check_remote; then
                currentBranch=$(git branch --show-current)
                echo -e "${WHITE}--> Current branch:${NOCOLOR} ${CYAN}$currentBranch${NOCOLOR}"
                echo -e "${WHITE}a. Push current branch to origin/$currentBranch${NOCOLOR}"
                echo -e "${WHITE}b. Push and set upstream (first push of new branch)${NOCOLOR}"
                echo -e "${WHITE}c. Force push (rewrites remote history — use with extreme caution!)${NOCOLOR}"
                read -rp "--> Choose (or press [Enter] for default push 'a'): " pushChoice
                case "$pushChoice" in
                    b)
                        git push --set-upstream origin "$currentBranch"
                        echo -e "${GREEN}--> Pushed and upstream set for '$currentBranch'.${NOCOLOR}"
                        commandsUsed+=("git push --set-upstream origin $currentBranch")
                        ;;
                    c)
                        read -rp "--> Force push to origin/$currentBranch? This rewrites remote history. Are you sure? (y/n): " conf
                        if [[ "$conf" == "y" ]]; then
                            git push --force origin "$currentBranch"
                            echo -e "${YELLOW}--> Force pushed to origin/$currentBranch.${NOCOLOR}"
                            commandsUsed+=("git push --force origin $currentBranch")
                        fi
                        ;;
                    *) # Default to option 'a'
                        read -rp "--> Push to origin/$currentBranch? (y/n): " c
                        if [[ "$c" == "y" ]]; then
                            git push origin "$currentBranch"
                            echo -e "${GREEN}--> Pushed to origin/$currentBranch.${NOCOLOR}"
                            commandsUsed+=("git push origin $currentBranch")
                        fi
                        ;;
                esac
            fi
            ;;
        12)
            show_explanation "git pull origin <branch>" \
                "Downloads and immediately merges the latest remote changes into your current local branch." \
                "Use to synchronize your local repository with updates from the remote, especially when collaborating." \
                "Yes — updates local code, but may create merge conflicts if local changes diverge from remote." \
                "It's a combination of 'git fetch' (download) and 'git merge' (integrate)." \
                "Always 'git pull' before starting new work each day to base your changes on the latest version." \
                "If conflicts occur, you'll need to manually resolve them in your editor before committing the merge."
            if check_remote; then
                currentBranch=$(git branch --show-current)
                read -rp "--> Pull from origin/$currentBranch? (y/n): " c
                if [[ "$c" == "y" ]]; then
                    git pull origin "$currentBranch"
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}--> Pulled latest changes from origin/$currentBranch.${NOCOLOR}"
                        commandsUsed+=("git pull origin $currentBranch")
                    else
                        echo -e "${RED}!! Pull failed. Resolve conflicts or check remote connection.${NOCOLOR}"
                    fi
                fi
            fi
            ;;
        13)
            show_explanation "git fetch [remote]" \
                "Downloads remote changes (commits, files, refs) to your local repository, but DOES NOT merge them." \
                "Use to see what new work is available on the remote without altering your current local working copy." \
                "Yes — read-only, your local code and branch remain untouched." \
                "Allows you to preview remote changes (e.g., 'git log origin/main') before deciding to merge them." \
                "Use '--prune' to remove any remote-tracking references that no longer exist on the remote." \
                "This is safer than 'git pull' when you want to inspect changes before integrating."
            if check_remote; then
                echo -e "${WHITE}a. Fetch all remotes (+ prune stale tracking branches)${NOCOLOR}"
                echo -e "${WHITE}b. Fetch a specific remote${NOCOLOR}"
                read -rp "--> Choose: " fetchChoice
                case "$fetchChoice" in
                    b)
                        read -rp "--> Remote name (e.g., origin): " remoteName
                        if [ -n "$remoteName" ]; then
                            git fetch "$remoteName" --prune
                            echo -e "${GREEN}--> Fetched from '$remoteName'.${NOCOLOR}"
                            commandsUsed+=("git fetch $remoteName --prune")
                        else
                            echo -e "${RED}!! Remote name required.${NOCOLOR}"
                        fi
                        ;;
                    *) # Default to option 'a'
                        git fetch --all --prune
                        echo -e "${GREEN}--> Fetched all remotes. Use 'git log origin/main' to inspect before merging.${NOCOLOR}"
                        commandsUsed+=("git fetch --all --prune")
                        ;;
                esac
            fi
            ;;
        14)
            handle_pr_menu # Calls the GitHub CLI PR management sub-menu
            choice="" # Clear choice to show main menu after returning from sub-menu
            ;;
        15)
            handle_remote_menu # Calls the remote management sub-menu
            choice="" # Clear choice to show main menu after returning from sub-menu
            ;;
        16)
            show_explanation "git log [options]" \
                "Displays the commit history of your repository or specific branches." \
                "To review past changes, find specific commits, or understand branch evolution." \
                "Yes — read-only, purely informative." \
                "Options like '--oneline' (compact) and '--graph' (visual branch structure) are very useful." \
                "Press 'q' to exit the log viewer (it uses a pager like 'less')." \
                "Each commit has a unique, cryptographic hash that identifies it."
            echo -e "${WHITE}a. Graph view (default)${NOCOLOR}"
            echo -e "${WHITE}b. Full detailed log${NOCOLOR}"
            echo -e "${WHITE}c. Compact one-line log${NOCOLOR}"
            read -rp "--> Choose (or [Enter] for graph view 'a'): " logChoice
            case "$logChoice" in
                b)
                    git log -10
                    commandsUsed+=("git log -10")
                    ;;
                c)
                    git log --oneline -20
                    commandsUsed+=("git log --oneline -20")
                    ;;
                *) # Default to graph view 'a'
                    git log --oneline --graph -15
                    commandsUsed+=("git log --oneline --graph -15")
                    ;;
            esac
            ;;
        17)
            show_explanation "git stash [push -m \"Message\"]" \
                "Temporarily saves your uncommitted changes (both staged and unstaged) to a separate area." \
                "Use when you need to switch branches urgently but aren't ready to commit your current work." \
                "Yes — moves changes to a temporary storage, making your working directory clean." \
                "Stash acts like a stack (Last-In, First-Out); the latest stash is at index 0." \
                "Give your stashes descriptive names (e.g., 'git stash push -m \"wip: login page\"') for clarity." \
                "'git stash list' shows all currently saved stashes."
            read -rp "--> Stash description (optional, e.g., 'wip: login page'): " stashMessage
            if [ -n "$stashMessage" ]; then
                git stash push -m "$stashMessage"
                commandsUsed+=("git stash push -m \"$stashMessage\"")
            else
                git stash
                commandsUsed+=("git stash")
            fi
            echo -e "${GREEN}--> Changes stashed.${NOCOLOR}"
            ;;
        18)
            show_explanation "git stash pop / git stash apply" \
                "Restores previously stashed changes back into your working directory." \
                "Use after switching back to the branch where you originally stashed work, to resume development." \
                "Yes — restores files, but may lead to conflicts if the branch has significantly changed." \
                "'git stash pop' applies the latest stash and then removes it from the stash list." \
                "'git stash apply' applies the latest stash but keeps it in the stash list (useful for applying to multiple branches)." \
                "If conflicts occur, you'll need to resolve them manually."
            git stash list; echo -e ""
            echo -e "${WHITE}a. Apply latest stash (keep in list)${NOCOLOR}"
            echo -e "${WHITE}b. Pop latest stash (apply and remove)${NOCOLOR}"
            echo -e "${WHITE}c. Apply a specific stash by index (e.g., '0' for stash@{0})${NOCOLOR}"
            read -rp "--> Choose (or [Enter] for 'b' pop latest): " stashChoice
            case "$stashChoice" in
                a)
                    git stash apply
                    echo -e "${GREEN}--> Stash applied (still in list).${NOCOLOR}"
                    commandsUsed+=("git stash apply")
                    ;;
                c)
                    read -rp "--> Stash index (e.g., 0 for stash@{0}): " idx
                    if [ -n "$idx" ]; then
                        git stash apply "stash@{$idx}"
                        echo -e "${GREEN}--> Stash index $idx applied.${NOCOLOR}"
                        commandsUsed+=("git stash apply stash@{$idx}")
                    else
                        echo -e "${RED}!! Stash index required.${NOCOLOR}"
                    fi
                    ;;
                *) # Default to pop latest stash 'b'
                    read -rp "--> Apply and remove latest stash? (y/n): " c
                    if [[ "$c" == "y" ]]; then
                        git stash pop
                        echo -e "${GREEN}--> Stash popped (removed from list).${NOCOLOR}"
                        commandsUsed+=("git stash pop")
                    fi
                    ;;
            esac
            ;;
        19)
            handle_branch_menu # Calls the branch management sub-menu
            choice="" # Clear choice to show main menu after returning from sub-menu
            ;;
        20)
            show_explanation "git merge <branch-to-merge>" \
                "Combines changes from another branch into your current active branch." \
                "Use after a feature branch is complete and has been reviewed, to integrate its changes into 'main'." \
                "CAREFUL: Can create merge conflicts if changes diverge. Rewrites history with a merge commit." \
                "Always 'git pull' the latest changes from the base branch (e.g., 'main') before merging." \
                "After the merge, you can delete the merged feature branch if it's no longer needed." \
                "'git merge --abort' can be used to cancel a merge with conflicts."
            currentBranch=$(git branch --show-current)
            echo -e "${WHITE}--> Current branch:${NOCOLOR} ${CYAN}$currentBranch${NOCOLOR}"
            git branch; echo -e ""
            read -rp "--> Branch to merge into '$currentBranch': " branchName
            if [ -n "$branchName" ]; then
                read -rp "--> Merge '$branchName' into '$currentBranch'? (y/n): " c
                if [[ "$c" == "y" ]]; then
                    git merge "$branchName"
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}--> '$branchName' merged into '$currentBranch' successfully.${NOCOLOR}"
                        commandsUsed+=("git merge $branchName")
                    else
                        echo -e "${RED}!! Merge conflict detected. Resolve conflicts then run: git merge --continue${NOCOLOR}"
                    fi
                fi
            else
                echo -e "${RED}!! Branch name required.${NOCOLOR}"
            fi
            ;;
        21)
            show_explanation "git rebase <base-branch>" \
                "Replays your local commits on top of another branch's latest history." \
                "Use for a cleaner, linear commit history, avoiding extra merge commits." \
                "CAREFUL: Rewrites commit hashes. NEVER rebase shared/public branches." \
                "Best used on your private feature branches before merging into a public branch." \
                "If conflicts occur, resolve them and then 'git rebase --continue'." \
                "'git rebase --abort' can be used to cancel an ongoing rebase."
            git branch; echo -e ""
            read -rp "--> Branch to rebase current branch onto: " branchName
            if [ -n "$branchName" ]; then
                read -rp "--> Rebase current branch onto '$branchName'? This rewrites history. (y/n): " c
                if [[ "$c" == "y" ]]; then
                    git rebase "$branchName"
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}--> Rebase complete.${NOCOLOR}"
                        commandsUsed+=("git rebase $branchName")
                    else
                        echo -e "${RED}!! Rebase conflict. Resolve conflicts then run: git rebase --continue${NOCOLOR}"
                    fi
                fi
            else
                echo -e "${RED}!! Branch name required.${NOCOLOR}"
            fi
            ;;
        22)
            show_explanation "git cherry-pick <commit-hash>" \
                "Applies a specific commit from any branch onto your current active branch." \
                "Use to port a small bug fix or a single feature commit to another branch without merging the entire branch." \
                "Yes — copies specific changes. Can create conflicts if target branch changed." \
                "Use 'git log --oneline' to find the 7-character short commit hash." \
                "You can cherry-pick multiple commits in sequence." \
                "If conflicts occur, resolve them and then 'git cherry-pick --continue'."
            git log --oneline -20; echo -e ""
            read -rp "--> Commit hash to cherry-pick: " commitHash
            if [ -n "$commitHash" ]; then
                read -rp "--> Cherry-pick '$commitHash'? (y/n): " c
                if [[ "$c" == "y" ]]; then
                    git cherry-pick "$commitHash"
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}--> Commit cherry-picked successfully.${NOCOLOR}"
                        commandsUsed+=("git cherry-pick $commitHash")
                    else
                        echo -e "${RED}!! Cherry-pick conflict. Resolve then run: git cherry-pick --continue${NOCOLOR}"
                    fi
                fi
            else
                echo -e "${RED}!! Commit hash required.${NOCOLOR}"
            fi
            ;;
        23)
            show_explanation "git revert <commit-hash>" \
                "Creates a NEW commit that undoes the changes introduced by a previous commit." \
                "Use to safely undo changes on a shared branch without rewriting history." \
                "Yes — creates a new commit. Safer than 'git reset' for shared history." \
                "Use 'git log --oneline' to find the commit hash you want to undo." \
                "This action does not erase history; it adds a new commit that reverses a previous one." \
                "The '--no-edit' flag skips opening the commit message editor for the revert commit."
            git log --oneline -20; echo -e ""
            read -rp "--> Commit hash to revert: " commitHash
            if [ -n "$commitHash" ]; then
                read -rp "--> This creates a new revert commit. Continue? (y/n): " c
                if [[ "$c" == "y" ]]; then
                    git revert "$commitHash" --no-edit
                    echo -e "${GREEN}--> Commit reverted.${NOCOLOR}"
                    commandsUsed+=("git revert $commitHash --no-edit")
                fi
            else
                echo -e "${RED}!! Commit hash required.${NOCOLOR}"
            fi
            ;;
        24)
            show_explanation "git tag [-a] <tag-name> [-m \"Message\"]" \
                "Marks a specific point in your commit history with a version label (e.g., 'v1.0.0')." \
                "Use when releasing a new version of your software to create a permanent, easy-to-reference snapshot." \
                "Yes — creates a pointer to a commit. No history rewrite." \
                "Annotated tags ('-a') include a message, author, and date; lightweight tags do not." \
                "Push tags separately to the remote: 'git push origin <tag-name>' or 'git push origin --tags'." \
                "Follow semantic versioning (e.g., 'v1.0.0', 'v1.0.1-beta')."
            read -rp "--> Tag name (e.g., v1.0.0): " tagName
            if [ -n "$tagName" ]; then
                read -rp "--> Tag message (leave blank for lightweight tag): " tagMessage
                if [ -n "$tagMessage" ]; then
                    git tag -a "$tagName" -m "$tagMessage"
                    echo -e "${GREEN}--> Annotated tag '$tagName' created.${NOCOLOR}"
                    commandsUsed+=("git tag -a $tagName -m \"$tagMessage\"")
                else
                    git tag "$tagName"
                    echo -e "${GREEN}--> Lightweight tag '$tagName' created.${NOCOLOR}"
                    commandsUsed+=("git tag $tagName")
                fi
                read -rp "--> Push tag '$tagName' to remote? (y/n): " pushTag
                if [[ "$pushTag" == "y" ]]; then
                    git push origin "$tagName"
                    echo -e "${GREEN}--> Tag '$tagName' pushed to remote.${NOCOLOR}"
                    commandsUsed+=("git push origin $tagName")
                fi
            else
                echo -e "${RED}!! Tag name required.${NOCOLOR}"
            fi
            ;;
        25)
            echo -e "${YELLOW}Goodbye! Exiting Git Assistant.${NOCOLOR}"
            break
            ;;
        *)
            echo -e "${RED}!! Invalid option: '$choice'. Please choose a number from the menu.${NOCOLOR}"
            ;;
    esac

    # Show command recap and prompt for next action (main menu)
    # Only if we didn't just exit a sub-menu or the script itself
    if [[ "$choice" != "14" && "$choice" != "15" && "$choice" != "19" && "$choice" != "25" ]]; then
        show_command_recap "${commandsUsed[@]}"
        echo -e "${GREEN}================================================================${NOCOLOR}"
        read -rp "Enter next option (1-25) or press [Enter] for menu: " choice
    fi
done
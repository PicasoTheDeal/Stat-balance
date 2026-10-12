#!/bin/bash
set -e

rand_range() {
    local min=$1
    local max=$2
    echo $((RANDOM % (max - min + 1) + min))
}

ISSUES_COUNT=$(rand_range 2 5)
PR_COUNT=$(rand_range 2 5)
REVIEW_COUNT=$(rand_range 2 4)

gh pr list --state open --limit 300 --json number --jq '.[].number' | while read pr; do
    gh pr close "$pr" --comment "Auto-closing to balance graph." || true
    sleep 2
done

git fetch -p || true
git branch -r | grep 'origin/auto-pr' | sed 's/origin\///' | while read branch; do
    git push origin --delete "$branch" || true
    sleep 2
done

for ((i=1; i<=ISSUES_COUNT; i++)); do
    GH_TOKEN="$SECONDARY_PAT" gh issue create --title "Automated Task #$RANDOM" --body "Routine profile balancing issue." || true
    sleep 2
done

BRANCH_NAME="auto-balancer-$(date +%Y%m%d)"

git checkout main || true
git pull origin main || true
git checkout -b "$BRANCH_NAME" || git checkout "$BRANCH_NAME"

for ((i=1; i<=PR_COUNT; i++)); do
    echo "Log entry $i" >> balance.log
    git add balance.log
    git commit -m "chore: auto update $i"
done

git push origin "$BRANCH_NAME" --force || true

GH_TOKEN="$SECONDARY_PAT" gh pr create --title "Auto PR - $(date +%Y-%m-%d)" --body "Automated pull request to balance graph." --base main || true

open_prs=($(gh pr list --state open --json number --jq '.[].number'))

if [ ${#open_prs[@]} -gt 0 ]; then
    for ((i=1; i<=REVIEW_COUNT; i++)); do
        random_pr=${open_prs[RANDOM % ${#open_prs[@]}]}
        gh pr review "$random_pr" --approve --body "Automated review comment for graph balance." || true
        sleep 2
    done
fi

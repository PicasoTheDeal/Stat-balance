#!/bin/bash
set -e

rand_range() {
    local min=$1
    local max=$2
    echo $((RANDOM % (max - min + 1) + min))
}

ISSUES_COUNT=$(rand_range 2 6)
PR_COUNT=$(rand_range 4 8)

echo "Target -> Issues: $ISSUES_COUNT, PRs: $PR_COUNT"

gh pr list --state open --limit 300 --json number --jq '.[].number' | while read pr; do
    gh pr close "$pr" || true
    sleep 2
done

git fetch -p || true
git branch -r | grep 'origin/auto' | sed 's/origin\///' | while read branch; do
    git push origin --delete "$branch" || true
    sleep 2
done

echo "Creating issues..."
for ((i=1; i<=ISSUES_COUNT; i++)); do
    gh issue create --title "Automated Task #$RANDOM" --body "Routine profile balancing issue."
    sleep 2
done

echo "Creating pull requests..."
BRANCH_NAME="auto-balancer-$(date +%Y%m%d)"

git checkout main
git pull origin main
git checkout -b "$BRANCH_NAME" || git checkout "$BRANCH_NAME"

for ((i=1; i<=PR_COUNT; i++)); do
    echo "Log entry $i" >> balance.log
    git add balance.log
    git commit -m "chore: auto update $i"
done

git push origin "$BRANCH_NAME" --force

gh pr create --title "Auto PR - $(date +%Y-%m-%d)" --body "Automated pull request to balance graph." --base main

echo "Done."

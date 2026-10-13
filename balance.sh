#!/bin/bash
set -e

rand_range() {
    local min=$1
    local max=$2
    echo $((RANDOM % (max - min + 1) + min))
}

ISSUES_COUNT=$(rand_range 2 6)
PR_COUNT=$(rand_range 1 3)

echo "Target -> Issues: $ISSUES_COUNT, PRs: $PR_COUNT"

gh pr list --state open --limit 300 --json number --jq '.[].number' | while read pr; do
    gh pr close "$pr" || true
    sleep 3
done

git fetch -p || true
git branch -r | grep 'origin/auto' | sed 's/origin\///' | while read branch; do
    git push origin --delete "$branch" || true
    sleep 3
done

echo "Creating issues..."
for ((i=1; i<=ISSUES_COUNT; i++)); do
    gh issue create --title "Automated Task #$RANDOM" --body "Routine profile balancing issue."
    sleep 3
done

echo "Creating pull requests..."
for ((i=1; i<=PR_COUNT; i++)); do
    BRANCH_NAME="auto-pr-$i-$(date +%Y%m%d)"
    
    git checkout main || true
    git pull origin main || true
    git checkout -b "$BRANCH_NAME" || git checkout "$BRANCH_NAME"
    
    echo "Log entry $i" >> balance.log
    git add balance.log
    git commit -m "chore: auto update $i"
    
    git push origin "$BRANCH_NAME" --force
    
    gh pr create --title "Auto PR $i - $(date +%Y-%m-%d)" --body "Automated pull request to balance graph." --base main
    
    sleep 2
done

echo "Done."

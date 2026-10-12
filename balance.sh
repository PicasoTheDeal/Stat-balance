#!/bin/bash
set -e

rand_range() {
    local min=$1
    local max=$2
    echo $((RANDOM % (max - min + 1) + min))
}

ISSUES_COUNT=$(rand_range 14 27)
PR_COUNT=$(rand_range 34 56)
REVIEW_COUNT=$(rand_range 5 10)

gh pr list --state open --limit 300 --json number,createdAt | \
  jq -r '.[] | select((now - (.createdAt | fromdateiso8601)) > 86400) | .number' | \
  while read pr; do
      gh pr close "$pr" --comment "Auto-closing to balance graph." || true
      sleep 1
  done

git fetch -p
git branch -r | grep 'origin/auto-pr' | sed 's/origin\///' | while read branch; do
    git push origin --delete "$branch" || true
    sleep 1
done

for ((i=1; i<=ISSUES_COUNT; i++)); do
    GH_TOKEN="$SECONDARY_PAT" gh issue create --title "Automated Task #$RANDOM" --body "Routine profile balancing issue."
    sleep 2
done

BRANCH_NAME="auto-balancer-$(date +%Y%m%d)"

git checkout main
git pull origin main || true
git checkout -b "$BRANCH_NAME" || git checkout "$BRANCH_NAME"

for ((i=1; i<=PR_COUNT; i++)); do
    echo "Log entry $i" >> balance.log
    git add balance.log
    git commit -m "chore: auto update $i"
done

git push origin "$BRANCH_NAME" --force

GH_TOKEN="$SECONDARY_PAT" gh pr create --title "Auto PR - $(date +%Y-%m-%d)" --body "Automated pull request to balance graph." --base main || true

open_prs=($(gh pr list --state open --json number -q '.[].number'))

if [ ${#open_prs[@]} -gt 0 ]; then
    for ((i=1; i<=REVIEW_COUNT; i++)); do
        random_pr=${open_prs[RANDOM % ${#open_prs[@]}]}
        gh pr review "$random_pr" --approve --body "Automated review comment for graph balance." || true
        sleep 2
    done
fi

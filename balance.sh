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

echo "Target for today -> Issues: $ISSUES_COUNT, PRs: $PR_COUNT, Reviews: $REVIEW_COUNT"

echo "Creating issues..."
for ((i=1; i<=ISSUES_COUNT; i++)); do
    gh issue create --title "Automated Task #$RANDOM" --body "Routine profile balancing issue."
    sleep 1
done

echo "Creating pull requests..."
for ((i=1; i<=PR_COUNT; i++)); do
    branch="auto-pr-$(date +%s)-$i"
    
    git checkout -b "$branch"
    
    echo "Log entry $i" >> balance.log
    git add balance.log
    git commit -m "chore: auto update $i"
    
    git push origin "$branch"
    gh pr create --title "Auto PR $i" --body "Automated pull request to balance graph." --base main
    
    git checkout main
    sleep 2
done

echo "Submitting code reviews..."
open_prs=($(gh pr list --state open --json number -q '.[].number'))

if [ ${#open_prs[@]} -gt 0 ]; then
    for ((i=1; i<=REVIEW_COUNT; i++)); do
        random_pr=${open_prs[RANDOM % ${#open_prs[@]}]}
        gh pr review "$random_pr" --approve --body "Automated LGTM review." || true
        sleep 1
    done
else
    echo "No open pull requests available to review."
fi

echo "Daily graph balancing complete!"

#!/usr/bin/env bash
set -e

GIT_INDEX_FILE=/tmp/gh-pages-idx GIT_WORK_TREE=web git add -A
TREE=$(GIT_INDEX_FILE=/tmp/gh-pages-idx git write-tree)
COMMIT=$(echo "Deploy to GitHub Pages" | git commit-tree "$TREE")
git push -f origin "${COMMIT}:refs/heads/gh-pages"
rm -f /tmp/gh-pages-idx

echo "Deployed: https://nanot1m.github.io/space-cleaner/"

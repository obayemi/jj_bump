#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JJ_BUMP="$SCRIPT_DIR/jj_bump"

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

PASS=0
FAIL=0

pass() {
    echo "✓ $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "✗ $1"
    FAIL=$((FAIL + 1))
}

setup_test_repo() {
    cd "$TEST_DIR"
    rm -rf .jj testdata
    mkdir testdata
    cd testdata
    export GIT_AUTHOR_NAME="Test User"
    export GIT_AUTHOR_EMAIL="test@example.com"
    export GIT_COMMITTER_NAME="Test User"
    export GIT_COMMITTER_EMAIL="test@example.com"
    jj git init > /dev/null 2>&1
    jj describe -m "initial" > /dev/null 2>&1
}

test_basic_bump() {
    echo "Test: Basic bookmark bump to non-empty revision"
    setup_test_repo
    
    echo "content" > file.txt
    jj describe -m "add file" > /dev/null 2>&1
    
    jj bookmark create test-bookmark > /dev/null 2>&1
    
    jj new > /dev/null 2>&1
    jj describe -m "empty commit" > /dev/null 2>&1
    
    "$JJ_BUMP" > /dev/null 2>&1
    
    bookmark_commit=$(jj log -r test-bookmark --no-graph -T 'description' | head -n 1)
    if [[ "$bookmark_commit" == *"add file"* ]]; then
        pass "Basic bookmark bump"
    else
        fail "Basic bookmark bump - bookmark not on correct commit"
    fi
    return 0
}

test_no_bookmarks() {
    echo "Test: No bookmarks on previous commit"
    setup_test_repo
    
    echo "content" > file.txt
    jj describe -m "add file" > /dev/null 2>&1
    
    jj new > /dev/null 2>&1
    jj describe -m "another commit" > /dev/null 2>&1
    
    if "$JJ_BUMP" 2>&1 | grep -q "No local bookmarks found"; then
        pass "No bookmarks error"
    else
        fail "No bookmarks error"
    fi
    return 0
}

test_multiple_bookmarks() {
    echo "Test: Multiple bookmarks on previous commit"
    setup_test_repo
    
    echo "content" > file.txt
    jj describe -m "add file" > /dev/null 2>&1
    
    jj bookmark create bookmark1 > /dev/null 2>&1
    jj bookmark create bookmark2 > /dev/null 2>&1
    
    jj new > /dev/null 2>&1
    jj describe -m "empty commit" > /dev/null 2>&1
    
    "$JJ_BUMP" > /dev/null 2>&1
    
    bookmark1_commit=$(jj log -r bookmark1 --no-graph -T 'description' | head -n 1)
    if [[ "$bookmark1_commit" == *"add file"* ]]; then
        pass "Multiple bookmarks - first bookmark moved"
    else
        fail "Multiple bookmarks - first bookmark not moved correctly"
    fi
    return 0
}

test_multiple_empty_commits() {
    echo "Test: Multiple empty commits before non-empty"
    setup_test_repo
    
    echo "content" > file.txt
    jj describe -m "add file" > /dev/null 2>&1
    
    jj bookmark create test-bookmark > /dev/null 2>&1
    
    jj new > /dev/null 2>&1
    jj describe -m "empty 1" > /dev/null 2>&1
    
    jj new > /dev/null 2>&1
    jj describe -m "empty 2" > /dev/null 2>&1
    
    "$JJ_BUMP" > /dev/null 2>&1
    
    bookmark_commit=$(jj log -r test-bookmark --no-graph -T 'description' | head -n 1)
    if [[ "$bookmark_commit" == *"add file"* ]]; then
        pass "Multiple empty commits"
    else
        fail "Multiple empty commits - bookmark not on correct commit"
    fi
    return 0
}

test_no_non_empty_revision() {
    echo "Test: No non-empty revision in lineage"
    setup_test_repo
    
    jj bookmark create test-bookmark > /dev/null 2>&1
    
    jj new > /dev/null 2>&1
    jj describe -m "empty commit" > /dev/null 2>&1
    
    if "$JJ_BUMP" 2>&1 | grep -q "No non-empty revision found"; then
        pass "No non-empty revision error"
    else
        fail "No non-empty revision error"
    fi
    return 0
}

test_jj_not_installed() {
    echo "Test: jj command not available"
    
    if PATH="/dev/null" "$JJ_BUMP" 2>&1 | grep -q "jj command not found"; then
        pass "jj not installed error"
        return 0
    else
        fail "jj not installed error"
        return 0
    fi
}

echo "Running jj_bump tests..."
echo

test_remote_bookmarks() {
    echo "Test: Remote bookmarks are ignored"
    setup_test_repo
    
    echo "content" > file.txt
    jj describe -m "add file" > /dev/null 2>&1
    
    jj bookmark create test-bookmark > /dev/null 2>&1
    jj bookmark create "test-bookmark@origin" > /dev/null 2>&1 || true
    
    jj new > /dev/null 2>&1
    jj describe -m "empty commit" > /dev/null 2>&1
    
    if "$JJ_BUMP" 2>&1 | grep -q "test-bookmark@origin"; then
        fail "Remote bookmarks - should not try to move remote bookmarks"
    else
        pass "Remote bookmarks - correctly ignored"
    fi
    return 0
}

test_jj_not_installed
test_basic_bump
test_no_bookmarks
test_multiple_bookmarks
test_multiple_empty_commits
test_no_non_empty_revision
test_remote_bookmarks

echo
echo "========================================"
echo "Results: $PASS passed, $FAIL failed"
echo "========================================"

if [ $FAIL -eq 0 ]; then
    exit 0
else
    exit 1
fi

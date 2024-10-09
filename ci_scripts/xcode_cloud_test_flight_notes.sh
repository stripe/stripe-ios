#!/bin/sh

# Creates tester notes that will be visible to TestFlight testers.
#
# By default, the test flight notes will contain:
# - branch name
# - workflow name
# - the last commit message
#
# Available overrides:
# - Set the `TESTER_NOTES` environment variable to override the default message.
# - Set the `TESTER_NOTE_GITLOG_SINCE` environment variable to set `--since` argument for `git log` (e.g. "24 hours ago").
#
# Documentation on test notes:
# https://developer.apple.com/documentation/xcode/including-notes-for-testers-with-a-beta-release-of-your-app

TESTFLIGHT_DIR_PATH=../TestFlight
WHAT_TO_TEST_FILE_PATH="${TESTFLIGHT_DIR_PATH}/WhatToTest.en-US.txt"

# Make the directory if it doesn't exist yet
mkdir -p "${TESTFLIGHT_DIR_PATH}"

# Use TESTER_NOTES if variable environment was configured, otherwise use branch,
# workflow, and recent changes
if [ -n "${TESTER_NOTES}" ]; then
    NOTES="${TESTER_NOTES}"
else

    # If time range is set, use it, otherwise get the last commit
    if [ -n "${TESTER_NOTE_GITLOG_SINCE}" ]; then
        # By default, Xcode cloud does a shallow clone, so the commit history is limited to the last commit.
        # We need to deepen the git history to get the commits since the specified time.
        # Note: Specifying the branch name significantly speeds up the fetch.
        git fetch origin "${CI_BRANCH}" --shallow-since="${TESTER_NOTE_GITLOG_SINCE}"

        # Get commits since the specified time, reversing the order so they're listed chronologically
        # Limit to 100 commits so it doesn't get too long
        GIT_LOG_OPTIONS="--since=\"${TESTER_NOTE_GITLOG_SINCE}\" --reverse -100"
    else
        # Limit to the last commit
        GIT_LOG_OPTIONS="-1"
    fi

    # List commits using specified options and deliminate with bullet points
    COMMITS=$(eval "git log --pretty=format:\"- %s\" ${GIT_LOG_OPTIONS} \"${CI_BRANCH}\"")

    if [ -z "$COMMITS" ]; then
        COMMIT_NOTES="No new commits."
    elif [ -n "$TESTER_NOTE_GITLOG_SINCE" ]; then
        COMMIT_NOTES="Changes since ${TESTER_NOTE_GITLOG_SINCE}:\n${COMMITS}"
    else
        COMMIT_NOTES="Latest change:\n${COMMITS}"
    fi

    NOTES="Branch: ${CI_BRANCH}\nWorkflow: ${CI_WORKFLOW}\n\n${COMMIT_NOTES}"
fi

echo "Adding test flight notes to ${WHAT_TO_TEST_FILE_PATH}"
echo "${NOTES}"

echo "${NOTES}" > "${WHAT_TO_TEST_FILE_PATH}"

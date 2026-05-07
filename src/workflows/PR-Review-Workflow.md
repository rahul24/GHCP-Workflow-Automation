# Follow the instructions

1. Check the PR link is provided. If its not available `STOP` the processing.
2. Use `/deep-review` skill to start the PR review. The output of the review is saved in the markdown file under the docs folder. The name of the file should include sessionid and date.
3. Add the table at the end of the PR review document to show the comments needs to be given on PR against each file and line number in it. Include the column `Is Approved?` and set to blank.
4. After the review completed, update the table in the `PR-Tracker.md` for the reviewed PRs. Column needs to be updated are `Review document` with review document path, `Is approved to post review comment?` should always set to `NO` and `Impact` based on analysis set the PR impact (HIGH PRIORITY ISSUES or GAPS) either LOW, MEDIUM or HIGH.   

## PR-Tracker.md Structure

|PR|Link|Author|Date|PR Satus|PR Classification|Review document|Impact|Is approved to post review comment?|
|--|---|-------|----|--------|-----------------|---------------|-----------|------------------------------|
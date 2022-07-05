# rpminspect-tag-runner
Scripts to run rpminspect against an entire tag of packages.

This project is in active development; check README for latest steps.

To run:
1. Install / update rpminspect and the koji cli command
2. Define or create a profile (c9s is used by default)
3. Run tag_runner.sh in tmux/screen
5. Watch tag_runner.sh or tail run.log for less noise
6. Run generate-results.sh to see which packages have passed both inspection and comparison

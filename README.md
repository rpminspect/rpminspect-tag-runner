# rpminspect-tag-runner
Scripts to run rpminspect against an entire tag of packages.

These are in active development so things may change.

To run:

1. Update KOJI_CMD and KOJI_TAG if needed
2. Run generate-list.sh
3. Run tag_runner.sh in tmux/screen
4. Watch tag_runner.sh or tail run.log for less noise
5. Run generate-comparisons.sh
5. Run tag_runner.sh comparison-list.txt
6. Look at logs/*comparison*success results for NVRs ready to opt-out

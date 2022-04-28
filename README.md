# rpminspect-tag-runner
Scripts to run rpminspect against an entire tag of packages.

These are in active development so things may change.

To run:

1. Install / update rpminspect
2. Update KOJI_CMD and KOJI_TAG if needed
3. Run generate-list.sh
4. Run tag_runner.sh in tmux/screen
5. Watch tag_runner.sh or tail run.log for less noise
6. Run generate-comparisons.sh
7. Run tag_runner.sh comparison-list.txt
8. Look at logs/*comparison*success results for NVRs ready to opt-out

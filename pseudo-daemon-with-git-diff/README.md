Pseudo-daemon Monitoring with `git diff`
========================================

This is an enhancement to the code in `manual-submission` that adds
intelligent `git diff` checking and a "pseudo-daemon" that runs in the
background and checks for new commits before auto-launching a new build.

There's also a section commented out that hits a remote REST server with job
status updates so that we can track status without having to hop on a terminal.
If you want implement the REST server for remote status tracking, hit me up and
I can get you the code base --> [@knksmith57](https://twitter.com/knksmith57).
(*it's security through obscurity right meow, so I feel pretty sketchy posting
it up here with all this code. sorry bro.*)

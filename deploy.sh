#!/bin/bash
ssh cogtree@www.cogtree.com mkdir -p /data/vhosts/parsely.com/slides/logs
rsync -Pavz --exclude=.git ./_build/slides/ cogtree@www.cogtree.com:/data/vhosts/parsely.com/slides/logs
rsync -Pavz --exclude=.git ./_build/html/ cogtree@www.cogtree.com:/data/vhosts/parsely.com/slides/logs/notes/

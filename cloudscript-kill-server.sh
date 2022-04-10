#! /bin/bash
set -x

sudo killall portfolio
ps -aux | grep portfolio

set +x
exit
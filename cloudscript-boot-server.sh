#! /bin/bash
set -x

cd portfolio
go build

# run the server in the background
nohup sudo PORT=80 PROJECT_ID=831860464490 ./portfolio &>/dev/null < /dev/null &

ps -aux | grep portfolio

set +x
exit
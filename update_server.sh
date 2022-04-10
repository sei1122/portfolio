gcloud compute scp cloudscript-kill-server.sh seikoigi_gmail_com@instance-1:./
echo running cloudscript-kill-server.sh on remote computer
gcloud compute ssh seikoigi_gmail_com@instance-1 --command="source ~/cloudscript-kill-server.sh 2>&1 < /dev/null | tee ~/log/kill-server.txt"

rsync -aP . seikoigi_gmail_com@instance-1.us-west1-b.seiko-portfolio:portfolio

gcloud compute scp cloudscript-boot-server.sh seikoigi_gmail_com@instance-1:./
echo running cloudscript-boot-server.sh on remote computer
gcloud compute ssh seikoigi_gmail_com@instance-1 --command="source ~/cloudscript-boot-server.sh 2>&1 < /dev/null | tee ~/log/boot-server.txt"


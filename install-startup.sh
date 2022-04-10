# gcloud compute instances create instance-1 --project=seiko-portfolio --zone=us-west1-b --machine-type=e2-micro --network-interface=address=104.198.105.46,network-tier=PREMIUM,subnet=default --public-ptr --public-ptr-domain=seikoigi.com. --maintenance-policy=MIGRATE --service-account=831860464490-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/cloud-platform --enable-display-device --tags=http-server,https-server --create-disk=auto-delete=yes,boot=yes,device-name=instance-1,image=projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2004-focal-v20220406,mode=rw,size=10,type=projects/seiko-portfolio/zones/us-west1-b/diskTypes/pd-standard --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any --metadata=enable-oslogin=TRUE

# timeout/t 60 /nobreak
gcloud compute ssh seikoigi_gmail_com@instance-1 --command="rm -rf bin log"
gcloud compute ssh seikoigi_gmail_com@instance-1 --command="mkdir bin"
gcloud compute ssh seikoigi_gmail_com@instance-1 --command="mkdir log"
gcloud compute scp cloudscript-startup.sh seikoigi_gmail_com@instance-1:./
echo running cloudscript-startup.sh on remote computer
gcloud compute ssh seikoigi_gmail_com@instance-1 --command="source ~/cloudscript-startup.sh 2>&1 | tee ~/log/startup.txt"
gcloud compute scp seikoigi_gmail_com@instance-1:./log/startup.txt . && code startup.txt

# rsync -aP web seikoigi_gmail_com@instance-1.us-west1-b.seiko-portfolio:web
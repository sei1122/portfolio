rem call gcloud compute instances create instance-1 --project=seiko-portfolio --zone=us-west1-b --machine-type=e2-micro --network-interface=address=104.198.105.46,network-tier=PREMIUM,subnet=default --public-ptr --public-ptr-domain=seikoigi.com. --maintenance-policy=MIGRATE --service-account=831860464490-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/cloud-platform --enable-display-device --tags=http-server,https-server --create-disk=auto-delete=yes,boot=yes,device-name=instance-1,image=projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2004-focal-v20220406,mode=rw,size=10,type=projects/seiko-portfolio/zones/us-west1-b/diskTypes/pd-standard --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any --metadata=enable-oslogin=TRUE

rem timeout/t 60 /nobreak
call gcloud compute ssh swardle_gmail_com@instance-1 --command="rm -rf *"
call gcloud compute ssh swardle_gmail_com@instance-1 --command="mkdir bin"
call gcloud compute ssh swardle_gmail_com@instance-1 --command="mkdir log"
call gcloud compute scp startup-script.sh swardle_gmail_com@instance-1:./
echo running startup-script.sh on remote computer
call gcloud compute ssh swardle_gmail_com@instance-1 --command="source ~/startup-script.sh 2>&1 | tee ~/log/startup.txt"
call gcloud compute scp swardle_gmail_com@instance-1:./log/startup.txt . && code startup.txt

rem gcloud compute instances add-metadata instance-1 --metadata-from-file=startup-script=startup-script.sh
rem sudo google_metadata_script_runner startup
rem sudo journalctl -u google-startup-scripts.service
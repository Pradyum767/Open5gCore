#!/bin/bash

for i in "$@"; do
    case $i in
        -h|--help)
            usage
            exit
            ;;
        --vm=?*)
            VM=(${i#*=})
            echo "setting VM=${VM}"
            ;;
        --zone=?*)
            ZONE=${i#*=}
            echo "setting ZONE=${ZONE}"
            ;;
        --amfip=?*)
            amfip=${i#*=}
            echo "setting Amfip=${amfip}"
            ;;
        --num=?*)
            NUM=${i#*=}
            echo "setting number of subscriber=${NUM}"
            ;;
     esac
done
export PROJECT_ID=$(gcloud config get-value project)

export IP=$(gcloud compute instances describe $VM --zone ${ZONE} \
 --format='get(networkInterfaces[0].networkIP)')

sleep 10s
gcloud compute ssh root@$VM --zone ${ZONE} << EOF
set -x
export PROJECT_ID=\$(gcloud config get-value project)
cd UERANSIM/build
echo $IP
sed -i "s/10.128.0.122/$IP/g" open5gs-gnb.yaml
sed -i "s/10.48.0.12/$amfip/g" open5gs-gnb.yaml
./nr-gnb -c open5gs-gnb.yaml > gnb-logs 2>&1 &
sleep 5s
sudo ./nr-ue -c open5gs-ue.yaml -n $NUM -i 208930000000000 > ue-logs 2>&1 &
EOF


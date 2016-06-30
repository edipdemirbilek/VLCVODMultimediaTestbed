#!/bin/bash

#VLC server
ip=10.10.10.12
port=5554

#local path to save files
dir=/home/labo/Desktop/

#dummy net host
dummynet=root@10.128.1.11

#vlc streaming parameters
mc=1000000
fc=1000000
fbs=1000000

DELAY=0ms

#prefixes
DELI=_
bw=bw
bwunit=Kbit
jitter=j
plr=plr

function doNetworkConf { #$1=BW, $2=JITTER, $3=PLR

	#BW with DummyNet
	#Dummy net is in between
	start2=$(date +'%s')
	#echo ssh $dummynet ipfw -f flush
	ssh $dummynet ipfw -f flush
	#echo ssh $dummynet ipfw add 3000 pipe 1 ip from any to any
	ssh $dummynet ipfw add 3000 pipe 1 ip from any to any
	#echo ssh $dummynet ipfw pipe 1 config bw $1Kbit/s
	ssh $dummynet ipfw pipe 1 config bw $1Kbit/s
	#echo "It took $(($(date +'%s') - $start2)) seconds to configure bandwidth."
	
	#PLR and JITTER with TC
	
	#configuring the local interface
	start2=$(date +'%s')
	#echo sudo /sbin/tc qdisc del dev eth1 root
	sudo /sbin/tc qdisc del dev eth1 root
	#echo sudo /sbin/tc qdisc add dev eth1 root handle 1:1 netem delay $DELAY $2
	sudo /sbin/tc qdisc add dev eth1 root handle 1:1 netem delay $DELAY $2
	#echo sudo /sbin/tc qdisc add dev eth1 parent 1:1 handle 10:1 netem loss $3
	sudo /sbin/tc qdisc add dev eth1 parent 1:1 handle 10:1 netem loss $3
	#echo sudo /sbin/tc qdisc show
	#sudo /sbin/tc qdisc show
	echo "It took $(($(date +'%s') - $start2)) seconds to configure jitter and loss on local interface."
	
	#configuring the remote interface
	start2=$(date +'%s')
	#echo ssh $ip sudo /sbin/tc qdisc del dev eth1 root
	ssh $ip sudo /sbin/tc qdisc del dev eth1 root
	#echo ssh $ip sudo /sbin/tc qdisc add dev eth1 root handle 1:1 netem delay $DELAY $2
	ssh $ip sudo /sbin/tc qdisc add dev eth1 root handle 1:1 netem delay $DELAY $2
	#echo ssh $ip sudo /sbin/tc qdisc add dev eth1 parent 1:1 handle 10:1 netem loss $3
	ssh $ip sudo /sbin/tc qdisc add dev eth1 parent 1:1 handle 10:1 netem loss $3
	#echo ssh $ip sudo /sbin/tc qdisc show
	#ssh $ip sudo /sbin/tc qdisc show
	echo "It took $(($(date +'%s') - $start2)) seconds to configure jitter and loss on remote interface."
}

function doStream { #$1=ID, $2=FILE, $3=BW, $4=JITTER, $5=PLR, $6=op
	
	start1=$(date +'%s')
	echo $1 $2 $3 $4 $5
	doNetworkConf $3 $4 $5
	echo "$6 --- It took $(($(date +'%s') - $start1)) seconds to configure the network."
	
	cvlc -v rtsp://$ip:$port/$1 --sout-mux-caching=$mc --file-caching=$fc --rtsp-frame-buffer-size=$fbs --sout="#std{access=file,dst=$dir$2$DELI$bw$3$bwunit$DELI$jitter$4$DELI$plr$5.ts}" vlc://quit
}

#vlc server VOD object IDs
idTSStreams=( ts1 ts2 ts3 ts4 ts5 ts6 )

#file name prefixes to save
aTSFileNames=( MVI_2501_MPEG2_HD_720_LQ MVI_2501_MPEG2_HD_720_MQ MVI_2501_MPEG2_HD_720_HQ MVI_2501_MPEG2_HD_1080_LQ MVI_2501_MPEG2_HD_1080_MQ MVI_2501_MPEG2_HD_1080_HQ )

#Bandwidth, Jitter and Packet Loss rates
aTSBWsAvg=( 1266 3191 7441 2645 6902 12337 )
aTSBWsAvgMaxHalf=( 1436 3492 7941 3000 7550 15274 )
aTSBWsMax=( 1605 3792 8441 3355 8197 18211 )
aTSBWsDouble=( 3210 7584 16882 6710 16394 36422 )
aTSJitter=( 0ms 10ms 50ms 100ms )
aTSPlr=( 0 0.1 0.5 1 3 5 )

#counters
let op=0
let index=0

# for each VLC server VOD objects
for ID in "${idTSStreams[@]}"
do
  FILE=${aTSFileNames[$index]}
  for PLR in "${aTSPlr[@]}"
  do
	for JITTER in "${aTSJitter[@]}"
	do
	  doStream $ID $FILE ${aTSBWsAvg[$index]} $JITTER $PLR $op
	  let op+=1
	  doStream $ID $FILE ${aTSBWsAvgMaxHalf[$index]} $JITTER $PLR $op
	  let op+=1
	  doStream $ID $FILE ${aTSBWsMax[$index]} $JITTER $PLR $op
	  let op+=1
	  doStream $ID $FILE ${aTSBWsDouble[$index]} $JITTER $PLR $op
	  let op+=1
	done
  done
  let index+=1
done               



#!/bin/bash

#VLC server
ip=10.10.10.12
port=5554

#dummy net host
dummynet=root@10.128.1.11

DELAY=0ms

function doNetworkConf { #$1=BW, $2=JITTER, $3=PLR

	#BW with DummyNet
	#Dummy net is in between
	#echo ssh $dummynet ipfw -f flush
	ssh $dummynet ipfw -f flush
	#echo ssh $dummynet ipfw add 3000 pipe 1 ip from any to any
	ssh $dummynet ipfw add 3000 pipe 1 ip from any to any
	#echo ssh $dummynet ipfw pipe 1 config bw $1Kbit/s
	ssh $dummynet ipfw pipe 1 config bw $1Kbit/s
}

#Bandwidth, Jitter and Packet Loss rates
aTSBWsAvg=( 1266 3191 7441 2645 6902 12337 )
aTSBWsAvgMaxHalf=( 1436 3492 7941 3000 7550 15274 )
aTSBWsMax=( 1605 3792 8441 3355 8197 18211 )
aTSBWsDouble=( 3210 7584 16882 6710 16394 36422 )

for index in `seq 0 5`;
do
	  echo doNetworkConf ${aTSBWsAvg[$index]} 
	  doNetworkConf ${aTSBWsAvg[$index]} 
	  iperf -c 10.10.10.12 -u -b ${aTSBWsMax[$index]}k  -f k

	  echo doNetworkConf ${aTSBWsAvgMaxHalf[$index]} 
	  doNetworkConf ${aTSBWsAvgMaxHalf[$index]} 
	  iperf -c 10.10.10.12 -u -b ${aTSBWsMax[$index]}k  -f k

	  echo doNetworkConf ${aTSBWsMax[$index]}
	  doNetworkConf ${aTSBWsMax[$index]} 
	  iperf -c 10.10.10.12 -u -b ${aTSBWsMax[$index]}k  -f k

	  echo doNetworkConf ${aTSBWsDouble[$index]} 
	  doNetworkConf ${aTSBWsDouble[$index]} 
	  iperf -c 10.10.10.12 -u -b ${aTSBWsMax[$index]}k  -f k
     
done  



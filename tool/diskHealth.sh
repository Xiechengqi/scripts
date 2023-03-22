#!/bin/bash
while true
do
mkdir -p /var/run/prometheus
label=$(df -h |grep md|awk -F '[/ ]' '{print $3}'|grep -v md126|grep -v md127 )
lotusProcessCount=$(ps -ef |grep lotus-slave|grep -v grep|wc -l)
lotusProcessUser=$(ps -ef |grep lotus-slave|grep -v grep|awk '{print $1}'|grep -v root|uniq)
df=$(df -h|grep md|awk '{print $2}'|awk -F 'T' '{print $1}')
cpuType=$(lscpu|grep "Model name")
if [[ "${label}" =~ "md" ]];then
       if [[ "${df}" -le 15 ]];then
               labelT="one"
               echo "one"
       else
               labelT="two"
               echo "two"
       fi
else
        labelT="pro"
        echo "pro"
fi
if [[ -d "(/home/"${lotusProcessUser}"/.lotusslave/)" ]];then
        echo "slaveInit 999" >/var/run/prometheus/node.prom
else
        echo "slaveInit -1" >/var/run/prometheus/node.prom
fi
if [[ "${lotusProcessCount}" -ge 1 ]];then
        echo "slaveHealth -1" >>/var/run/prometheus/node.prom
        slaveForMiner=$(cat /home/"${lotusProcessUser}"/.lotusslave/config.toml|grep WorkForPowerActor|awk -F '"' '{print $2}')
        if  [[ "${slaveForMiner}" =~ 'f0' ]];then
                echo slaveForMiner{miner=\""$slaveForMiner"\"\,labelType=\""$labelT"\"} $lotusProcessCount>>/var/run/prometheus/node.prom
        slaveInfo=`su filecoin -c "~/bin/view_lotus.sh info"`
        p1ing=`echo -e "$slaveInfo"|grep PreCommit1|grep Queues|awk '{print $2}'`
        p1count=`echo -e "$slaveInfo"|grep PreCommit1|grep Queues|awk '{print $4}'`
        p1queues=`echo -e "$slaveInfo"|grep PreCommit1|grep Queues|awk -F 'Queues:' '{print $2}'|cut -d ")" -f1`
        p2ing=`echo -e "$slaveInfo"|grep -w PreCommit2|grep Queues|awk '{print $2}'`
        p2count=`echo -e "$slaveInfo"|grep -w PreCommit2|grep Queues|awk '{print $4}'`
        p2queues=`echo -e "$slaveInfo"|grep -w PreCommit2|grep Queues|awk -F 'Queues:' '{print $2}'|cut -d ")" -f1`
        c2ing=`echo -e "$slaveInfo"|grep -w Commit2|grep Queues|awk '{print $2}'`
        c2count=`echo -e "$slaveInfo"|grep -w Commit2|grep Queues|awk '{print $4}'`
        c2queues=`echo -e "$slaveInfo"|grep -w Commit2|grep Queues|awk -F 'Queues:' '{print $2}'|cut -d ")" -f1`
        echo p1ing{miner=\""$slaveForMiner"\"\,labelType=\""$labelT"\"} $p1ing>>/var/run/prometheus/node.prom
        echo p1count{miner=\""$slaveForMiner"\"\,labelType=\""$labelT"\"} $p1count>>/var/run/prometheus/node.prom
        echo p1queues{miner=\""$slaveForMiner"\"\,labelType=\""$labelT"\"} $p1queues>>/var/run/prometheus/node.prom
        echo p2ing{miner=\""$slaveForMiner"\"\,labelType=\""$labelT"\"} $p2ing>>/var/run/prometheus/node.prom
        echo p2count{miner=\""$slaveForMiner"\"\,labelType=\""$labelT"\"} $p2count>>/var/run/prometheus/node.prom
        echo p2queues{miner=\""$slaveForMiner"\"\,labelType=\""$labelT"\"} $p2queues>>/var/run/prometheus/node.prom
        echo c2ing{miner=\""$slaveForMiner"\"\,labelType=\""$labelT"\"} $c2ing>>/var/run/prometheus/node.prom
        echo c2count{miner=\""$slaveForMiner"\"\,labelType=\""$labelT"\"} $c2count>>/var/run/prometheus/node.prom
        echo c2queues{miner=\""$slaveForMiner"\"\,labelType=\""$labelT"\"} $c2queues>>/var/run/prometheus/node.prom
        else
                echo slaveForMiner{miner=\"999\"\,labelType=\""$labelT"\"} $lotusProcessCount>>/var/run/prometheus/node.prom
        fi
else
        slaveForMiner=999
        echo "slaveHealth 1" >>/var/run/prometheus/node.prom
        echo slaveForMiner{miner=\""$slaveForMiner"\"\,labelType=\""$labelT"\"} $lotusProcessCount>>/var/run/prometheus/node.prom
fi

if [[ "${label}" =~ 'md' ]];then
        echo "gaopei"
        nvidiaCount=`nvidia-smi  -L |grep GeForce|wc -l`
        nvidiaFan=`nvidia-smi |grep ERR |awk '{print $1}' |wc -l`
        echo "nvidiaCount $nvidiaCount" >>/var/run/prometheus/node.prom
        echo "nvidiaFan $nvidiaFan" >>/var/run/prometheus/node.prom
else
        echo "pro"
        diskHealth=`megacli -LDInfo -Lall -aALL |grep -E "(Virtual Drive|RAID Level|State|Number Of Drives)" | grep State |awk '{print $3 }'|awk '{printf "%s",$1}'`
        if [[ "${diskHealth}" =~ "Degraded" ]]; then
           echo "diskHealth 1" >>/var/run/prometheus/node.prom
   fi
        if [[ "${diskHealth}" =~ "Offline" ]]; then
           echo "diskHealth 999" >>/var/run/prometheus/node.prom
   fi
        if [[ "${diskHealth}" != "Offline" ]]||[[ "${diskHealth}" != "Degraded" ]]; then
           echo "diskHealth 0" >>/var/run/prometheus/node.prom
   fi
        raid=`megacli -cfgdsply -aALL|grep "RAID Level"|tail -1|awk -F: '{print $1":"$2}'`
        case "$raid" in
        "RAID Level          : Primary-1, Secondary-0, RAID Level Qualifier-0")
        echo "RaidLevel 1" >>/var/run/prometheus/node.prom ;;
        "RAID Level          : Primary-0, Secondary-0, RAID Level Qualifier-0")
        echo "RaidLevel 0" >>/var/run/prometheus/node.prom ;;
        "RAID Level          : Primary-5, Secondary-0, RAID Level Qualifier-3")
        echo "RaidLevel 5" >>/var/run/prometheus/node.prom ;;
        "RAID Level          : Primary-6, Secondary-0, RAID Level Qualifier-3")
        echo "RaidLevel 6" >>/var/run/prometheus/node.prom ;;
        "RAID Level          : Primary-1, Secondary-3, RAID Level Qualifier-0")
        echo "RaidLevel 10" >>/var/run/prometheus/node.prom ;;
        esac
        faileddisk=`megacli -AdpAllInfo -aALL -NoLog|awk '/Failed Disks/ {print $4}'`
        rebuilddisk=`megacli -cfgdsply -aALL|grep -c "Rebuild"`
        if [ $rebuilddisk = 0 ]; then
                rebuildNum=-1
        else
        rebuildNum=`megacli -cfgdsply -aALL  |grep "Rebuild" -B 19 |grep Slot |awk '{print $3}'|awk '{printf "%s",$1}'`
        echo "rebuildNum $rebuildNum" >>/var/run/prometheus/node.prom
        fi
        if [ $faileddisk = 0 ]; then
                 failNum=-1
        else
                 failNum=`megacli -PDList -aAll -NoLog|grep -E 'Failed|bad' -B 20|grep Slot|awk '{print $3}' |awk '{printf "%s",$1}'`
                 echo "failNum $failNum" >>/var/run/prometheus/node.prom
        fi
        nvidiaCount=`nvidia-smi  -L |grep GeForce|wc -l`
        nvidiaFan=`nvidia-smi |grep ERR |awk '{print $1}' |wc -l`
        disknum=`megacli -cfgdsply -aALL|grep "Number Of Drives"|awk -F: '{print $2}' |awk '{printf "%s",$1}'`
        echo "TotalDiskNumber $disknum" >>/var/run/prometheus/node.prom
        echo "nvidiaCount $nvidiaCount" >>/var/run/prometheus/node.prom
        echo "nvidiaFan $nvidiaFan" >>/var/run/prometheus/node.prom
fi
sleep 5m
done

#!/usr/bin/ksh
# Unix Pre-post Script
#
#Variable declaration

DIR=/tmp/INFO
NFSMNT=/mnt3
CHKLOG=$DIR
SER=$(hostname)
rootvg=$2
#DATE=$(date +"%m%d%Y")

bcmsg()
{
echo
echo "SANITY script should not take more than 10 seconds to complete, if it standalone. May take additional 5 sec if VIOS to take viosbr & HACMP "
echo "Please, RERUN this script by checking any NFS hangs or system performance "
echo
}

# Do bosboot & set bootlist
bosbootd()
{

echo
x1=$(bootinfo -b)
x2=$(lspv|grep -w "$rootvg"|awk '{print $1}'|head -1)
x22=$(lspv|grep -w "$rootvg"|awk '{print $1}'|tail -1)
x3=$(lspv|grep -w "$rootvg"|awk '{print $1}'|wc -l)
if [ "$x1" = "$x2" ] || [ "$x1" = "$x22" ] ; then
echo "\033[31mWait !!! Doing Bosboot on $x1 \033[0m"
bosboot -a
else
echo
echo "\033[31mWait !!! Last booted disk info & rootvg disk info NOT MATCHING, So doing bosboot on now $x2 \033[0m"
bosboot -ad /dev/"$x2"
fi
if [ "$x3" = 1 ] || [ "$x3" = 2 ] ; then
x4=$(lspv|grep -w "$rootvg"|awk '{print $1}'|tail)
echo
echo "Setting the bootlist as below"
bootlist -m normal "$x4"
bootlist -m normal -o
else
echo
echo "\033[31mLooks no rootvg mirrored, could be VIOC or ALTDISK may be \033[0m"
bootlist -m normal "$x4"
fi
}

# Find hmc
echo
findhmc()
{
HMCD=$(lsrsrc IBM.ManagementServer | grep -iw hmcipaddr)
if [ $? = 1 ] ; then
HMCD=$(lsrsrc IBM.ManagementServer | grep -iw hostname)
echo
echo "HMC IP Details is "; echo "$HMCD"
else
echo
echo "HMC IP Details is "; echo "$HMCD"
fi
HMCD1=$(lsrsrc IBM.MCP | grep -iw hmcipaddr)
if [ $? = 1 ] ; then
HMCD1=$(lsrsrc IBM.MCP | grep -iw hostname)
echo
echo "HMC IP Details is "; echo "$HMCD1"
else
echo
echo "HMC IP Details is "; echo "$HMCD1"
fi
}

# Local Directory Creation / Check

if  [ ! -d $DIR ] ; then
mkdir $DIR
fi

if [ ! -d $NFSMNT ] ; then
mkdir $NFSMNT
fi


getinfo()
{
DIS="____________________________________________________________________________________________________________"
ha_cnt=$(lssrc -g cluster | wc -l 2>/dev/null)
vioc=$(lsdev |grep -cE "l-lan|vio" 2>/dev/null)
echo;echo "Server : $SER" ; echo "INFO collected on $DAY";echo "$E_DIS" ;echo
echo "AIX VERSION" :;oslevel -s;echo $DIS ;echo
echo "PROCESSOR/VP DETAILS :";lsdev -Cc processor;
echo "TOTAL NO.OF PROCESSOR :";lsdev -Cc processor|wc -l
bindprocessor -q;echo $DIS ;echo
echo "LPARSTAT INFO :";lparstat -i;echo $DIS ;echo
echo "MEMORY DETAILS :";lsattr -El mem0;echo $DIS ;echo
echo "DF OUPTUT :";df|grep -v sapcd;echo $DIS ;echo
echo "MOUNT OUTPUT :";mount|grep -v sapcd;echo $DIS ;echo
echo "LSNFSMNT OUTPUT :";lsnfsmnt;echo $DIS ;echo
echo "LAST BOOT OUTPUT :";bootinfo -b;echo $DIS ;echo
echo "BOOTLIST OUTPUT :";bootlist -m normal -o;echo $DIS ;echo
echo "VG INFORMATIONS :";lsvg;lsvg -o;lsvg -o|lsvg -il;lsvg -o|lsvg -i;lsvg -o|lsvg -ip;echo $DIS ;echo
echo "LSPV OUTPUT :";lspv;echo $DIS ;echo
echo "IP ADDRESS DETAILS :";ifconfig -a;echo $DIS ;echo
echo "ROUTE DETAILS :";netstat -nr;echo $DIS ;echo
echo "INTERFACE DETAILS :";netstat -i;echo $DIS ;echo
echo "ADAPTERS DETAILS :";lsdev -Cc adapter;echo $DIS ;echo
echo "TAPE DETAILS :";lsdev -Cc tape;echo $DIS ;echo
echo "PHYSICAL ADAPTER DETAILS :";lscfg;echo $DIS ;echo
echo "LSDEV command OUTPUT :";lsdev;echo $DIS ;echo
echo "INET0 DETAILS :";lsattr -El inet0;echo $DIS ;echo
if [[ -f /usr/bin/pcmpath ]]; then
                pcmpath query adapter 2>/dev/null;
                echo ""
                pcmpath query wwpn 2>/dev/null;
        elif [[ -f /usr/bin/datapath ]] ; then
                datapath query adapter;
                echo ""
                datapath query wwpn;
if [[ -f /usr/sbin/powermt ]] ; then
                powermt display;
                powermt display dev=all;
if [[ -f /usr/DynamicLinkManager/bin/dlnkmgr ]] ; then
                dlnkmgr view -hba;
                dlnkmgr view -lu;
                dlnkmgr view -path;
        else
                echo "This server might be VIO client, so not necessary for pcmpath/datapath/powermt details"
fi
fi
fi

if [ "$vioc" -gt 1 ] ; then
echo
echo "VIOC Device Attributes :"
echo
echo "VSCSI adapter attributes :";lsdev|grep vscsi|awk '{print $1}'|while read -r a
        do
        echo "$a"
        lsattr -El "$a"
        echo
        done
echo
echo "VIRTUAL Fibre adapter attributes :";
        if ! lsdev | grep fscsi > /dev/null 2>&1 ; then
        lsdev | grep fscsi | awk '{print $1}'|while read -r a
        do
        echo "$a"
        lsattr -El "$a"
        echo
        done
        fi
echo
echo "VIRTUAL Disk attributes & PATH  :";lsdev |grep disk | awk '{print $1}'|while read -r a
        do
        echo "$a"
        lsattr -El "$a"
        echo
        done
        echo "LSPATH INFO :";lspath
fi

echo
echo $DIS ;echo
echo "HMC IP Details :";lsrsrc IBM.ManagementServer | grep -E -iw "hmcipaddr|hostname"
echo "HMC IP Details :";lsrsrc IBM.MCP | grep -E -iw "hmcipaddr|hostname"

if [ "$ha_cnt" -gt 1 ] ; then
        echo $DIS ; echo "CLUSTER DETAILS ";echo ;echo $DIS ;
        echo "CLSTAT OUTPUT :"; /usr/es/sbin/cluster/clstat -o  2>/dev/null;echo $DIS ;echo
        echo "CLLSIF  OUTPUT :";
        /usr/es/sbin/cluster/utilities/cllsif   2>/dev/null ;echo $DIS ;echo
        echo "CLDUMP OUTPUT :";
        /usr/es/sbin/cluster/utilities/cldump 2>/dev/null ;echo $DIS ;echo
        echo "CLSHOWRES OUTPUT :";
        /usr/es/sbin/cluster/utilities/clshowres 2>/dev/null ;echo $DIS;echo
fi
        echo $DIS ;echo;echo "FILESYSTEMS OUTPUT :";echo $DIS ;echo
        cat /etc/filesystems 2>/dev/null
        echo $DIS
VIOS=0
export VIOS
if ! VIOS=$(lsuser -a padmin  2>/dev/null) ; then
        echo $DIS ; echo "VIO Server Details";echo ;echo $DIS ;
        echo "VIOS Version:"; /usr/ios/cli/ioscli ioslevel
        echo
        echo "VIOS Virtual Adapters:"; /usr/ios/cli/ioscli lsdev -virtual
        echo
        echo "VIOS VA/SEA Mapping Details:"; /usr/ios/cli/ioscli lsmap -all -net
        echo
        echo "VIOS Disk mapping SCSI:"; /usr/ios/cli/ioscli lsmap -all
        echo
        echo "VIOS Disk Mapping NPIV:"; /usr/ios/cli/ioscli lsmap -all -npiv
        echo
        echo "VIOS MAPPING using viosbr backup taken & kept it /tmp/$SER:"; /usr/ios/cli/ioscli viosbr -backup -file /tmp/"$SER".viosbr.backup
        echo
        echo "Attribute Collections:"; /usr/ios/cli/ioscli lsdev|grep EtherChannel|awk '{print $1}'|while read -r SEA
        do
        echo "SEA $SEA Attributes : "
        lsattr -El "$SEA"
        done
        echo $DIS
fi

} > $CHKLOG/info_"$SER"

funchk()
{
cp /dev/null $CHKLOG/"$SER"."$1"
cp /dev/null $CHKLOG/"$SER".CPU."$1"
cp /dev/null $CHKLOG/"$SER".MEM."$1"
cp /dev/null $CHKLOG/"$SER".OS."$1"
cp /dev/null $CHKLOG/"$SER".FCS."$1"
if [[ $1 =  'precheck' ]] ; then
getinfo
fi
df -k 2>/dev/null > /tmp/.DF
lsdev -Cc processor 2>/dev/null > /tmp/.cpu
pcmpath query adapter 2>/dev/null > /tmp/.fcs
lsattr -El mem0 2>/dev/null > /tmp/.mem
oslevel -s 2>/dev/null > /tmp/.oslevel
CPU_C=$(< /tmp/.cpu grep -c Available)
PU=$(lparstat -i|grep "Entitled Capacity"|head -1|awk '{print $4}') 2>/dev/null
CAP=$(lparstat -i|grep -w "Mode"|grep -i capp|awk '{print $3}') 2>/dev/null
MEM=$(< /tmp/.mem grep Total | awk '{print $2}')
ROUTE=$(netstat -nr|grep -p Route|grep -cv Route)
OSLVL=$(cat /tmp/.oslevel)
FCS=$(< /tmp/.fcs grep -c fscsi)
echo "$CPU_C"  > $CHKLOG/"$SER".CPU."$1"
echo "$PU" > $CHKLOG/"$SER".PU."$1"
echo "$CAP" > $CHKLOG/"$SER".CAP."$1"
echo "$MEM" > $CHKLOG/"$SER".MEM."$1"
echo "$ROUTE" > $CHKLOG/"$SER".ROUTE."$1"
echo "$OSLVL" > $CHKLOG/"$SER".OS."$1"
echo "$FCS" > $CHKLOG/"$SER".FCS."$1"

< /tmp/.DF grep -v Filesystem | awk '{print $7}' | sort -u > $CHKLOG/"$SER"."$1"

}

cpu_mem()

{
F_CPU=0;F_MEM=0;F_PU=0;F_CAP=0;F_ROUTE=0
#F_OS=0
export F_CAP
export F_ROUTE

#DIFF=$(diff $CHKLOG/$SER.CPU.precheck $CHKLOG/$SER.CPU.end | grep ">" | > awk '{print $2,$3}')

CNT=$(diff $CHKLOG/"$SER".CPU.precheck $CHKLOG/"$SER".CPU.end | grep -c ">")

if [ "$CNT" -gt 0 ] ; then
echo;echo "Miss match in CPU !!!"
B_sys=$(< "$CHKLOG"/"$SER".CPU.precheck awk '{print $1}');A_sys=$(< "$CHKLOG"/"$SER".CPU.end awk '{print $1}')
echo "\033[31mBefore reboot CPU : $B_sys \033[0m"
echo "\033[31mAfter reboot CPU  : $A_sys \033[0m"
else
F_CPU=10
fi

CNT=$(diff $CHKLOG/"$SER".PU.precheck $CHKLOG/"$SER".PU.end | grep -c ">")

if [[ -f /usr/bin/lparstat ]]; then
if [ "$CNT" -gt 0 ] ;  then
echo;echo "Miss match in Processing Units !!!"
B_sys=$(< $CHKLOG/"$SER".PU.precheck awk '{print $1}');A_sys=$(< $CHKLOG/"$SER".PU.end awk '{print $1}')
echo "\033[31mBefore reboot Processing Units  : $B_sys \033[0m"
echo "\033[31mAfter reboot Processing Units  : $A_sys \033[0m"
else
F_PU=10
fi

CNT=$(diff $CHKLOG/"$SER".CAP.precheck $CHKLOG/"$SER".CAP.end | grep -c ">")

if [ "$CNT" -gt 0 ] ;  then
echo;echo "Miss match Processing Unit Mode !!!"
B_sys=$(< $CHKLOG/"$SER".CAP.precheck awk '{print $1}');A_sys=$(< $CHKLOG/"$SER".CAP.end awk '{print $1}')
echo "\033[31mBefore reboot Processing Unit Mode  : $B_sys \033[0m"
echo "\033[31mAfter reboot Processing Unit Mode  : $A_sys \033[0m"
else
F_CAP=10
fi

else
echo
echo "\033[31mThis is not capable for lparstat command to view/compare PROCESSING UNITS \033[0m"
fi

#DIFF=$(diff $CHKLOG/$SER.MEM.precheck $CHKLOG/$SER.MEM.end | grep ">" |awk '{print $2,$3}')
CNT=$(diff $CHKLOG/"$SER".MEM.precheck $CHKLOG/"$SER".MEM.end | grep -c ">")

if [ "$CNT" -gt 0 ] ; then
echo;echo "Miss match in Memory !!!"
B_sys=$(cat $CHKLOG/"$SER".MEM.precheck);A_sys=$(cat $CHKLOG/"$SER".MEM.end)
echo "\033[31mBefore reboot Memory : $B_sys \033[0m"
echo "\033[31mAfter reboot Memory  : $A_sys \033[0m";echo
else
F_MEM=10
fi

CNT=$(diff $CHKLOG/"$SER".ROUTE.precheck $CHKLOG/"$SER".ROUTE.end | grep -c ">")

if [ "$CNT" -gt 0 ] ; then
echo;echo "Miss match in Routing Table !!!"
B_sys=$(< $CHKLOG/info_"$SER" grep -p Route|grep -vp INET)
A_sys=$(netstat -nr|grep -p Route|grep -v Route)
echo -e "\033[31mBefore reboot Routing Table : \n $B_sys \033[0m"
echo -e "\033[31mAfter reboot Routing Table  : \n $A_sys \033[0m";echo
else
F_ROUTE=10
fi

#DIFF=$(diff $CHKLOG/$SER.OS.precheck $CHKLOG/$SER.OS.end | grep ">" | wc -l)
CNT=$(diff $CHKLOG/"$SER".OS.precheck $CHKLOG/"$SER".OS.end | grep -c ">")
if [ "$CNT" -gt 0 ] ; then
echo;echo "Miss match in OS level !!!"
echo "\033[01;33mPls ignore if the activity was related to NEW OS UPDATE/TL/SP else Pls correct the issue\033[00m"
B_sys=$(cat $CHKLOG/"$SER".OS.precheck);A_sys=$(cat $CHKLOG/"$SER".OS.end)
echo "\033[31mBefore reboot OS level : $B_sys \033[0m"
echo "\033[31mAfter reboot OS level : $A_sys \033[0m";echo
else
echo; echo "\033[32mNo difference found in oslevel before & after reboot\033[0m"
fi

if [[ -f /usr/bin/pcmpath ]]; then
CNT=$(diff $CHKLOG/"$SER".FCS.precheck $CHKLOG/"$SER".FCS.end | grep -c ">")
if [ "$CNT" -gt 0 ] ; then
echo;echo "\033[31mMiss match in Fiber Channel Disk adapter!!!\033[0m"
B_sys=$(cat $CHKLOG/"$SER".FCS.precheck);A_sys=$(cat $CHKLOG/"$SER".FCS.end)
echo "\033[31mBefore reboot Fiber Channel Disk adapter : $B_sys \033[0m"
echo "\033[31mAfter reboot Fiber Channel Disk adapter  : $A_sys \033[0m";echo
echo "Current Fiber info"
if [[ -f /usr/bin/pcmpath ]]; then
                pcmpath query adapter 2>/dev/null;
                echo ""
                /usr/bin/pcmpath query wwpn;
        elif [[ -f /usr/bin/datapath ]] ; then
                datapath query adapter;
                echo ""
                datapath query wwpn;
fi
else
echo; echo "\033[32mNo difference found in Fiber Channel Disk adapter\033[0m"
fi
echo
else
                echo
                echo "This server might be VIO client, so not necessary for pcmpath/datapath details"
fi


if [[ $F_CPU -eq 10 && $F_PU -eq 10 ]] ; then
echo
echo "\033[32mCPU PU & VP are fine\033[0m";
echo
elif [ $F_CPU -eq 10 ] ; then
echo;echo "\033[32mCPU Virtual Processor is Fine\033[0m ";
elif [ $F_PU -eq 10 ] ; then
echo;echo "\033[32mProcessing Units is Fine\033[0m";
echo;echo
fi

if [[ $F_MEM -eq 10 ]] ; then
echo
echo "\033[32mMemory is fine\033[0m";
echo
fi

}

vioc_cmp()

{

vioc=$(lsdev |grep -cE "l-lan|vio" 2>/dev/null)
if [ "$vioc" -gt 1 ] ; then
echo
echo "Check above info & going to list the VIOC Virtual attribute comparisions"
sleep 4
clear
# ATTRIBUTE VARIABLES A
vscsi[0]="vscsi_err_recov,fast_fail"
vscsi[1]="vscsi_path_to,30"
fscsi[0]="dyntrk,yes"
fscsi[1]="fc_err_recov,fast_fail"
hdisk[0]="hcheck_interval,60"
hdisk[1]="queue_depth,32"

# MAIN

echo "Virtual SCSI Adapter Attributes"
echo "-------------------------------"
if ! lsdev | grep vscsi > /dev/null 2>&1; then
  echo "Server contains vscsi adapters with the following attributes:"
    for vscsi_adapter in $(lsdev | grep vscsi | awk '{ print $1 }'); do
     echo "${vscsi_adapter}:"
     count=0
       while ( count < "{#vscsi[*]}" ); do
          VSCSI_VAR1=$(echo ${vscsi[$count]} | awk -F , '{ print $1 }')
          VSCSI_VAR2=$(echo ${vscsi[$count]} | awk -F , '{ print $2 }')

          VSCSI_CURRENT=$(lsattr -l "$vscsi_adapter" -a "$VSCSI_VAR1" -E | awk '{ print $2 }')

          if [ "$VSCSI_CURRENT" != "$VSCSI_VAR2" ]; then
            echo "\033[31m  $FAIL $VSCSI_VAR1 must be set to \"$VSCSI_VAR2\" \033[0m"
            let count="count + 1"
          else
            echo "   $OK $VSCSI_VAR1 = $VSCSI_VAR2"
            let count="count + 1"
          fi
       done
    done
else
   echo "Server does not contain any vscsi adapters"
fi

## Check fc adapter attributes
echo -e "\n"
echo "Virtual FC Adapter Attributes"
echo "-----------------------------"
if ! lsdev | grep fscsi > /dev/null 2>&1; then
  echo "Server contains fscsi adapters with the following attributes:"
    for fscsi_adapter in $(lsdev | grep fscsi | awk '{ print $1 }'); do
     echo "${fscsi_adapter}:"
     count=0
       while ( count < "{#fscsi[*]}" ); do
          FSCSI_VAR1=$(echo ${fscsi[$count]} | awk -F , '{ print $1 }')
          FSCSI_VAR2=$(echo ${fscsi[$count]} | awk -F , '{ print $2 }')

          FSCSI_CURRENT=$(lsattr -l "$fscsi_adapter" -a "$FSCSI_VAR1" -E | awk '{ print $2 }')

          if [ "$FSCSI_CURRENT" != "$FSCSI_VAR2" ]; then
            echo "\033[31m   $FAIL $FSCSI_VAR1 must be set to \"$FSCSI_VAR2\"\033[0m"
            let count="count + 1"
          else
            echo "   $OK $FSCSI_VAR1 = $FSCSI_VAR2"
            let count="count + 1"
          fi
       done
    done
else
   echo "Server does not contain any fscsi adapters"
fi

# Verify hdisks
echo -e "\n\n"
$BORDER
echo "=> Verify hdisk attributes"
$BORDER

## Check hdisk attributes
echo "hdisk attributes"
echo "----------------"
    for pv in $(lspv | grep hdisk | awk '{ print $1 }'); do
     echo "${pv}:"
     count=0
       while ( count < "{#hdisk[*]}" ); do
          HDISK_VAR1=$(echo ${hdisk[$count]} | awk -F , '{ print $1 }')
          HDISK_VAR2=$(echo ${hdisk[$count]} | awk -F , '{ print $2 }')

          HDISK_CURRENT=$(lsattr -l "$pv" -a "$HDISK_VAR1" -E | awk '{ print $2 }')

          if [ "$HDISK_CURRENT" != "$HDISK_VAR2" ]; then
            echo "\033[31m   $FAIL $HDISK_VAR1 must be set to \"$HDISK_VAR2\"\033[0m"
            let count="count + 1"
          else
            echo "   $OK $HDISK_VAR1 = $HDISK_VAR2"
            let count="count + 1"
          fi
       done
    done

## Check number of path's to disk
echo -e "\n"
echo "Disk paths"
echo "----------"
for hdisk in $(lspv | grep hdisk | awk '{ print $1 }'); do
      PATHS=$(lspath -l "$hdisk" | wc -l | sed 's,^ *,,')

      if [ "$PATHS" -lt 2 ]; then
        echo "${hdisk}:"
        echo "\033[31m   $FAIL There is only $PATHS path to the disk \033[0m"
      fi

      if [ "$PATHS" -gt 2 ]; then
        echo "${hdisk}:"
        echo "\033[31m   $FAIL There are more than 2 $PATHS path to the disk \033[0m"
      fi

done

else
echo
echo "This server does not looks like a VIOC to compare the Virtual settings of disk/vfcs/paths"
echo
fi

}




funcompare()
{
if [[ -s $CHKLOG/$SER.precheck  && -s $CHKLOG/$SER.precheck ]] ; then
funchk end
cpu_mem
sed '/^$/d' $CHKLOG/"$SER".precheck > /tmp/.remove_empty_line;cp /tmp/.remove_empty_line $CHKLOG/"$SER".precheck
sed '/^$/d' $CHKLOG/"$SER".end > /tmp/.remove_empty_line;cp /tmp/.remove_empty_line $CHKLOG/"$SER".end
DIFF=$(diff $CHKLOG/"$SER".precheck $CHKLOG/"$SER".end | grep "<" | awk '{print $2}')
CNT=$(diff $CHKLOG/"$SER".precheck $CHKLOG/"$SER".end | grep "<" | awk '{print $2}'| wc -l)

if [ "$CNT" -gt 0 ] ; then
echo;echo "Filesystem not mounted"
echo;echo "\033[31m$DIFF \033[0m";echo

# echo "Would you like to Mount the FS one by One (y/n): \c"

# read -r T_CON

T_CON='n'

if [[ $T_CON = 'y' || $T_CON = 'Y' ]] ; then
 for FS in $(print "${DIFF}")
 do
# echo; echo "FS : $FS : Do you want to mount     (y/n): \c"
# read -r T_CON;echo
 if [[ $T_CON = 'y' || $T_CON = 'Y' ]] ; then
 mount "$FS"
 FS_CHK=$(df  | grep -cw "$FS")

    if [ "$FS_CHK" -eq 0 ] ; then
       echo "\033[31mUNABLE to MOUNT the FS $FS, Please check above errors and fix the issue manually !!!!!!! \033[0m";
    else
       echo "\033[32m Successfully mount the FS $FS \033[0m";
    fi

 else
 echo "\033[31mCheck the FS $FS and mount manually,If needed \033[0m";
 fi
 done
 else
 echo "\033[31mCheck and MOUNT ALL the FS manually,If needed \033[0m";
fi
else
echo
echo "\033[32mALL the FS are Mounted\033[0m";
echo
fi
funchk end
#fun_over

#Checking the default gatway

D_ROUTE=$(netstat -rn | grep -cw  default)
if [ "$D_ROUTE" -eq 0 ] ; then
  echo; echo "\033[31mDefault Gateway Does Not Exist, Please Check!
\033[0m";
elif [ "$D_ROUTE" -gt 1 ] ; then
  echo; echo "\033[31mDuplicate Default Gateway, Please Check! \033[0m";
fi
vioc_cmp

else
echo "\033[31mYou must run with  check precheck before to run with compare option \033[0m";
fi
exit 0

}


funbase()
{
clear
echo -e "Select the options to do \n1. Find high size used files in a directory \n2. List System Performance \n"
echo
read -r no
if [ "$no" = 1 ] ; then
        echo
        echo "please provide the full path of directory / if current directory : \c";read -r dir
        find "$dir" -xdev -size +$((2048*20)) -exec du -am {} \;|sort -nr | head -20
        echo
        echo -e "Do you want to truncate any of log files in below list if its greater in size, select number else process any key \n1. Truncate wtmp - If Yes, no more question & this will be truncated \n2. Truncate any Log files (Make sure you are not nullify/zipping the data/mail files, it should be only text files"
        echo
        read -r no1
        if [ "$no1" = 1 ] ; then
        if [ -f /usr/bin/dsmc ] ; then
        echo -e "taking backup of wtmp file if tsm works \n $(dsmc ba /var/adm/wtmp)"
        echo "Before truncate $(ls -al /var/adm/wtmp)"
        /usr/lib/acct/fwtmp < /var/adm/wtmp > /tmp/wtmp.out
        tail -500 /tmp/wtmp.out > /tmp/wtmp.small
        /usr/lib/acct/fwtmp -ci < /tmp/wtmp.small > /var/adm/wtmp
        rm /tmp/wtmp.out
        rm /tmp/wtmp.small
        echo "After truncate $(ls -al /var/adm/wtmp)"
        else
        echo "No tsm to backup the wtmp file, can we proceed with wtmp truncate ? y/n : \c";read -r ans
        if [ "$ans" = y ] ; then
        echo "Before truncate $(ls -al /var/adm/wtmp)"
        /usr/lib/acct/fwtmp < /var/adm/wtmp > /tmp/wtmp.out
        tail -500 /tmp/wtmp.out > /tmp/wtmp.small
        /usr/lib/acct/fwtmp -ci < /tmp/wtmp.small > /var/adm/wtmp
        rm /tmp/wtmp.out
        rm /tmp/wtmp.small
        echo "After truncate $(ls -al /var/adm/wtmp)"
        fi
        fi
        fi
        if [ "$no1" = 2 ] ; then
        echo "Specify the Log file name with full path / if current path : \c";read -r dir1
        echo "Be sure, you are going to 1. nullify 2. or zip this file : \c"; read -r opt
                        if [ "$opt" = 1 ] ; then
                        if [ -f /usr/bin/dsmc ] ; then
                        echo -e "taking backup of $dir1 file if tsm works \n $(dsmc i "$dir1")"
                        cat "$dir1" > /dev/null
                        echo
                        echo "After nullify $(ls -al "$dir1")"
                        else
                        echo "No dsmc found or with errors, Proceeding with nullify"
                        cat "$dir1" > /dev/null
                        echo "After nullify $(ls -al "$dir1")"
                        fi
                        fi
                        if [ "$opt" = 2 ] ; then
                        if [ -f /usr/bin/dsmc ] ; then
                        echo -e "taking backup of $dir1 file if tsm works \n $(dsmc i "$dir1")"
                        gzip "$dir1"
                        echo
                        echo "After zip $(ls -al "$dir1".gz)"
                        else
                        echo "No dsmc found or with errors, Proceeding with nullify"
                        echo
                        gzip "$dir1"
                        fi
                        fi
        fi
fi
if [ "$no" = 2 ]  ; then
clear
TOPAS=$(ps aux | head -1; ps aux | sort -rn +2 | head -20)
MEMORY=$(svmon -Pt20 | perl -e 'while(<>){print if($.==2||$&&&!$s++);$.=0 if(/^-+$/)}')
echo "Monitoring system using vmstat & svmon - Allow 12 sec"
CPU=$(vmstat 2 2 | tail -1 | awk '{print $14+$15}')
echo -e "CPU exceeded $CPU us+sy percent on $SERVER \n$TOPAS"
echo
FREE=$(svmon -G -O unit=MB|grep -p free|tail -3|grep -v "space"|awk '{print $4}')
echo -e "AVM MEMORY free is $FREE MB on $SERVER \n$MEMORY"
echo
PAG=$(vmstat 2 2 | tail -1 | awk '{print $6+$7}')
echo -e ""PAGING exceeded "$PAG" pi+po pages on "$SERVER"" \n $(lsps -a)"
echo
echo "Specify the process id to find its related process tree  (OR) press ^c to break: \c";read -r proc
        if [ -f /usr/bin/proctree ] ; then
        echo -e "Proctree for process $proc \n$(proctree "$proc")"
        else
        echo -e "Proctree for process $ proc \n$(ps -T "$proc")"
        fi
else
echo "Exiting"
fi
}
ser_fun()
{
#if [ $? -ne 0 ] ; then
if 0 ; then
echo "hi"
else
case $1 in
        precheck)
                clear
                bcmsg
                funchk precheck
                < /etc/niminfo grep MASTER_HOST|while read -r a
                do
                $a
                NIMSERV=$NIM_MASTER_HOSTNAME
                if [ "$NIMSERV" = nimprod1 ] || [ "$NIMSERV" = nimprod2 ]
                then
                mount "$NIMSERV":/appl/nim/images $NFSMNT
                cp /tmp/INFO/info_"$SER" $NFSMNT/INFO
                echo
                echo "$(ls -al $NFSMNT/INFO/info*"$SER") file copied to NIM sever under /appl/nim/images/INFO";
                umount $NFSMNT
                fi
                if [ "$NIMSERV" = aixnim1t ] || [ "$NIMSERV" = aixnim2t ]
                then
                mount "$NIMSERV":/export/INFO $NFSMNT
                cp /tmp/INFO/info_"$SER" $NFSMNT
                echo
                echo "$(ls -al $NFSMNT/info*"$SER") file copied to NIM sever under /export/INFO";
                umount $NFSMNT
                fi
                if [ "$NIMSERV" = nimdev1 ]
                then
                mount "$NIMSERV":/appl/nim/mksysb $NFSMNT
                cp /tmp/INFO/info_"$SER" $NFSMNT/INFO
                echo
                echo "$(ls -al $NFSMNT/INFO/info*"$SER") file copied to NIM sever under /export/INFO";
                umount $NFSMNT
                fi
                done
                bosbootd
                findhmc
                echo
                echo "\033[1mServer : $SER -> Precheck & Getinfo Scripts Completed  \033[0m ";
                echo
        ;;
        checkend)
                funchk end
        ;;
        postcompare)
                clear
                bcmsg
                funcompare
                #fcs_check
                pv_cnt=$(lsvg -o | lsvg -ip | grep -ci missing  2>/dev/null)
                if [ "$pv_cnt" -gt 0 ] ; then
                echo
                echo "\033[31mSome PV's are in Missing State. Pls check and correct \033[0m"
                else
                echo
                echo "\033[32mStatus of all PV's looks fine\033[0m"
                fi
                sz_cnt=$(lsvgfs "$rootvg" | grep -v bos_inst | xargs -i df -m {} | grep -v Filesystem | awk '{print $4}' | grep -ci 100%)
                if [ "$sz_cnt" -gt 0 ] ; then
                echo
                echo "\033[31mSome of the rootvg filesystems are full. Pls check and correct \033[0m"
                fi
                ha_cnt=$(lssrc -g cluster | wc -l 2>/dev/null)
                if [ "$ha_cnt" -gt 1 ] ; then
                HAcheck_fun
                fi
                export compare="yes"
        ;;
        *)
                echo "\033[31m the options are: precheck, postcompare"
        ;;
esac
fi
}
ser_fun "$1"
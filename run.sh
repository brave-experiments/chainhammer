# defaults:
DBFILE=temp.db
INFOFILE=hammer/last-experiment.json
TPSLOG=logs/tps.py.log
DEPLOYLOG=logs/deploy.py.log
SENDLOG=logs/send.py.log

# if [ -z "$CH_TXS" ] || [ -z "$CH_THREADING" ]; then 
#     echo "You must set 2 ENV variables, examples:"
#     echo "export CH_TXS=1000 CH_THREADING=sequential"
#     echo "export CH_TXS=5000 CH_THREADING=\"threaded2 20\""
#     exit
# fi

# if (( $# != 1  && $# != 2 )); then
#     echo "Syntax:"
#     echo "./run.sh info-word [network-scripts-prefix]"
#     echo "e.g."
#     echo "./run.sh Geth-t2.xlarge"
#     echo "./run.sh Geth-t2.xlarge geth-clique"
#     echo "The first case assumes that network nodes are started manually."
#     exit    
# fi

INFOWORD=$1

# exit when any command fails
set -e
# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo; echo "\"${last_command}\" command filed with exit code $?."' EXIT
#

function title {
    echo =============================
    echo = $1
    echo ============================= 
}  

echo 

title "chainhammer v52 - run all ="
echo
echo infoword: $INFOWORD
echo number of transactions: $CH_TXS 
echo concurrency algo: $CH_THREADING
echo
echo infofile: $INFOFILE
echo blocks database: $DBFILE
echo log files:
echo $TPSLOG
echo $DEPLOYLOG
echo $SENDLOG
echo

# exit

if (( $# == 2 )); then
    title start network
    source networks/$2-start.sh
    echo
fi


title "activate virtualenv" 
source env/bin/activate
echo
python --version
echo 

cd hammer
rm -f $INFOFILE
#  Taking out last info file
rm -f last-experiment.json

title is_up.py
echo Loops until the node is answering on the expected port.
./is_up.py
echo Great, node is available now.
echo 

title tps.py
echo start listener tps.py, show here but also log into file $TPSLOG
echo this ENDS after send.py below writes a new INFOFILE $INFOFILE
unbuffer ./tps.py | tee "../$TPSLOG" &
echo


title send 
echo Send Transactions through Jmeter and wait 10 more blocks.
echo Then send_jmeter.py triggers tps.py to end counting. Logging all into file $SENDLOG. 


./send_jmeter.py  > "../$SENDLOG"


echo

title "sleep 2"
echo wait 2 second until also tps.py has written its results.
echo
sleep 2
echo



cd ..

# switch off the trap already here, because sometimes the 2nd kill in networks/$2-stop.sh is not needed anymore:
set +e
trap '' EXIT

if (( $# == 2 )); then
    title stop network
    source networks/$2-stop.sh
 
    echo

fi

title "Ready."
# echo See that image, and those .md and .html pages.
echo Experiemnt done.
echo



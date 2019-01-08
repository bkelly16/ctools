#!/bin/bash

# Generate random number between 1 and DIR_DEPTH and use it as sleep value to simulate random IO access to filesystem
# use another andome number to fake differnet file sizes
# should be able to force script to run recursively and can then compare it to the parralel option. Should be able to hit the mds less this way.
# This script should write to  files of random size and radnom times as well as read random files at random times.
# Do one pass of multiple dirs and file names lke {A,B,C,D,E}/{1,2,3,4,5,6,7,8,9,10}.img (mkdir and touch)
# then read and wirte chucks randoly.

DIR_DEPTH=$1 ; if [ -z $DIR_DEPTH ]; then DIR_DEPTH=10 ;fi
FILE_DEPTH=$2 ; if [ -z $FILE_DEPTH ]; then FILE_DEPTH=$DIR_DEPTH ;fi
ROOT_PATH=/cephfs
MAX_WAIT=20

trap cleanup INT

initdir(){
    local DEPTH=$1
    local i=1
    local TEST_PATH=$ROOT_PATH
    while [ $i -le $DEPTH ];do
        TEST_PATH+="/$i"
        let i=i+1 
    done
    mkdir -p $TEST_PATH
}
initfiles(){
    local DIR_DEPTH=$1
    local FILE_DEPTH=$2
    local TEST_PATH=$ROOT_PATH
    i=1
    while [ $i -le $FILE_DEPTH ];do
        FILE_STRING+="$i,"
        let i=i+1
    done
    FILE_STRING=${FILE_STRING::-1}
    j=1
    while [ $j -le $DIR_DEPTH ];do
        TEST_PATH+="/$j"
        eval touch $TEST_PATH/level$j-{$FILE_STRING}.img
        let j=j+1
    done
}
randdir(){
    local DIR_DEPTH=$1
    local DIR_RAND=$(( ( RANDOM % $DIR_DEPTH ) + 1 ))
    echo "$DIR_RAND"
}
randfile(){
    local FILE_DEPTH=$1
    local FILE_RAND=$(( ( RANDOM % $FILE_DEPTH ) + 1 ))
    echo "$FILE_RAND"
}
randclock(){
    local MAX_WAIT=$1
    local CLOCK_RAND=$(( ( RANDOM % $MAX_WAIT ) + 1 ))
    echo "$CLOCK_RAND"
}
cleanup(){
    echo "cleanup"
    rm -rf {1,2}
}

initdir $DIR_DEPTH
initfiles $DIR_DEPTH $FILE_DEPTH

CLOCK_RAND=$(randclock $MAX_WAIT)
while sleep $CLOCK_RAND;do
    echo $CLOCK_RAND
    IO_TYPE=$(randclock $MAX_WAIT)
    IO_SIZE=$(randclock $MAX_WAIT)
    if [ $IO_TYPE -ge $(( 3*MAX_WAIT/4 )) ];then
        RAND_DIR_SEED=$(randdir $DIR_DEPTH)
        RAND_FILE_SEED=$(randfile $FILE_DEPTH)
        TEST_PATH="$ROOT_PATH"
        i=1
        while [ $i -le $RAND_DIR_SEED ];do
            TEST_PATH+="/$i"
            let i=i+1 
        done
        pv < $TEST_PATH/level$RAND_DIR_SEED-$RAND_FILE_SEED.img > /dev/null
    else
        RAND_DIR_SEED=$(randdir $DIR_DEPTH)
        RAND_FILE_SEED=$(randfile $FILE_DEPTH)
        TEST_PATH="$ROOT_PATH"
        i=1
        while [ $i -le $RAND_DIR_SEED ];do
            TEST_PATH+="/$i"
            let i=i+1 
        done
        dd if=/dev/zero of=$TEST_PATH/level$RAND_DIR_SEED-$RAND_FILE_SEED.img bs=1M count=$IO_SIZE
    fi
    CLOCK_RAND=$(randclock $MAX_WAIT)
done     




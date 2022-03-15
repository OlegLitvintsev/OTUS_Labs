#!/bin/bash
srcDir="/proc/"

tics_to_ms() {
 ((secs=(${1}/$(getconf CLK_TCK))))
 ((m=$secs/60))
 ((s=$secs%60))
 printf "%d:%02d" $m $s
}

echo -e "PID\tTTY\tSTAT\tTIME\tCOMMAND"
for var in $(ls $srcDir | sort -V | awk '/[[:digit:]]/{print $0}')
do
terminal=" ? "
    if [ -f $srcDir$var/comm ]
    then
        if [ -r $srcDir$var/fd/0 ]
        then
            terminal=$(ls -la $srcDir$var/fd | grep dev | head -n 1 |  sed  's/\/dev\//\ /' | awk '{print $11}')
        fi
        prrocState=$(cat $srcDir$var/stat | awk '{print $3}')
        utime=$(cat $srcDir$var/stat | awk '{print $14}')
        stime=$(cat $srcDir$var/stat | awk '{print $15}')
        let time=utime+stime
        if [ "$(cat $srcDir$var/cmdline | wc -c)" -eq 0 ]
        then
            comm="["$(cat $srcDir$var/comm)"]"
        else
            comm=$(cat $srcDir$var/cmdline | tr '\000' ' ')
        fi
        echo -e $var"\t"$terminal"\t"$prrocState"\t"$(tics_to_ms $time)"\t"$comm"\t"
    fi
done

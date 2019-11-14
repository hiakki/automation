#!/bin/bash
# Author - Akshay Gupta
# Version - 1.0.0

#> ROTATE operation
#* daily create copy as a backup of error and access logs from "logs" directory to "backup" directory in user's home
#* create an archive (zip /or/ tar.gz) of backup of access log present in "backup" directory, which are older then 2 months (from current date) and copy them in "archive" directory in user's home
#* create an archive (zip /or/ tar.gz) of backup of error log present in "backup" directory, which are older then 2 weeks (from current date) and copy them in "archive" directory in user's home
#* access logs of only last 1 week (from current date) remain/present in "logs" directory
#* error logs of only last 3 day's (from current date) remain/present in "logs" directory
#* backup access logs of only last 2 month's (from current date) remain/present in "backup" directory
#* backup error logs of only last 2 week's (from current date) remain/present in "backup" directory
#* access log archive's (present in "archive" directory) of only 6 month's (from current date) remain/present in "archive" directory. Rest access log archives should be moved into "deleted" directory in user's home
#* error log archive's (present in "archive" directory) of only 2 month's (from current date) remain/present in "archive" directory. Rest error log archives should be moved into "deleted" directory in user's home

#> LIST operation
#* perform LIST operation on available backup's (in "backup" dir) and archvie's (in "archive" dir)
#* List operation output show `state`, `log_creation_date`, `log_type` in output. Check the output format below:
#------
#<state>                 <log-creation-date>             <log-type>
#(backup /or/ archive)   {date}-{month}-{year}           (access /or/ error)
#------

#* By default list operation print all entries in backup's and archive's. But an optional argument to list operation allow to choose `state` and/or `log_type` to print/show results based on given values, sorted by data
#>> See example's for reference:
#        cmd -> <script> list // print all access and error log's available in both archive and and backup dir's, sorted by date
#        output ->
#                archive 7-Jan-2019 access
#                backup 27-Apr-2019 access
#                archive 5-May-2019 error
#                backup 12-Jun-2019 error

#        cmd -> <script> list --log-type access // print only access logs available in both archive and backup dir's, sorted by date
#        output ->
#                archive 7-Jan-2019 access
#                backup 27-Apr-2019 access


#        cmd -> <script> list --state archive // print access and error logs available in archive dir's, sorted by date
#        output ->
#                archive 7-Jan-2019 access
#                archive 5-May-2019 error

#        cmd -> <script> list --log-type error --state backup // print error logs available in backup dir's, sorted by date
#        output ->
#                backup 12-Jun-2019 error

#> RESTORE operation
#* RESTORE(copy) the logs backup's available in "backup" or "archive" directory to the "logs" directory.
#* restore operation required 3 inputs from user. `state`,`date`, and `log_type`
#>> See example's for reference:
#        cmd -> <script> restore --state backup --date 27-Apr-2019 --log-type access // will restore(i.e copy) access log of date 27-Apr-2019 from "backup" into "logs" dir in user's home
#        cmd -> <script> restore --state archive --date 5-May-2019 --log-type error // will unarchive(or unzip) and restore(i.e copy) error log of date 5-May-2019 from "archive" into "logs" dir in user's home


#> Script usage
#* script print usage/help information if run without any options or passing --help/-h to it.


PROGNAME=$0
cd $HOME

usage() {
  cat << EOF >&2
  
Usage: $PROGNAME [rotate] [list] [restore]

LISTING

list --log-type <access/error>
list --state <backup/archive>
list --log-type <access/error> --state <backup/archive>

RESTORING

restore --state <backup/archive> --date <DD-MM-YYYY> --log-type <access/error>

EOF
  exit 1
}

rotating() {

# For logs folder

cd logs
cp * ../backup/ -r

for dirName in *
do 
	createdDate=`date -d"$dirName" +%s`
	threeDays=`date --date "7 days ago" +%s`
	oneWeek=`date --date "7 days ago" +%s`
	
	if [[ $createdDate -lt $threeDays ]]
		then
			rm -rf $dirName/error.log
	fi

	if [[ $createdDate -lt $oneWeek ]]
		then
			rm -rf $dirName
	fi
done

cd ..

# For backup folder

cd backup

for dirName in *
do 
	createdDate=`date -d"$dirName" +%s`
	twoWeeks=`date --date "2 weeks ago" +%s`
	twoMonths=`date --date "2 months ago" +%s`
	
	if [[ $createdDate -lt $twoWeeks ]]
	then
		if [ -f $dirName/error.log ]
		then
			tar czf ../archive/$dirName@error $dirName/error.log
			rm -rf $dirName/error.log
		fi
	fi

	if [[ $createdDate -lt $twoMonths ]]
		then
			tar czf ../archive/$dirName@access $dirName/access.log
			rm -rf $dirName
	fi
done

cd ..

# For archive folder

cd archive

for fileName in *
do 
	IFS='@' read -r -a a <<< $fileName
	dirName=${a[0]}
	createdDate=`date -d"$dirName" +%s`
	sixMonths=`date --date "6 months ago" +%s`

	
case ${a[1]} in
error)
	if [[ $createdDate -lt $twoMonths ]]
	then
		mv $fileName ../deleted/
	fi
;;
access)
	if [[ $createdDate -lt $sixMonths ]]
	then
		mv $fileName ../deleted/
	fi
;;
esac
done

cd ..
}

listing1() {
listDisplay=()
cd backup
for dirName in *
do
	if [ $(ls $dirName | grep -c log) -eq 1 ]
	then
		listDisplay+=("backup $dirName access")
	else
		listDisplay+=("backup $dirName error")
		listDisplay+=("backup $dirName access")
	fi
done
cd ..

cd archive
for fileName in *
do
	IFS='@' read -r -a a <<< $fileName
	listDisplay+=("archive ${a[0]} ${a[1]}")
done
cd ..
}

listing2() {
n=${#listDisplay[@]}

for ((i=0; $i<$((n-1)); i=$((i+1))))
do
	x=$(echo ${listDisplay[$i]} | tr ' ' ,)
	IFS=',' read -r -a y <<< $x
	p=`date -d"${y[1]}" +%s`

	for ((j=$((i+1)); $j<$n; j=$((j+1))))
	do
		a=$(echo ${listDisplay[$j]} | tr ' ' ,)
		IFS=',' read -r -a b <<< $a
		q=`date -d"${b[1]}" +%s`
		
		if (( $p > $q ))
		then
			p=$q
			
			temp=${listDisplay[$i]}
			listDisplay[$i]=${listDisplay[$j]}
			listDisplay[$j]=$temp
		fi
	done		
done
}

listing() {

case $1 in
--state)
state=$2
;;
--log-type)
log_type=$2
;;
'')
for ((i=0; $i<${#listDisplay[@]}; i=$((i+1))))
do
	echo ${listDisplay[$i]} | awk '{printf "%-8s %-12s %-1s\n",$1,$2,$3}'
done
exit
;;
*)
echo "Unknown Parameter '$1'."
exit
;;
esac

}

post_listing() {
paramed=()
if [ ! -z $state ] && [ ! -z $log_type ]
then

	for ((i=0; $i<${#listDisplay[@]}; i=$((i+1))))
	do
		a=$(echo ${listDisplay[$i]} | tr ' ' ,)
		IFS=',' read -r -a b <<< $a

		if [ $state = ${b[0]} ] && [ $log_type = ${b[2]} ]
		then
			paramed+=("${listDisplay[$i]}")
		fi
	done

elif [ ! -z $state ] && [ -z $log_type ]
then

	for ((i=0; $i<${#listDisplay[@]}; i=$((i+1))))
	do
		a=$(echo ${listDisplay[$i]} | tr ' ' ,)
		IFS=',' read -r -a b <<< $a

		if [ $state = ${b[0]} ]
		then
			paramed+=("${listDisplay[$i]}")
		fi
	done

elif [ -z $state ] && [ ! -z $log_type ]
then

	for ((i=0; $i<${#listDisplay[@]}; i=$((i+1))))
	do
		a=$(echo ${listDisplay[$i]} | tr ' ' ,)
		IFS=',' read -r -a b <<< $a

		if [ $log_type = ${b[2]} ]
		then
			paramed+=("${listDisplay[$i]}")
		fi
	done

fi

for ((i=0; $i<${#paramed[@]}; i=$((i+1))))
do
	echo ${paramed[$i]} | awk '{printf "%-8s %-12s %-1s\n",$1,$2,$3}'
done
}

restoring() {

case $1 in
--state)
state=$2
;;
--date)
date_param=$2
;;
--log-type)
log_type=$2
;;
*)
echo "Unknown Parameter '$1'."
exit
;;
esac

}

post_restoring() {

if [ ! -z $state ] && [ ! -z $date_param ] && [ ! -z $log_type ]
then

	for ((i=0; $i<${#listDisplay[@]}; i=$((i+1))))
	do
		a=$(echo ${listDisplay[$i]} | tr ' ' ,)
		IFS=',' read -r -a b <<< $a

		if [ $state = ${b[0]} ] && [ $date_param = ${b[1]} ] && [ $log_type = ${b[2]} ]
		then
			case $state in
			backup)
			mkdir -p logs/$date_param
			cp $state/$date_param/$log_type.log logs/$date_param/$log_type.log
			;;
			archive)
			tar xzf $state/$date_param\@$log_type -C logs/
			;;
			esac
		fi
	done

else
	echo "All three parameters 'state', 'date' and 'log-type' are required for restoring."
fi

}

case $1 in
rotate) rotating
;;
list) 
listing1
listing2

if [[ "$#" < 3 ]]
then
	listing ''
fi
while [[ "$#" -ge 3 ]]; do
    listing "$2" "$3"
    shift; shift
done

post_listing
;;
restore)
while [[ "$#" -ge 3 ]]; do
    restoring "$2" "$3"
    shift; shift
done

listing1
post_restoring
;;
*) usage
;;
esac

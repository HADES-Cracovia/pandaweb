rm padiwa_threshold_dump.log
rm padiwa_threshold.log
rm padiwa_threshold_result.log
echo setting all thresholds to nirvana

for i in 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10
do
    for j in 0 1 2 3
    do
	endpoint="0"$i$j
        echo $endpoint
	./write_thresholds.pl dummythresholds.thr -o 5
        ./thresholds_automatic.pl --endpoint=0x$endpoint --chain=0 --offset=0 --32channel --polarity 0
        ./read_threshold.pl --endpoint=0x$endpoint --chain=0 --offset=0 --32channel
    done
done
exit


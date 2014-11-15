set terminal pdf
set output "data/dlm_jitter_blocks.pdf"

set xlabel "Run"
set ylabel "Average DLM Latency [ns]"

#set xrange [0:10]

plot 'data/dlm_jitter_blocks.txt' using ($1+1):3:4 with errorbar title "DLM Latency"
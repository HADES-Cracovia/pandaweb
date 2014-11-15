set terminal png
set output "data/dlm_jitter.png"

load "data/dlm_jitter.label"
set label labelText at graph 0.05,0.95

set xlabel "Deviation from average"
set ylabel "Frequency"

set title "Jitter of DLM"

binwidth=10
bin(x,width)=width*floor(x/width)

plot 'data/dlm_jitter.txt' using (bin($2*1000,binwidth)):(1.0) smooth freq with boxes notitle
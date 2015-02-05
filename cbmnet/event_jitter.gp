set terminal png
set output "data/event_jitter.png"

load "data/event_jitter.label"
set label labelText at graph 0.05,0.95

set xlabel "Deviation from average [ps]"
set ylabel "Frequency"

binwidth=10
bin(x,width)=width*floor(x/width)
plot 'data/event_jitter.txt' using (bin($2*1000,binwidth)):(1.0) smooth freq with boxes notitle
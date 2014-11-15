set terminal pdf
set output "data/calib.pdf"

set xlabel "Fine-Time"
set ylabel "Calibrated Fine-Time [ns]"
set key left;
set xrange [-1:512]
set yrange [-0.1 : 5.1]

plot \
  'data/calib.txt' using 1 with line title "Ch 0 Timing Trg", \
  'data/calib.txt' using 2 with line title "Ch 1 DLM sensed", \
  'data/calib.txt' using 3 with line title "Ch 2 Pulser", \
  'data/calib.txt' using 4 with line title "Ch 3 Timing Trg (CBM)", \
  'data/calib.txt' using 5 with line title "Ch 4 DLM Ref";

reset
set terminal pdf
set xrange [-1:512]

set output "data/histogram.pdf"

set ylabel "Frequency"
  
plot \
  'data/histogram.txt' using 1 with line title "Ch 0 Timing Trg", \
  'data/histogram.txt' using 2 with line title "Ch 1 DLM sensed", \
  'data/histogram.txt' using 3 with line title "Ch 2 Pulser", \
  'data/histogram.txt' using 4 with line title "Ch 3 Timing Trg (CBM)", \
  'data/histogram.txt' using 5 with line title "Ch 4 DLM Ref";  
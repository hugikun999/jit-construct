reset                                                                           
set ylabel 'time(ms)'
set title 'hanoi'
set style fill solid
set term png enhanced font 'Verdana,10'
set output 'comparison_hanoi.png'

plot [:][:] 'data/hanoi.txt' using 4:xtic(1) with histogram notitle  , \
'' using ($0):($4+1):4 with labels notitle

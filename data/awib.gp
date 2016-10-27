reset                                                                           
set ylabel 'time(ms)'
set title 'awib'
set style fill solid
set term png enhanced font 'Verdana,10'
set output 'comparison_awib.png'

plot [:][:] 'data/awib.txt' using 4:xtic(1) with histogram notitle  , \
'' using ($0):($4+1):4 with labels notitle

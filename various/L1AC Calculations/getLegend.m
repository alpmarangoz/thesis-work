function [legendstr] = getLegend(x)

n = min(size(x)) ;
xstr = inputname(1) ;
if n == 1 ;
    legendstr = xstr ;
else
    for i=1:n
        vecxstr(i,:) = xstr ;
    end
    vecnumstr = num2str([1:n]') ;
    legendstr = [vecxstr vecnumstr] ;
end
end

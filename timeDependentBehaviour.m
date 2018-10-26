
A1 = [0 0.5; 0 0 ] ;

lrm = -10 ;
Arm = [lrm 0 ; 0 lrm] ;

A2 = A1-Arm ;
eig(A2)

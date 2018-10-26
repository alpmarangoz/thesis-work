

A1 = [0 0 1; 0 0 0; 0 0 0] - Arm_x1
eig(A1) ;

w3Max = 2 ;
Ar1 = [0 0 0; 0 0 -1 ; 0 0 -a*w3Max] + -10*eye(3)
eig(Ar1) ;



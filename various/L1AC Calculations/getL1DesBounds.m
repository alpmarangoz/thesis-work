function [ybound,xbound,ubound] = getL1DesBounds(A,b,c,tht,x0,r,km,C,lambda,dispFlag,warningFlag)
% Bounds for the L1 Adaptive Control System design calculations
% Calculates limiting bounds between the ref system outputs and implementation scheme
% L1 Adaptive Control book, Eqns. 2.26-2.27

warningState = warning;

if nargin < 10
    warningFlag = 0 ;
    dispFlag = 0 ;
elseif nargin < 11
    warningFlag = 0 ;    
end

if warningFlag == 0
    warning off all
end


%% Calculations
Am = A - b*km' ;
s = tf('s') ;
H = ((s*eye(2)-Am)^-1)*b ;
xin = ((s*eye(2)-Am)^-1)*x0 ;

kg = -1./(c'*(Am^-1)*b);

if lambda>=1
    warning(['lambda:  ' num2str(lambda) ' (lambda should be < 1)'])
end

coeff_lambda = lambda/(1-lambda) ;
kgHC_L1 = getL1norm(kg*H*C) ;
CthtTpkmT_L1 = getL1norm(C*tht'+km') ;
rLinf = norm(r,inf) ;
xinLinf = norm(xin,inf) ;

ybound = coeff_lambda*norm(c',1)*(kgHC_L1*rLinf+xinLinf) ;
xbound = coeff_lambda*(kgHC_L1*rLinf+xinLinf) ;
ubound = coeff_lambda*CthtTpkmT_L1*(kgHC_L1*rLinf+xinLinf) ;




if dispFlag 

disp(['lambda = ' num2str(lambda) ' (lambda should be < 1)'])

disp(['|kg*H(s)*C(s)|_L1 = [' num2str(num2str(reshape(kgHC_L1,1,length(kgHC_L1)))) '] (' num2str(size(kgHC_L1,1)) 'x' num2str(size(kgHC_L1,2)) ')'])
disp(['|C(s)*theta^T + km^T|_L1 = [' num2str(num2str(reshape(CthtTpkmT_L1,1,length(CthtTpkmT_L1)))) '] (' num2str(size(CthtTpkmT_L1,1)) 'x' num2str(size(CthtTpkmT_L1,2)) ')'])

disp(['|xin|_Linf <= ' num2str(xinLinf)])
disp(['|r|_Linf <= ' num2str(rLinf)])

disp(['|ydes-yref|_Linf <= ' num2str(ybound)])
disp(['|xdes-xref|_Linf <= ' num2str(xbound)])
disp(['|udes-uref|_Linf <= ' num2str(ubound)])

end

warning(warningState)
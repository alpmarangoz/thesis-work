function [lambda,gamma1,gamma2] = getL1RefBounds(A,b,tht,km,C,THT,Gamma,dispFlag,warningFlag)
% Bounds for the L1 Adaptive Control System design calculations
% Calculates limiting bounds between the ref system outputs and implementation scheme
% L1 Adaptive Control book, Eqns. 2.19-2.20

warningState = warning;

if nargin < 8
    warningFlag = 0 ;
    dispFlag = 0 ;
elseif nargin < 9
    warningFlag = 0 ;    
end

if warningFlag == 0
    warning off all
end


%% Calculations
Am = A - b*km' ;
s = tf('s') ;
H = ((s*eye(2)-Am)^-1)*b ;
G = H*(1-C) ;
L = norm(THT,1) ;
lambda = getL1norm(G)*L ;

if lambda>=1
    warning(['lambda:  ' num2str(lambda) ' (lambda should be < 1)'])
end

H1 = getGRelDeg1(C,H) ;

C_L1 = getL1norm(C) ;
G_L1 = getL1norm(G) ;
H1_L1 = getL1norm(H1) ;
CthtTpkmT_L1 = getL1norm(C*tht'+km') ;


Q = eye(size(Am)) ;
P = lyap(Am',Q) ;
[temp,checkPtv] = chol(P)  ; % Check for positive definiteness
if checkPtv ~= 0
    error('P is not Positive definite')
end

lambdaminP = min(eig(P)) ;
thetamax = max(THT) ;
gamma1 = C_L1./(1-G_L1)*sqrt(thetamax/lambdaminP) ;
gamma2 = H1_L1*sqrt(thetamax/lambdaminP)+ CthtTpkmT_L1*gamma1 ;

if dispFlag 
upBoundxrefmx = gamma1/sqrt(Gamma) ;
upBoundurefmu = gamma2/sqrt(Gamma) ;

disp(['lambda = ' num2str(lambda) ' (lambda should be < 1)'])
disp(['|C(s)|_L1 = [' num2str(num2str(reshape(C_L1,1,length(C_L1)))) '] (' num2str(size(C_L1,1)) 'x' num2str(size(C_L1,2)) ')'])
disp(['|G(s)|_L1 = [' num2str(num2str(reshape(G_L1,1,length(G_L1)))) '] (' num2str(size(G_L1,1)) 'x' num2str(size(G_L1,2)) ')'])
disp(['|H1(s)|_L1 = [' num2str(num2str(reshape(H1_L1,1,length(G_L1)))) '] (' num2str(size(H1_L1,1)) 'x' num2str(size(H1_L1,2)) ')'])
disp(['|C(s)*theta^T + km^T|_L1 = [' num2str(num2str(reshape(CthtTpkmT_L1,1,length(CthtTpkmT_L1)))) '] (' num2str(size(CthtTpkmT_L1,1)) 'x' num2str(size(CthtTpkmT_L1,2)) ')'])

disp(['lambdaminP = ' num2str(lambdaminP) ' '])
disp(['thetamax = ' num2str(thetamax) ' '])
disp(['gamma1 = [' num2str(num2str(reshape(gamma1,1,length(gamma1)))) '] (' num2str(size(gamma1,1)) 'x' num2str(size(gamma1,2)) ')'])
disp(['gamma2 = [' num2str(num2str(reshape(gamma2,1,length(gamma2)))) '] (' num2str(size(gamma2,1)) 'x' num2str(size(gamma2,2)) ')'])

disp(['|xref-x|_Linf <= [' num2str(num2str(reshape(upBoundxrefmx,1,length(upBoundxrefmx)))) '] (' num2str(size(upBoundxrefmx,1)) 'x' num2str(size(upBoundxrefmx,2)) ')'])
disp(['|uref-u|_Linf <= [' num2str(num2str(reshape(upBoundurefmu,1,length(upBoundurefmu)))) '] (' num2str(size(upBoundurefmu,1)) 'x' num2str(size(upBoundurefmu,2)) ')'])

end

warning(warningState)
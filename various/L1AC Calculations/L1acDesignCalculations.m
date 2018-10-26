clear all
% close all
clc


%% The system
A = [0 1; -1 -1.4] ;
b = [0 1]' ;
c = [1 0] ;
tht = [-4 4.5]' ; % nonlinearity


%% Controller 
% Non-adaptive gain
km = [0 0]' ;
Amc = A - b*km' ;

% Adaptation law
Gamma = 10000 ;
Gamma = 400 ;
THT = [-10 10] ;
Q = eye(size(Amc)) ;
P = lyap(Amc',Q) ;
[temp,checkPtv] = chol(P)  ; % Check for positive definiteness
if checkPtv ~= 0
    error('P is not Positive definite')
end

% Low Pass Filter
wc = 10:10:200 ;

for i = 1:length(wc)
%     C = tf(wc(i),[1 wc(i)]);
    C = tf([3*wc(i)^2 wc(i)^3],conv([1 wc(i)],conv([1 wc(i)],[1 wc(i)])));
    [lambda(i),gamma1,gamma2] = getL1RefBounds(A,b,tht,km,C,THT,Gamma);
    upBoundxrefmx(i) = gamma1/sqrt(Gamma) ;
    upBoundurefmu(i) = gamma2/sqrt(Gamma) ;
end

figure ; plot(wc,lambda) ; grid on ; xlabel('\omega_c') ; ylabel('\lambda')



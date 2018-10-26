clearvars
% close all hidden
clc

%% Simulation
dtmax = 1e-3 ; 
dtFc = 1*dtmax ;
tof = 7;
q0 = [90 0]'*pi/180 ;
qdot0 = [0 0]'*pi/180 ;
visualFlag = 0;
visualizationDataFlag = 1 ;

%% Plant Parameters
l1 = 1 ; l2 = 1 ; lc1 = 0.5 ; lc2 = 0.5 ;
m1 = 1 ; m2 = 1 ; I1 = m1*l1*1/12 ; I2 = m2*l2*1/12  ;
c1 = 1; c2 = 1; 
g = 9.81 ; 

%% Fault insertion
tfault = 5 ; ifault = 2 ; faultyArm = 2 ;
% ifault:2 => Freeswing, ifault:3 => Locked, 
% ifault:4 => Saturation, ifault:5 => Ramp
fault_gamma = 1 ; fault_taumax = 15 ;


faultCs = zeros(4,5); 
faultCs(:,1) = [0 tfault tfault+dtFc max(tof,tfault+2*dtFc)] ;
faultCs(3:4,2) = 1 ; % ifault = 2 is always 1 in the presence of faults 
faultCs(3:4,ifault) = 1 ;



%% Commands 
r1(:,1) = 0:dtFc:tof ;
r1(:,2) = (90+20*sin(2*pi*0.25*r1(:,1)))*pi/180 ;
r1(:,3) = -(20*sin(2*pi*0.25*r1(:,1)))*pi/180 ;
% r1(:,2) = 90 *pi/180 ;

r2(:,1) = 0:dtFc:tof ;
r2(:,2) = 45*pi/180 ; 
r2(:,3) = -45*pi/180 ; 

r = r1 ;

%% Controller
% Nominal controller
wn = 2*pi*10 ; ksi  = 1 ;
Kv = 2*ksi*wn ;
Kp = wn^2 ;
clearvars wn ksi

% State Estimator
xhat0 = [q0 ; qdot0] ; xhatdot0 = zeros(4,1) ;
nofstates = length(xhat0) ;
As = zeros(nofstates,nofstates) ;
As(1:2,1:2) = -30*eye(2) ;
As(3:4,3:4) = -50*eye(2) ;

% Distrubance Estimation
Dhat0 = zeros(4,1) ; 


% Parameters for Custom Basis Function

% Parameters for Chebyshev Polynomial Basis Function
nCheby = 4 ;


% Parameters for RBF Basis Function
x1is = -2:2:2 ; 
x2is = -2:2:2 ;
x3is = -2:2:2 ; 
x4is = -2:2:2 ;

% x3is =  -100:20:100 ;
% x4is = -100:20:100 ;

% 
x1is = 0 ;
x2is = 0 ;
x3is = 0 ;
x4is = 0 ;

nRBF = length(x1is)*length(x2is)*length(x3is)*length(x4is) ;
xu = zeros(nRBF,2) ;
n = 0 ;
for i1 = 1:length(x1is)
    for i2 = 1:length(x2is)
        for i3 = 1:length(x3is)
            for i4 = 1:length(x4is)
                n = n+1 ;
                xu(n,1) = x1is(i1);
                xu(n,2) = x2is(i2);
                xu(n,3) = x3is(i3);
                xu(n,4) = x4is(i4);
            end
        end
    end
end
clear i1 i2 i3 i4

% Parameters for Basis function integration
Q = eye(2) ;
Ps = lyap(As(3:4,3:4)',Q) ;
[temp,checkPtv] = chol(Ps)  ; % Check for positive definiteness
if checkPtv ~= 0
    error('Ps is not Positive definite')
end
GammaW = 1000 ; Wbnd = 1000 ; epsilontheta = 0.01 ;
W0 = 0 ;


%% Execute Simulation

try
sim('simTwoLinkFDIbasisComparison')
catch
end
plotlab

break
%%
v = axis ;
v(2) = 7;
axis(v)




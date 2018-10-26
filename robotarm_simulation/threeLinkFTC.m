clearvars
% close all hidden
clc

%% Simulation
dtmax = 1e-3 ;
dtFc = 1*dtmax ;
tof = 10;
q0 = [90 0 0]'*pi/180 ;
qdot0 = [0 0 0]'*pi/180 ;

%% Plant Parameters
l1 = 1 ; l2 = 1 ; l3 = 1 ; lc1 = 0.5 ; lc2 = 0.5 ; lc3 = 0.5 ;
m1 = 1 ; m2 = 1 ; m3 = 1 ; I1 = m1*l1^2*1/12 ; I2 = m2*l2^2*1/12  ; I3 = m3*l3^2*1/12  ;
g = 9.81 ;

%% Fault insertion
% ifault:2 => Freeswing, ifault:3 => Locked,
% ifault:4 => Saturation, ifault:5 => Ramp
tfault = 5 ; ifault = 2 ; faultyArm = 3 ;



faultCs = zeros(4,5);
faultCs(:,1) = [0 tfault tfault+dtFc max(tof,tfault+2*dtFc)] ;
faultCs(3:4,2) = 1 ; % ifault = 2 is always 1 in the presence of faults
faultCs(3:4,ifault) = 1 ;



%% Commands
r1(:,1) = 0:dtFc:tof ;
r1(:,2) = (90+20*sin(2*pi*0.25*r1(:,1)))*pi/180 ;
r1(:,3) = -(20*sin(2*pi*0.25*r1(:,1)))*pi/180 ;
r1(:,4) = (45*sin(2*pi*0.25*r1(:,1)))*pi/180 ;

r2(:,1) = 0:dtFc:tof ;
r2(:,2) = 90*pi/180 ;
r2(:,3) = -45*pi/180 ;
r2(:,4) = 45*pi/180 ;

r3(:,1) = 0:dtFc:tof ;
r3(:,2) = 80*pi/180 ;
r3(:,3) = 20*pi/180 ;
r3(:,4) = 0*pi/180 ;


r = r1 ;

%% Controller
% Fault mitigation position
fmPosition = [0 90 -45]'*pi/180 ;

% Nominal controller
wn = 2*2*pi ; ksi  = 0.7 ;
Kv = 2*ksi*wn ;
Kp = wn^2 ;
clearvars wn ksi

% State Estimator
xhat0 = [q0 ; qdot0] ; xhatdot0 = zeros(6,1) ;
nofstates = length(xhat0) ;
As = zeros(nofstates,nofstates) ;
As(1:3,1:3) = -30*eye(3) ;
As(4:6,4:6) = -50*eye(3) ;

%% Distrubance Estimation
Dhat0 = zeros(6,1) ;


% Parameters for Chebyshev Polynomial Basis Function
nCheby = 4 ;

% Parameters for Basis function integration
Q = eye(3) ;
Ps = lyap(As(4:6,4:6)',Q) ;
[temp,checkPtv] = chol(Ps)  ; % Check for positive definiteness
if checkPtv ~= 0
    error('Ps is not Positive definite')
end
GammaW = 1000 ; Wbnd = 1000 ; epsilontheta = 0.01 ;
W0 = 0 ;

%% Fault Detection
Dlimit = 10 ;
FDstart = 0.5 ;


%% FTC Controller parameters
% PFBL controller 
ksi = 0.7 ;
wn = 2*pi ;

K2 = wn^2 ;
K1 = 2*wn*ksi;

% ADI Controller
epsilon = 0.5 ;
r0 = [0 0]' ; rmax = inf*[50*pi/180 inf]' ; rmin = -rmax ;

% Reference model
ksi = 0.7 ;
wn = 2*2*pi ;
Arm1 = [0 1; -wn^2 -2*ksi*wn] ;
Brm1 = [0 wn^2]' ;

% ADI parameters
alpha = 1 ;
Ar = [0 5; -30 -30] ;
Ar = [0 1; -5 -5] ;

% Fault mode
Bfault = [0 0; 0 1] ;
%% Execute Simulation
try
    sim('simThreeLinkFTC')
catch err
    disp('Error in simulation:')
    msg = err.message ;
    nline = 100 ;
    for i = 0:floor(length(msg)/nline)-1
        disp(msg(nline*i+1:nline*(i+1)))
    end
    disp(msg(nline*(i+1)+1:length(msg)))
end
plotlab



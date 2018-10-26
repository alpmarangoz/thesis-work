clearvars
% close all hidden
clc

%% Simulation
dtmax = 10e-3 ;
dtFc = 10e-3 ;
tof = 50;
euler0 = [0 0 0]'*pi/180 ;
pqr0 = [0 0 0]'*pi/180 ;
Xe0 = [0 0 0]' ; % m
Vb0 = [0 0 0]' ; % m/s

q0 = [euler0 ; pqr0] ;
qdot0 = zeros(6,1) ;

%% Commands
r1 = (0:dtFc:tof)' ; ndatar = length(r1) ;
r1(:,2) = 1*ones(ndatar,1) ;
r1(:,3) = 15*ones(ndatar,1)*pi/180 ;
r1(:,4) = [10*ones(floor(ndatar/2),1)*pi/180 ; 10*ones(ceil(ndatar/2),1)*pi/180] ;
r1(:,5) = 0*ones(ndatar,1)*pi/180 ;
r = r1 ;


%% Plant Parameters
% Inertial properties from, Relaxed hover solutions for multicopters
IxxT = 2.7e-3 ; IyyT = IxxT ; IzzT = 5.2e-3 ; % kgm2
IxxP = 0 ; IyyP = IxxP ; IzzP = 1.5e-5 ; % kgm2
IxxB =  IxxT - 4*IxxP ; IyyB =  IyyT - 4*IyyP ; IzzB =  IzzT - 4*IzzP ;

m = 0.5 ; % kg
l = 0.17 ; % m

% Motor data
Kf = 6.41e-6 ; % Ns2/rad2 ;
Ktau = 1.72e-2 ; % Nm/N - Kf*Ktau  = 1.1e-7 Nms2/rad2
sigmaMot = 0.015 ; % s
flims = [0.2*0 3.8*2.5] ; % N

% Rotational Drag
Kdxx = 0.7e-4/10 ; % Nms2/rad2
Kdzz = 1.4e-4 ; % Nms2/rad2

a = (IzzT - IxxT)./ IxxT ;


% gravity
g = 9.81 ; % m/s2

%% Fault insertion
tfault = 5 ; faultyPropeller = [4] ;
faultyPropellerVec = [0 0 0 0] ;
for i = 1:length(faultyPropeller)
    faultyPropellerVec = faultyPropellerVec + ([1 2 3 4]==faultyPropeller(i)) ;
end
faultyPropellerVec = double(not(faultyPropellerVec)) ;


%% Nominal Controller
% attitudeControlFlag : 0 -> Reduced attitude control
% attitudeControlFlag : 1 -> Full attitude control
% attitudeControlFlag : 2 -> Full attitude control with Omega_R calculation (Problematic)
% attitudeControlFlag : 3 -> Full attitude control with wB_IB commands
% attitudeControlFlag : 4 -> Reduced attitude control with PD, from Burro,
%                               Murray and Sarti

attitudeControlFlag = 4 ;

Kp4 = 0.05 ;
Kv4 = 0.02 ;
% Proportional-Derivative Controller
Kp = 2*0.75*diag([1 1 1]) ;
Kv = 0*0.005*diag([1 1 1]) ;

%% State Estimator
xhat0 = [pqr0] ; xhatdot0 = zeros(3,1) ;
% nofstates = length(xhat0) ;
% As = zeros(nofstates,nofstates) ;
% As(1:3,1:3) = -30*eye(3) ;
As = -50*eye(3) ;

%% Distrubance Estimation
Dhat0 = zeros(3,1) ;

% Parameters for Chebyshev Polynomial Basis Function
nCheby = 3 ;

% Parameters for Basis function integration
Q = eye(3) ;
Ps = lyap(As',Q) ;
[temp,checkPtv] = chol(Ps)  ; % Check for positive definiteness
if checkPtv ~= 0
    error('Ps is not Positive definite')
end
GammaW = 10000 ; Wbnd = 10 ; epsilontheta = 0.1 ;
W0 = 0 ;

%% Fault Detection
Dlimit = 2.5 ; DSecondLimit = 2 ;
FDstart = 3 ;

%% FTC
Eulerc_ftc = [0 0 0]' ;
nc_ftc = 1 ;


%% FTC Perturbation Calculation Parameters for Single Propeller
% Third prop force
ftc_f2 = 0.1*2 ; % [N]

% w2 Controller
Aq = -20 ;
Bq = 1 ;
% sys = ss(Aq,Bq,1,0) ; step(sys)

% x1 Ref model
Arm = [-20 0 ; 0 -5] ;

% ADI parameters of singel propeller
alpha = 1 ; epsilon = 0.1 ;
Br = [1 0] ;
Ar = -10*eye(2)  ;

qp0 = 0 ;

%% Execute Simulation
try
    sim('simQuadrotor');
catch err
    disp('Error in simulation:')
    msg = err.message ;
    nline = 100 ;
    if length(msg) <= nline
        disp(msg)
    else
        for i = 0:floor(length(msg)/nline)-1
            disp(msg(max(1,nline*i+1):nline*(i+1)))
        end
        disp(msg(nline*(i+1)+1:length(msg)))
    end
    
end
plotlab2014


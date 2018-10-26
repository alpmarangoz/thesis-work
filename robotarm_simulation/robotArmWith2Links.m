clear all
close all hidden
clc

%% Sim parameters
tf = 1.4 ;
dt = 1e-3 ;
dtFC = dt ;
visualFlag = 0;
visualizationDataFlag = 1 ;


%% Plant Parameters
l1 = 1 ; l2 = 1 ;
m1 = 1 ; m2 = 1 ; I1 = 8.33e-2 ; I2 = 8.33e-2 ;
lc1 = l1/2 ; lc2 = l2/2 ;

c1 = 0; c2 = 0;
g = 9.81 ;

%% Initial conditions
q0  = [80 20]'*pi/180 ; % rad
qdot0 = [0 0]' ; % [rad/s]

%% Command Generator Parameters
tData = [0 tf]  ;
qcData(:,1) = tData  ;
qcData(:,2) = 90*[1 1]'*pi/180 ; % rad
qcData(:,3) = 0*[1 1]'*pi/180 ; % rad

qcdotData(:,1) = tData  ;
qcdotData(:,2) = [0 0]'*pi/180 ; % rad
qcdotData(:,3) = [0 0]'*pi/180 ; % rad
%

% clear tData qcData
% tData = 0:10*dt:tf ;
% qcData(:,1) = tData'  ;
% qcData(:,2) = (90+5*sin(2*pi*10*tData'))*pi/180 ; % rad
% qcData(:,3) = 0*ones(length(tData),1)*pi/180 ; % rad

%% Fault Mode
Bfault = [0 0; 0 1] ;

%% Controller Parameters


%% Nominal Controller
ksi = 2*0.7 ;
wn = 5*2*pi ;

K2 = wn^2 ;
K1 = 2*wn*ksi;

% % Controller
% u0 = zeros(1,1);
% umax = 1000*pi/180 ;
% umin = -1000*pi/180 ;

%% ADI Controller
epsilon = 0.5 ;
r0 = [0 0]' ; rmax = inf*[50*pi/180 inf]' ; rmin = -rmax ;

% Reference model
ksi = 0.7 ;
wn = 10*2*pi ;
Arm1 = [0 1; -wn^2 -2*ksi*wn] ;
Brm1 = [0 wn^2]' ;
% sysRefModel = ss(Arm1,Brm1,eye(2),0) ;
% figure ; step(sysRefModel)

% ADI parameters
alpha = 1 ;

Ar = [0 5; -30 -30] ;

try
    sim('simRobotArmWith2Links')
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





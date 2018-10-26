clear all
close all hidden
close all
clc

tof = 40 ;
dtSim = 1e-3 ;
dtController = dtSim ;

%% Reference signal
t = 0:dtSim:tof  ;
rData(:,1) = t ;
rData(:,2) = 1./(1+exp(t-8)) - 1.5./(1+exp(t-15)) + 1./(1+exp(t-30)) + 0.5 ;  
rData(:,3) = 1 ;

% rData(:,3) = -exp(t-8)./(1+exp(t-8)).^2 + 1.5.*exp(t-15)./(1+exp(t-15)).^2 - exp(t-30)./(1+exp(t-30)).^2 ;  
% rData(:,2) = 1.5 -  rData(:,2);
% rData(:,3) = -  rData(:,3);
clear t

% drdt = diff(rData(:,2))./diff(rData(:,1)) ;
% figure ; plot(rData(:,1),[0 ; drdt],'ro',rData(:,1),rData(:,3),'k')

%% Plant
x0 = [0 0]' ;

%% Controller
% Ref model
xr0 = 0 ;
Arm = -2 ;
Brm = 2 ;

% Controller
u0 = 0;
epsilon = 0.05 ;

% State Predictor
xhat0 = 0 ;

As = -10 ;
Q = eye(size(As)) ;
Ps = lyap(As',Q) ;
[temp,checkPtv] = chol(Ps)  ; % Check for positive definiteness
if checkPtv ~= 0
    error('Ps is not Positive definite')
end

% Adaptive Law
B = 1 ;
GammaW = 100 ;

Wbound = 10 ;

xis = -2:2 ;
uis = -2:2 ;
nofbasis = length(xis)*length(uis) ;
xu = zeros(nofbasis,2) ;
n = 0 ;
for i = 1:length(xis)
    for j = 1:length(uis)
        n = n+1 ;
        xu(n,1) = xis(i);
        xu(n,2) = uis(j);        
    end
end
clear i j n

W0 = zeros(nofbasis,1) ;

epsilontheta = 0.1 ;

%% Controller for x2
lambdae2 = 10 ;

clear all
close all hidden
clc


%% Simulation parameters
xm0 = zeros(2,1) ;
x0 = zeros(2,1) ;
tf = 40 ;

%% System Parameters
d0 = 1 ;

A = [0 1;0 0] ;
b = [0 ; d0] ;
c = [1 ; 1] ;


% Nonlinearity
tNonlinEnable = 50 ;

tNonlinChange = tNonlinEnable+10 ;

theta= [0 -0.018 0.015 -0.062 0.0095 0.021] ;

fx_p_x1_1 = [theta(6) 0 theta(2) theta(1)]; % [theta(1) theta(2) 0 theta(6)];
fx_p_x2_1 = [theta(3) 0] ;
fx_p_absx1x2_1 = [theta(4) 0] ;
fx_p_absx2x2_1 = [theta(5) 0] ;


theta= [4 -0.018 0.015 -0.062 0.0095 0.021] ;

fx_p_x1_2 = [theta(6) 0 theta(2) theta(1)];
fx_p_x2_2 = [theta(3) 0] ;
fx_p_absx1x2_2 = [theta(4) 0] ;
fx_p_absx2x2_2 = [theta(5) 0] ;

%% Reference Model Parameters
kx = [0.25 ; 0.707] ;
% bm = b ;

Am = A - b*kx' ;

bm=-b/(c'*inv(Am)*b);


% Am = [0 1;-0.25 -0.707];


%% Control Law Parameters
kxtld0 = zeros(2,1) ; kxtld0 = [200 200]' ;
kg0 = 1 ;
kphi0 = [1 0 0 0 0 0]' ; kphi0 = [1 1 1 1 1 1]';


Q = eye(size(Am)) ;
P = lyap(Am',Q) ;

[temp,checkPtv] = chol(P)  ; % Check for positive definiteness
if checkPtv ~= 0
    error('P is not Positive definite')
end

%% Adaptation Law Parameters

Gamma_kg = 1;
Gamma_kx = 1*eye(2,2);
Gamma_PHI = 1*eye(length(kphi0),length(kphi0));









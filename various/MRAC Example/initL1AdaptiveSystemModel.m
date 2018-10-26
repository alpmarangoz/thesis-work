clear all
close all hidden
clc


%% Simulation parameters
xhat0 = zeros(2,1) ;
x0 = zeros(2,1) ;
tf = 100 ;

%% System Parameters
d0 = 1 ;

A = [0 1;0 0] ;
b = [0 ; d0] ;
c = [1 ; 1] ;


% Nonlinearity
tNonlinEnable = 0 ;

tNonlinChange = 10 ;

theta= [0 -0.018 0.015 -0.062 0.0095 0.021] ;

fx_p_x1_1 = [theta(6) 0 theta(2) theta(1)]; % [theta(1) theta(2) 0 theta(6)];
fx_p_x2_1 = [theta(3) 0] ;
fx_p_absx1x2_1 = [theta(4) 0] ;
fx_p_absx2x2_1 = [theta(5) 0] ;


theta= [2 -0.018 0.015 -0.062 0.0095 0.021] ;

fx_p_x1_2 = [theta(6) 0 theta(2) theta(1)];
fx_p_x2_2 = [theta(3) 0] ;
fx_p_absx1x2_2 = [theta(4) 0] ;
fx_p_absx2x2_2 = [theta(5) 0] ;

%% Reference Model Parameters
kx = [0.25 ; 0.707] ;

Am = A - b*kx' ;
% Am = [0 1;-0.25 -0.707];


%% Control Law Parameters
ththat0 = ones(5,1) ;

Cs_num = 25 ;
Cs_den = [1 25] ;

Q = eye(size(Am)) ;
P = lyap(Am',Q) ;

[temp,checkPtv] = chol(P)  ; % Check for positive definiteness
if checkPtv ~= 0
    error('P is not Positive definite')
end

%% Adaptation Law Parameters
Gamma = 20;
kg = -(c'*(Am^-1)*b).^-1 ;








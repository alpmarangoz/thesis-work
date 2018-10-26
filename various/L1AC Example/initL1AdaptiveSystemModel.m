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

% Functions for nonlinearity:
% 1 x1 x2 |x1|x2 |x2|x2 x1^3
% Coefficients:
theta= [0 -0.018 0.015 -0.062 0.0095 0.021] ;
theta2= [4 -0.018 0.015 -0.062 0.0095 0.021] ;


%% Static feedback gain
km = [0.25 ; 0.707] ;

Am = A - b*km' ;
%% Control Law Parameters
ththat0 = zeros(6,1) ;

Cs_num = 25 ;
Cs_den = [1 25] ;

Q = eye(size(Am)) ;
P = lyap(Am',Q) ;

[temp,checkPtv] = chol(P)  ; % Check for positive definiteness
if checkPtv ~= 0
    error('P is not Positive definite')
end

%% Adaptation Law Parameters
Gamma = 100;
kg = -(c'*(Am^-1)*b).^-1 ;




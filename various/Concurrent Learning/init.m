clear all
close all hidden
close all
clc

tof = 60 ;
x0 = [1 1]' ; r = 1 ; tr = [20 25] ;

%Ref model
ksi = 1 ; wn = 1 ;
Arm = [0 1;-wn^2 -2*ksi*wn] ; Brm = [0 wn^2]' ;

% Controller
K = [1.5 0;0 1.3] ;
A = -K ;

Q = eye(size(A)) ;
P = lyap(A',Q) ;

[temp,checkPtv] = chol(P)  ; % Check for positive definiteness
if checkPtv ~= 0
    error('P is not Positive definite')
end

p = 10 ;
GammaW = 3.5 ;
% W0 = [1 -1 0.5]' ;
W0 = [2 -0.5 1]' ;
B = [0 1]' ;

epsilon = 0.08 ;



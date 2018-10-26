clear all
close all hidden
close all
clc

tof = 60 ;

%% Reference signal
dreps = 1e-3 ;
rData= [0   20   20+dreps 25   25+dreps tof ; ...
        0   0    1       1     0        0 ; ...
        0   0    0       0     0        0 ]' ;
if rData(length(rData),1)<= rData(length(rData)-1,1)
    rData(length(rData),:) = [] ;
end
rData(:,3) = rData(:,2) ;
rData(:,2) = 0;


x0 = [1 1]' ;

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

pMax = 10 ;
GammaW = 3.5 ;
% W0 = [1 -1 0.5]' ;
W0 = [2 -0.5 1 ; 0 0 0]' ;
B = [0 0 ; 0 1] ;
nofbasis = 3 ;
nofstates = 2 ;
epsilon = 0.08 ;



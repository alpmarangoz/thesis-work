clear all
% close all hidden
clc

%% Simulation
dtmax = 10e-3 ;
dtFc = 10e-3 ;
tof = 5;
euler0 = [-10 30 0]'*pi/180 ;
pqr0 = [0 0 0]'*pi/180 ;
Xe0 = [0 0 0]' ; % m
Vb0 = [0 0 0]' ; % m/s

q0 = [euler0 ; pqr0] ;
qdot0 = zeros(6,1) ;

%% Commands
r1 = (0:dtFc:tof)' ; ndatar = length(r1) ;
r1(:,2) = 1*ones(ndatar,1) ;
r1(:,3) = 0*ones(ndatar,1)*pi/180 ;
r1(:,4) = 0*ones(ndatar,1)*pi/180 ;
r1(:,5) = 0*ones(ndatar,1)*pi/180 ;
r = r1 ;


%% Plant Parameters
% Inertial properties from, Relaxed hover solutions for multicopters
IxxT = 2.7e-3 ; IyyT = IxxT ; IzzT = 5.2e-3 ; % kgm2
m = 0.5 ; % kg


% Control gains % : A Good set..Kp = 0.05 ; Kv = 0.02 ;
Kp = 0.05 ;
Kv = 0.02 ;

%% Execute Simulation
try
    sim('simAttitudeControl');
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
plotlab


clear all
close all hidden
close all
clc

tof = 15 ;
dtSim = 10e-3 ;
dtController = dtSim ;

%% Reference signal
t = 0:dtSim:tof  ;
rData(:,1) = t ;
rData(:,2) = 0 ;
rData(:,3) = 0.1*sin(2*pi*t*1) ;
rData(:,3) = 0.0 ;
clear t

% drdt = diff(rData(:,2))./diff(rData(:,1)) ;
% figure ; plot(rData(:,1),[0 ; drdt],'ro',rData(:,1),rData(:,3),'k')

%% Plant
a = -1 ; b = 1 ; c = -1 ;

x0 = [0.1 0.1 0.1]' ;
% x0 = [0.5 0.5]' ;
x0 = 1*x0 ;
intLimit = 10 ;

%% x3 Controller
K2 = -2 ;

% Initial output
u0 = 0;

%% ADI Controller
epsilon = 0.1 ;
r0 = [0 0]' ; rmax = 10000 ; rmin = -rmax ;
Arm1 = 10*[-2 1 ; 1 -1] ;
Arm1 = 10*[-1 0 ; 0 -1] ;
% Arm1 = 10*[-5 0 ; 0 -1] ;
Arm1 = Arm1 + [0 a*max(abs(rData(:,3))) ; b*max(abs(rData(:,3))) 0] ;
alpha = 1 ;
Ar = -5; % [-2 0 ; 0 -2] ;


sim('sim_main_pqr')
plotlab


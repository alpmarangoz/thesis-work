clear all
close all
clc


%% The system
A = [0 1; -1 -1.4] ;
b = [0 ; 1] ;
c = [1 ; 0] ;
d = 0 ;
tht = [-4 ; 4.5] ; % nonlinearity


%% Controller 
% Non-adaptive gain
km = [0 0]' ;

% Adaptation law
Gamma = 10000 ;
THT = [-10 10] ;

% Low Pass Filter
wc = 160 ;
C = tf(wc,[1 wc]);

x0 = [0 0]' ;
dt = 1e-3 ;
Tfinal = 10 ;
t = 0:dt:Tfinal ;
r = 25*ones(length(t),1) ;

[ydes,xdes,udes] = simDesSystem(A,b,c,d,tht,km,C,r,t,x0) ;


figure ; plot(t,ydes,'r-',t,r,'ko') ; grid on ;  title('ydes')
figure ; plot(t,xdes) ; grid on ;  legend(getLegend(xdes)) ; title('xdes')
figure ; plot(t,udes) ; grid on ;   title('udes')


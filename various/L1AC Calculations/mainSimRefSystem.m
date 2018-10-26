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
[y1,x1,uref1] = simRefSystem(A,b,c,d,tht,km,C,r,t,x0) ;
r = 100*ones(length(t),1) ;
[y2,x2,uref2] = simRefSystem(A,b,c,d,tht,km,C,r,t,x0) ;
r = 400*ones(length(t),1) ;
[y3,x3,uref3] = simRefSystem(A,b,c,d,tht,km,C,r,t,x0) ;


figure ; plot(t,y1,'k-',t,y2,'k-.',t,y3,'k--') ; grid on ; legend({'r=25';'r=100';'r=400'}) ; title('y')
figure ; plot(t,uref1,'k-',t,uref2,'k-.',t,uref3,'k--') ; grid on ; legend({'r=25';'r=100';'r=400'}) ; title('uref')

Tfinal = 50 ;
t = 0:dt:Tfinal ;
r = 100*cos(0.2*t) ;
[y,x,uref] = simRefSystem(A,b,c,d,tht,km,C,r,t,x0) ;
figure ; plot(t,y,'k-',t,r,'r') ; grid on ; title('y') ; legend('y','r')
figure ; plot(t,uref,'k-') ; grid on ; title('uref')

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
rLaplace = 25*tf(1,[1 0]) ;

[lambda,gamma1,gamma2] = getL1RefBounds(A,b,tht,km,C,THT,Gamma);
upBoundxrefmx = gamma1/sqrt(Gamma) ;
upBoundurefmu = gamma2/sqrt(Gamma) ;

[ybound,xbound,ubound] = getL1DesBounds(A,b,c,tht,x0,r,km,C,lambda,1) ;

[ydes,xdes,udes] = simDesSystem(A,b,c,d,tht,km,C,r,t,x0) ;
[yref,xref,uref] = simRefSystem(A,b,c,d,tht,km,C,r,t,x0) ;

disp(['|ydes-yref|_Linf <= ' num2str(ybound) ' (Calculated), ' ...
    num2str(norm(ydes-yref,inf)) ' (Simulated) ' ])
disp(['|xdes-xref|_Linf <= ' num2str(xbound) ' (Calculated), ' ...
    num2str(norm(xdes-xref,inf)) ' (Simulated) ' ])
disp(['|udes-uref|_Linf <= ' num2str(ubound) ' (Calculated), ' ...
    num2str(norm(udes-uref,inf)) ' (Simulated) ' ])





figure ; plot(t,xdes,t,xref) ;
legend('Design system (1)','Design system (2)','Reference System (1)','Reference System (2)')
ylabel('x') ; xlabel('t [s]') ; title('Design system and Reference System')
figure ; plot(t,ydes,t,yref) ;
legend('Design system','Reference System')
ylabel('y') ; xlabel('t [s]') ; title('Design system and Reference System')
figure ; plot(t,ydes,t,yref,t,r) ;
legend('Design system','Reference System','Command')
ylabel('y') ; xlabel('t [s]') ; title('Design system and Reference System')
figure ; plot(t,udes,t,uref) ;
legend('Design system','Reference System')
ylabel('u') ; xlabel('t [s]') ; title('Design system and Reference System')

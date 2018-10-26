clearvars
close all
clc
g = 9.81 ;

% Inertial properties
IxxT = 3.2e-3 ; IyyT = IxxT ; IzzT = 5.5e-3 ; % kgm2
IxxP = 0 ; IyyP = IxxP ; IzzP = 1.5e-5 * 1e-6 ; % kgm2
IxxB =  IxxT - 4*IxxP ; IyyB =  IyyT - 4*IyyP ; IzzB =  IzzT - 4*IzzP ;

m = 0.5 ; % kg
l = 0.17 ; % m

% Motor data
Kf = 6.41e-6 ; % Ns2/rad2 ;
Ktau = 1.69e-2 ; % Nm/N

% Rotational Drag
Kdxx = 0.7e-4 ; % Nms2/rad2
Kdzz = 1.4e-4 ; % Nms2/rad2

a = (IzzT - IxxT)./ IxxB ;
b = Ktau/IxxB ;
c = l/IxxB ;

Ftot = m*g ;

f2 = linspace(0,Ftot/3,100) ;
twoF = Ftot - f2 ;
rbar = sqrt(b/Kdzz*(twoF-f2)) ;
d = c*f2 ;

figure ; 
plot(f2,rbar,'r',f2,rbar*a,'b--') ; grid on
hlgnd = legend('$\bar r$','$a \cdot \bar r$') ;
set(hlgnd,'interpreter','latex','fontsize',14)
ylabel('$\bar r, a \bar r$ [rad/s]','interpreter','latex','fontsize',14) ; 
xlabel('$f_2$[N]','interpreter','latex','fontsize',14) ; 


figure ; 
plot(f2,d,'r') ; grid on
xlabel('$f_2[N]$','interpreter','latex','fontsize',14) ; 
ylabel('$d [rad/s^2]$','interpreter','latex','fontsize',14) ; 

figure ; 
plot(f2,d./a./rbar,'r') ; grid on
xlabel('$f_2[N]$','interpreter','latex','fontsize',14) ; 
ylabel('$\bar q = \frac{d}{a \bar r}$ [rad/s]','interpreter','latex','fontsize',14) ; 

gammaf = linspace(min(a.*rbar),max(a.*rbar),3) ;
gammaf = round(gammaf/10)*10 ;
legendstr = [] ;

lambday = linspace(150,350,20) ;
for j = 1:length(gammaf)
for i = 1:length(lambday)
    Ar = -lambday(i) ;
    Q = 1 ; P = lyap(Ar,Q) ;
    chk(j,i) = Q./(2*P) - gammaf(j) ;
end
legendstr{j} = ['\gamma_f = ' num2str(gammaf(j))] ;
end

figure ; plot(-lambday,chk) ; grid on
xlabel('$A_r$','interpreter','latex','fontsize',14) ;  
ylabel('$\frac{1}{2\lambda_{max}(P)} - \gamma_f$','interpreter','latex','fontsize',14) ; 
legend(legendstr)
hax = gca ;


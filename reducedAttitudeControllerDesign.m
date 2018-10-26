% clearvars

systemFlag = 1 ;

switch systemFlag
    case 1
        % Inertial properties from, Relaxed hover solutions for multicopters 
        IxxT = 2.7e-3 ; IyyT = IxxT ; IzzT = 5.2e-3 ; % kgm2
        IxxP = 0 ; IyyP = IxxP ; IzzP = 1.5e-5 ; % kgm2
        IxxB =  IxxT - 4*IxxP ; IyyB =  IyyT - 4*IyyP ; IzzB =  IzzT - 4*IzzP ;

        m = 0.5 ; % kg
        l = 0.17 ; % m
        
        % Motor data
        Kf = 6.41e-6 ; % Ns2/rad2 ;
        Ktau = 1.72e-2 ; % Nm/N - Kf*Ktau  = 1.1e-7 Nms2/rad2
        sigmaMot = 0.015 ; % s
        flims = [0.2*0 3.8*1.5] ; % N
        
        % Rotational Drag
        Kdxx = 0.7e-4/100 ; % Nms2/rad2
        Kdzz = 1.4e-4 ; % Nms2/rad2
        
    case 2        
        % Inertial properties
        IxxP = 0 ; IyyP = IxxP ; IzzP = 1.5e-5 * 1e-6 ; % kgm2
        IxxB = 0.0820 ; IxxT = IxxB + 4*IxxP ;
        IyyB = 0.0845 ; IyyT = IyyB + 4*IyyP ;
        IzzB = 0.1377 ; IzzT = IzzB + 4*IzzP ;
        
        m = 4.34 ; % kg 
        l = 0.315 ; % m
        
        % Motor data
        Kf = 4.e-5 ; % Ns2/rad2 ;
        Ktau = 8.e-4  ; % Nm/N
        sigmaMot = 0.015*0 ; % s
        flims = [0.2 100] ; % N
    
        % Rotational Drag
        Kdxx = 0.7e-4 ; % Nms2/rad2
        Kdzz = 1.4e-4 ; % Nms2/rad2        
end
a = (IzzT - IxxT)./ IxxB ;
b = Ktau/IxxB ;
c = l/IzzB ;

J = [IxxT 0 0 ; 0 IyyT 0 ; 0 0 IzzT] ;
distmax = 90*pi/180 ;
wMax = [3 3 3]'; %.*pi/180 ;

kplim = wMax'*(J*wMax)./(pi^2 - distmax.^2) ;
disp(['kp should be greater than ' num2str(kplim)])

m0 = J*wMax ;
m0norm2 = m0'*m0 ;
dbar = m0norm2./(2*J(3,3)*kplim) ;
disp(['dist converges to ' num2str(dbar) ' with kp: ' num2str(kplim)])

kps = linspace(kplim,200*kplim,10) ;
dbars = m0norm2./(2*J(3,3)*kps) ;
disp(' ')
disp(['kps: ' num2str(kps)])
disp(['dbars: ' num2str(dbars)])


% Controllability..
w3 = 1 ;
A = [0 0 0 1 ; 0 0 -1 0 ; 0 0 0 -a*w3 ; 0 0 a*w3 0] ;
B = [0 0 0 1]' ;
C = eye(4) ;
Co=ctrb(A,B);
% Number of uncontrollable states
unco=length(A)-rank(Co) ;


[Abar,Bbar,Cbar,T,k] = ctrbf(A,B,C) ;



















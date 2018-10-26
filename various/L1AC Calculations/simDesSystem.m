function [yout,xout,udesout] = simDesSystem(A,b,c,d,tht,km,C,r,t,x0)

Cnum = cell2mat(get(C,'num')) ;
Cden = cell2mat(get(C,'den')) ;
[CA,CB,CC,CD] = tf2ss(Cnum,Cden) ;
Css  = ss(CA,CB,CC,CD) ;

Am = A - b*km' ;
kg = -1/(c'*(Am^-1)*b) ;

c1 = eye(size(A,2)) ; 

sys = ss(A,b,c1',d) ; 
thtss = ss([],[],[],tht') ;

sys2 = feedback(sys,Css*thtss,+1) ;


sys2p = sys2 ;
d1 = [get(sys2p,'d') ; 1] ;
c1 = eye(size(get(sys2p,'a'),1)) ; % [get(sys2p,'c') ; zeros(1,size(A,2))] ;

set(sys2p,'d',d1,'c',c1)
sys2p.InputName = 'udes' ;
sys2p.OutputName = {'xdes1' ; 'xdes2' ; 'yudes'} ;

sys3fb = ss([],[],[],km') ;
sys3fb.InputName = {'xdes1' ; 'xdes2'} ;
sys3fb.OutputName = {'xdeskmT'} ;

sys3sum = sumblk('udes','ulp','xdeskmT','+-') ;
sys3 = connect(sys2p,sys3fb,sys3sum,'ulp', {'xdes1' ; 'xdes2' ; 'yudes'} ) ;


CssFP  = Css ;
CssFP.InputName = 'u1';  CssFP.OutputName = 'ulp' ;

sys4Lp = connect(sys3,CssFP,'u1', {'xdes1' ; 'xdes2' ; 'yudes'} ) ;
sys4fb =  ss([],[],[],tht') ;
sys4fb.InputName = {'xdes1' ; 'xdes2'} ;
sys4fb.OutputName = {'xdesThtT'} ;
sys4sum = sumblk('u1','rscaled','xdesThtT','+-') ;
sys4 = connect(sys4Lp,sys4fb,sys4sum,'rscaled', {'xdes1' ; 'xdes2' ; 'yudes'} ) ;

sys5 = ss([],[],[],kg) ;
sys5.InputName  = {'r'} ;
sys5.OutputName = {'rscaled'} ;

Gxdes = connect(sys5,sys4,'r', {'xdes1' ; 'xdes2' ; 'yudes'} ) ;

sys6 = ss([],[],[],[c ; 0]') ;
sys6.InputName  = {'xdes1' ; 'xdes2' ; 'yudes'} ;
sys6.OutputName = {'ydes'} ;
Gdes = connect(Gxdes,sys6,'r', {'xdes1'} ) ;

x0sim = [x0 ; 0 ; 0]' ;

[y,tout,x] = lsim(Gdes,r,t,x0sim) ;

xout = x(:,1:size(x,2)-2) ;
udesout =  x(:,size(x,2)) ;
yout = y ;




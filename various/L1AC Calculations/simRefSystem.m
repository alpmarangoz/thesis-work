function [yout,xout,urefout] = simRefSystem(A,b,c,d,tht,km,C,r,t,x0)


Am = A - b*km' ;
kg = -1/(c'*(Am^-1)*b) ;

c1 = eye(size(A,2)) ; 

sys = ss(A,b,c1',d) ;
sys2 = feedback(sys,ss([],[],[],tht'),+1) ;

sys2p = sys2 ;
d1 = [get(sys2p,'d') ; 1] ;
c1 = [get(sys2p,'c') ; zeros(1,size(A,2))] ;

set(sys2p,'d',d1,'c',c1)
sys2p.InputName = 'uref' ;
sys2p.OutputName = {'xref1' ; 'xref2' ; 'yuref'} ;

sys3fb = ss([],[],[],km') ;
sys3fb.InputName = {'xref1' ; 'xref2'} ;
sys3fb.OutputName = {'xrefkmT'} ;

sys3sum = sumblk('uref','ulp','xrefkmT','+-') ;
sys3 = connect(sys2p,sys3fb,sys3sum,'ulp', {'xref1' ; 'xref2' ; 'yuref'} ) ;

Cnum = cell2mat(get(C,'num')) ;
Cden = cell2mat(get(C,'den')) ;
[CA,CB,CC,CD] = tf2ss(Cnum,Cden) ;
Css  = ss(CA,CB,CC,CD) ;
Css.InputName = 'u1';  Css.OutputName = 'ulp' ;

sys4Lp = connect(sys3,Css,'u1', {'xref1' ; 'xref2' ; 'yuref'} ) ;
sys4fb =  ss([],[],[],tht') ;
sys4fb.InputName = {'xref1' ; 'xref2'} ;
sys4fb.OutputName = {'xrefThtT'} ;
sys4sum = sumblk('u1','rscaled','xrefThtT','+-') ;
sys4 = connect(sys4Lp,sys4fb,sys4sum,'rscaled', {'xref1' ; 'xref2' ; 'yuref'} ) ;

sys5 = ss([],[],[],kg) ;
sys5.InputName  = {'r'} ;
sys5.OutputName = {'rscaled'} ;

Gxref = connect(sys5,sys4,'r', {'xref1' ; 'xref2' ; 'yuref'} ) ;

sys6 = ss([],[],[],[c ; 0]') ;
sys6.InputName  = {'xref1' ; 'xref2' ; 'yuref'} ;
sys6.OutputName = {'yref'} ;
Gref = connect(Gxref,sys6,'r', {'xref1'} ) ;

x0sim = [x0 ; 0]' ;

[y,tout,x] = lsim(Gref,r,t,x0sim) ;
xout = x(:,1:size(x,2)-1) ;
urefout =  x(:,size(x,2)) ;
yout = y ;

% keyboard


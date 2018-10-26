function G_L1 = getL1norm(G,flag)

if nargin<2
    flag = 0 ;
end

[y,t] = impulse(G) ;
t1 = 0:1e-3:max(t) ;
[y,t] = impulse(G,t1) ;
G_L1 = reshape(squeeze(trapz(t,abs(y),1)),size(G)) ;


if flag == 0
    G_L1 = max(sum(G_L1,1)) ;
end


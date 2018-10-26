
gammaf = sqrt(2) ;

w3 = 0:1:10 ;
gammaf = sqrt(1+w3.^2) ;
lambday = linspace(1,20,20) ;
for j = 1:length(gammaf)
for i = 1:length(lambday)
    Ar = -lambday(i) ;
    Q = 1 ; P = lyap(Ar,Q) ;
    chk(i) = Q./(2*P) - gammaf(j) ;
    par(i) = Q./(2*P) ;
end
Armax(j) = -min(lambday(chk > 0)) ;
end
figure ; plot(gammaf,Armax) ; grid on
xlabel('$\sqrt{1+ \omega_3^2}$','interpreter','latex','fontsize',14) ;  
ylabel('$\lambda_{max}(A_r)$','interpreter','latex','fontsize',14) ; 

% figure ; plot(-lambday,chk) ; grid on
% xlabel('$A_r$','interpreter','latex','fontsize',14) ;  
% ylabel('$\frac{1}{2\lambda_{max}(P)} - \gamma_f$','interpreter','latex','fontsize',14) ; 
% 
% figure ; plot(-lambday,par) ; grid on
% xlabel('$A_r$','interpreter','latex','fontsize',14) ;  
% ylabel('$\frac{1}{2\lambda_{max}(P)}$','interpreter','latex','fontsize',14) ; 



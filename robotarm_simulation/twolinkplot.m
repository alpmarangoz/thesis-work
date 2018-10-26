function out = twolinkplot(u)
out = 0 ;


x = u(1:3,1) ;
y = u(4:6,1) ;
l1l1c = u(7) ;
l2l2c = u(8) ;
lim = u(9) ;

if u(10) 
    xcg(1) = x(2)*l1l1c ;
    xcg(2) = (x(3)-x(2))*l2l2c+x(2) ;
    ycg(1) = y(2)*l1l1c ;
    ycg(2) = (y(3)-y(2))*l2l2c+y(2) ;
    
plot(x,y,'k ','LineWidth',4)
hold on
plot(x(1),y(1),...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','w',...
    'Marker','o',...
    'MarkerSize',10)
plot(x(2),y(2),...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','r',...
    'Marker','o',...
    'MarkerSize',10)
plot(xcg,ycg,'ko',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','k',...
    'Marker','o',...
    'MarkerSize',6)
hold off

grid on
axis([-lim lim -lim lim])

end



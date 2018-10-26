function linelabel(hp,labelstr,location)

% hp : Plot handle
% labelstr : Cell array of labels..
% location : Array of numbers between 0 and 1 . 
%       0: Label will be be placed at the minimum x value. 
%       1: Label will be be placed at the maximum x value. 

if not(length(labelstr) < length(location))
    location(length(location)+1:length(labelstr)) = location(length(location)) ;
end
 
nstr = length(labelstr);

dar = daspect ;
ac = dar(2)./dar(1) ;

for i = 1:nstr
    x = get(hp(i),'XData') ;
    y = get(hp(i),'YData') ;
    ndata = length(x) ;
    x1 = location(i)*(max(x)-min(x)) + min(x) ;
    y1 = interp1(x,y,x1) ;
    
    htxt = text(x1,y1,labelstr{i}) ;
    R = get(htxt,'extent');
    R = R(4) ;
    
    % Find the x location where the text crosses the function
    ilbl = interp1(x,1:ndata,x1,'nearest') ;
    dy1dx1 = (y(ilbl+1)-y(ilbl))./(x(ilbl+1)-x(ilbl)) ;
    angle =  atan(dy1dx1) ;
    x2 = x1 + R*cos(angle) ;
    fx2 = interp1(x,y,x2,'spline') ;
    slope = (fx2 - y1)./(x2-x1) ;
    
%     % Newton Raphson to find the crossing point..
%     % set x2 fx2 as the initial guess
%     j = 0 ;
%     df = 100 ;
%     dx = x2*0.01 ;
% 
%     while and(df > 0.01,j<10)
%         f = (x2 - x1).^2 + (fx2 - y1).^2 - R.^2 ;
%         fx2p = interp1(x,y,x2+dx,'spline','extrap') ;
%         fp = (x2 + dx - x1).^2 + (fx2p - y1).^2 - R.^2 ;
%         dfdx = (fp-f)./dx ;
%         x2n = x2 - f./dfdx ;
%         fx2n = interp1(x,y,x2n,'spline','extrap') ;
%         df = abs((x2n - x1).^2 + (fx2n - y1).^2 - R.^2) ;
%         slope = (fx2n - y1)./(x2n-x1) ;
%         j = j + 1;
%         bk_df(j) = df ;      
%         x2 = x2n ;
%         fx2 = fx2n ;
%     end
        
    dy2dx2 = slope./ac ;
    angle = atan(dy2dx2).*180/pi ; 
    set(htxt,'Rotation',angle) ;
    set(htxt,'BackgroundColor',[1 1 1]);
    set(htxt,'FontSize',8) ;

end


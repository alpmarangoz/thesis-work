aviFlag = 0 ;

tData = thetaForVisualization.time ;
tht1Data = squeeze(thetaForVisualization.signals.values(1,:,:)) ;
tht2Data = squeeze(thetaForVisualization.signals.values(2,:,:)) ;
% tht1Data = thetaForVisualization.signals.values(:,1) ;
% tht2Data = thetaForVisualization.signals.values(:,2) ;

tht2Data = tht2Data + tht1Data ;


y0 = zeros(length(tData),1) ;
x0 = zeros(length(tData),1) ;
y1 = l1*sin(tht1Data) ;
x1 = l1*cos(tht1Data) ;
y2 = l2*sin(tht2Data)+y1 ;
x2 = l2*cos(tht2Data)+x1 ;
l1l1c = 0.5*l1/l1*ones(length(tData),1) ;
l2l2c = 0.5*l2/l2*ones(length(tData),1) ;
visuallim = (l1+l2)*ones(length(tData),1) ;
enable = ones(length(tData),1) ;

uvisual = [x0 x1 x2 y0 y1 y2 l1l1c l2l2c visuallim enable]' ;

fps = 20 ; % frames per second
trttotal = 5 ; % real time visualization duration (approx)
ibk = round(linspace(1,length(tData),fps*trttotal)) ;

fig = figure ;

if aviFlag == 1
    aviobj = avifile('example.avi') ;
end

tTotal = tic ;

for i = 1:length(ibk)
    tic
    out = twolinkplot(uvisual(:,ibk(i))) ;
    title(['t = ' num2str(tData(ibk(i)))])
    pause(1/fps-toc)
    if aviFlag == 1
        F = getframe(fig);
        aviobj = addframe(aviobj,F);
    end
    %     break
end
toc(tTotal)

if aviFlag == 1
aviobj = close(aviobj);
end
% close(fig)

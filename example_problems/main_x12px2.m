clear all
close all hidden
close all
clc

tof = 100 ;
dtSim = 1e-3 ;
dtController = dtSim ;

%% Reference signal
t = 0:dtSim:tof  ;
rData(:,1) = t ;
rData(:,2) = 0 ;
rData(:,3) = sin(2*pi*t*1) ;
rData(:,3) = 0 ;
clear t

% drdt = diff(rData(:,2))./diff(rData(:,1)) ;
% figure ; plot(rData(:,1),[0 ; drdt],'ro',rData(:,1),rData(:,3),'k')

%% Plant
x0 = [0.1 0.1]' ;
% x0 = [0.5 0.5]' ;
x0 = 10*x0 ;
intLimit = 10 ;

%% x2 Controller
K2 = -10 ;

% Initial output
u0 = 0;

%% ADI Controller
epsilon = 0.1 ;
r0 = 0 ; rmax = 10000 ; rmin = -rmax ;
Arm1 = -2 ;
alpha = -1 ;
Ar = 0 ;


sim('sim_main_x12px23')
plotlab


return
%%
Arv = [-1:0.05:1] ;
for i = 1:length(Arv)
    Ar = Arv(i) ;
    % Execute Simulation
    sim('sim_main_x12px23')
    x1inf(i) = interp1(logsout.System.x.Time,logsout.System.x.Data(1,:),tof) ;
    x2inf(i) = interp1(logsout.System.x.Time,logsout.System.x.Data(2,:),tof) ;
end

figure ; plot(Arv,x1inf,'r--',Arv,x2inf,'b-.') ;  grid on
hold on ; plot(Arv,-sqrt(x1inf).^2,'ko')

return
%%
tx1bk = logsout.System.x.Time ;
x1bk = logsout.System.x.Data(1,:) ;
x2_x1bk = -x1bk.^2 ;
figure ; plot(x1bk,x2_x1bk,'r--') ;  grid on

%%
Arv = [-1:0.1:0.7] ;
Arv = [-1 -0.75 -0.5 0 0.5 0.75] ;
Arv = round(Arv*100)/100 ;
for i = 1:length(Arv)
    Ar = Arv(i) ;
    % Execute Simulation
    sim('sim_main_x12px23')
    x1inf(i,:) = logsout.System.x.Data(1,:) ;
    x2inf(i,:) = logsout.System.x.Data(2,:) ;
end

switch 1
    case 1
        inds = 1:length(Arv) ;
    case 2
inds = unique(round(linspace(1,length(Arv),5))) ;
i0 = find(Arv == 0);
if not(isempty(i0))
    if not(sum(inds == i0))
        inds = [inds i0] ;
        inds = sort(inds) ;
    end
end
end


figure ;
for i = 1:length(inds)
    hp(i) = plot(x1inf(inds(i),:),x2inf(inds(i),:),'k--') ;
    if i == 1, hold all, end
    labelstr{i} = ['A_r: ' num2str(round(Arv(inds(i))*100)/100) ]  ;
end
x1bk = linspace(floor(min(min(x1inf))*10)/10,...
    ceil(max(max(x1inf))*10)/10,100) ;
x2_x1bk = Arm1*x1bk - x1bk.^2 ;
hp(i+1) = plot(x1bk,x2_x1bk,'r-') ;
labelstr{i+1} = 'x_2 = A_{rm1} x_1 - x_1^2' ;

grid on

linelabel(hp,labelstr,0.5)
xlabel('x_1'), ylabel('y_1')
return
%%
run(['..\fixfigforArticle.m'])

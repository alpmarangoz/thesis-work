clear all
close all
clc


% f = @(x1,x2,a,b) [a*ones(1,length(x1)); x1.^3+b];

% dx1dt = @(x1,x2) [x1+ x2.^3];
% dx2dt = @(x1,x2) [zeros(size(x1))];
% dx1dt = @(x1,x2) [x1.*x2.^3];
% dx2dt = @(x1,x2) [x2.^2];
dx1dt = @(x1,x2) [x1 + x2.^3];
dx2dt = @(x1,x2) [x2.^2];
dfdt = @(t,x) [dx1dt(x(1),x(2)) ; dx2dt(x(1),x(2))];

%% Trajectory calculaton
y01 = [1 ; 1]*0.1 ; 
[tout,yout1] = ode45(dfdt,[0 200],y01) ;
y02 = [-1 ; -1]*1 ;
[tout,yout2] = ode45(dfdt,[0 200],y02) ;


%% Phase space calculations
x1 = linspace(-2,2,20) ;
x2 = linspace(-2,2,20) ;

[x,y] = meshgrid(x1,x2);
f1 = dx1dt(x,y) ;
f2 = dx2dt(x,y) ;


%% Draw the figure
figure ; quiver(x,y,f1,f2,'r');
% quiver(x1,x2,f1,f2,'b'); figure(gcf)
grid on
xlabel('x_1')
ylabel('x_2')
% axis tight equal;

% Draw the trajcetories
hold on
plot(yout1(:,1),yout1(:,2),'k--')
plot(yout2(:,1),yout2(:,2),'b--')

axis([min(x1) max(x1) min(x2) max(x2) ])













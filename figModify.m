clear all ; close all hidden ; clc
load logsout_00 ; logsout0 = logsout ;
load logsout_01 ; logsout1 = logsout ;
load logsout_02 ; logsout2 = logsout ;

%%
varname =  'qp [rad/s]' ;
a = logsout0.Controller ;
a = get(a,'FTC Controller') ;
a = get(a,'SingleProp Compensation') ;
var0 = a.qp ;

a = logsout1.Controller ;
a = get(a,'FTC Controller') ;
a = get(a,'SingleProp Compensation') ;
var1 = a.qp ;

a = logsout2.Controller ;
a = get(a,'FTC Controller') ;
a = get(a,'SingleProp Compensation') ;
var2 = a.qp ;


%%
eval(['x0 = var0.Time ;']) ;
eval(['y0 = var0.Data ;']) ;
y0 = squeeze(y0) ;

eval(['x1 = var1.Time ;']) ;
eval(['y1 = var1.Data ;']) ;
y1 = squeeze(y1) ;

eval(['x2 = var2.Time ;']) ;
eval(['y2 = var2.Data ;']) ;
y2 = squeeze(y2) ;

figure ; plot(x0,y0,x1,y1,x2,y2) ; grid on 

xlabel('Time [s]') ;
ylabel(varname) ;

%%
hlgnd = legend('f_2 = 0 N','f_2 = 0.1 N','f_2 = 0.2 N');
hlgnd.Location = 'Best' ;
hlgnd.FontSize = 10.8 ; 

%%
ax = gca ; ax.GridAlpha = 0.3 ;
ax.FontWeight = 'Bold' ;
ax.FontSize = 12 ;
ylabel('Label','FontWeight','bold','FontSize',13,...
    'Interpreter','none');
xlabel('time [s]','FontWeight','bold','FontSize',13,'Interpreter','none');

%%
hline = ax.Children ;
hline(1).LineStyle = '-.' ;
hline(1).LineWidth = 1 ;
hline(1).Color = [0.4941 0.1843 0.5569] ;

hline(2).LineStyle = '--' ;
hline(2).LineWidth = 1 ;
hline(2).Color = [0.8500    0.3250    0.0980] ;

hline(3).LineStyle = '-' ;
hline(3).LineWidth = 1 ;
hline(3).Color = [0    0.4470    0.7410] ;


%%
 hlgnd = legend ;
 hlgnd.Interpreter = 'latex' ;
 hlgnd.FontSize = 12 ;
% hlgnd.String = {'$\widehat D_1$','$\widehat D_2$','$\widehat D_3$'} ;
hlgnd.String = {'$\phi$','$\theta$','$\psi$'} ;




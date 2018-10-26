# Example Problems #
This folder includes Matlab - Simulink files related to work presented in Chapter-1 of the thesis work.
The simulation includes simulation programs and control system implentations on various nonlinear ODE's. 

***Description of files:***

* _main_x12px2.m_: Main Matlab script for simulation of two-degree of freedom nonlinear ODE's. It assigns simulation parameters, runs the simulation ('sim_main_x12px23.slx') and plots the results ('plotlab.m'). 
* _sim_main_x12px23.slx_: Simulink file for simulation of two-degree of freedom nonlinear ODE's and developed control system architecture.

* _main_pqr.m_: Main Matlab script for simulation of three dimensional attitude dynamics. It assigns simulation parameters, runs the simulation ('sim_main_pqr.slx') and plots the results ('plotlab.m'). 
* _sim_main_pqr.slx_: Simulink file for simulation of two-degree of freedom nonlinear ODE's and developed control system architecture.

* _phasePortraitandFixedPoints.m_: Matlab script for drawing phase portraits of two-degree of freedom nonlinear ODE's. 
* _phasePortraitandTrajectory.m_: Matlab script for drawing phase portraits of two-degree of freedom nonlinear ODE's, together with time trajectories for some initial conditions. 

* _plotlab.m_: Interactive figure plotter that works on Simulink's simulation log files. The parameters should be logged during the simulation for them to appear in the interactive plot figure. It is an earlier version of the simplotter tool developed vy Arda Aksu (https://www.mathworks.com/matlabcentral/fileexchange/35827-simplotter-plot-tool-for-simulink-log-outputs).
* _linelabel.m_: Matlab function that posts text labels on the plotted curves.



# Quadrotor Simulation #
This folder includes Matlab - Simulink files related to work presented in Chapter-3 of the thesis work.
The simulation includes alternative methods for full attitude and reduced attitude control of quadrotor systems using 4, 3 and 2 propellers.  Following references are used for formulation of the quadrotor dynamics:

* General quadrotor modeling: 
  * M. W. Mueller and R. D’Andrea, “Stability and control of a quadrocopter
despite the complete loss of one, two, or three propellers”, in Robotics and
Automation (ICRA), 2014 IEEE International Conference on, IEEE, 2014,
pp. 45–52.
  * M. W. Mueller and R. D’Andrea, “Relaxed hover solutions for multicopters:
Application to algorithmic redundancy and novel vehicles”, The International
Journal of Robotics Research, vol. 35, no. 8, pp. 873–889, 2016.
  * R. Mahony, V. Kumar, and P. Corke, “Multirotor aerial vehicles: Modeling,
estimation, and control of quadrotor”, IEEE Robotics & Automation Magazine,
vol. 19, pp. 20–32, 2012.

* Reduced attitude formulation: 
  * F. Bullo, R. M. Murray, and A. Sarti, “Control on the sphere and reduced
attitude stabilization”, California Institute of Technology, 1995.
  * N. A. Chaturvedi, A. K. Sanyal, and N. H. McClamroch, “Rigid-body attitude
control”, IEEE Control Systems, vol. 31, no. 3, pp. 30–51, 2011.


***Description of files:***

* _quadrotor.m_: Main Matlab script for quadrotor simulation that assigns simulation parameters, runs the simulation ('simQuadrotor.slx') and plots the results ('plotlab.m')      
* _simQuadrotor.slx_: Simulink file that includes the quadrotor system dynamics and control system architecture
* _plotlab.m_: Interactive figure plotter that works on Simulink's simulation log files. The parameters should be logged during the simulation for them to appear in the interactive plot figure. It is an earlier version of the simplotter tool developed vy Arda Aksu  (https://www.mathworks.com/matlabcentral/fileexchange/35827-simplotter-plot-tool-for-simulink-log-outputs).

* _pureAttitude.m_: Main Matlab script for quadrotor attitude dynamics that assigns simulation parameters, runs the simulation ('simAttitudeControl.slx') and plots the results ('plotlab.m')
* _simAttitudeControl.slx_: Simulink file that includes the quadrotor attitude dynamics and the control system.
                      
* -reducedAttitudeControllerDesign.m_: Implements the PD control system design method for reduced attitude control, presented in  Bullo et al. 1995.
* _systemBounds.m_: Some calculations on limiting yaw rate for different propeller forces.                        

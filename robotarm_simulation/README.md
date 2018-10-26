# Robot Arm Simulation #
This folder includes Matlab - Simulink files related to work presented in Chapter-2 of the thesis work.
The simulation includes simulation programs and control system implentations on two-link and three-link open chain robotic manipulators. Following references are used for formulation of the manipulator dynamics:

* General robotic manipulator modeling: 
 * R. Tedrake, Underactuated robotics: algorithms for walking, running, swimming,
flying, and manipulation (course notes for mit 6.832), Available at http:
//underactuated.mit.edu/underactuated.html [28/11/2017].
 * J.-J. E. Slotine and W. Li, Applied nonlinear control, 1. Prentice-Hall Englewood
Cliffs, NJ, 1991, vol. 199.


***Description of files:***

* _twoLinkFDIbasisComparison.m_: Main Matlab script for comparison of different basis functions for construction of the fault signal. Fully actuated two-link vertical robotic manipulator problem is implemented for this purpose. This file assigns simulation parameters, runs the simulation ('simTwoLinkFDIbasisComparison.slx') and plots the results ('plotlab.m'). 
* _simTwoLinkFDIbasisComparison.slx_: Simulink file that includes the fully actuated two-link vertical robotic manipulator system dynamics, fault detection and identification block and control system architecture.

* _robotArmWith2Links.m_: Main Matlab script for fully actuated two-link vertical robotic manipulator simulation that assigns simulation parameters, runs the simulation ('simRobotArmWith2Links.slx') and plots the results ('plotlab.m'). 
* _simRobotArmWith2Links.slx_: Simulink file that includes the fully actuated two-link vertical robotic manipulator system dynamics and control system architecture.

* _twoLinkFTC.m_: Main Matlab script for fault tolerant control of two-link vertical robotic manipulator simulation that assigns simulation parameters, runs the simulation ('simTwoLinkFTC.slx') and plots the results ('plotlab.m'). 
* _simTwoLinkFTC.slx_: Simulink file that includes the two-link vertical robotic manipulator system dynamics, including simulation of free-swing and locked joint faults and the developed fault tolerant control system architecture.

* _twoLinkFTCwAdaptive.m_: Main Matlab script for fault tolerant control of two-link vertical robotic manipulator simulation that assigns simulation parameters, runs the simulation ('simTwoLinkFTCwAdaptive.slx') and plots the results ('plotlab.m'). This model includes adaptive compensation terms in the fault tolerant control structure.
* _simTwoLinkFTCwAdaptive.slx_: Simulink file that includes the two-link vertical robotic manipulator system dynamics, including simulation of free-swing and locked joint faults and the developed fault tolerant control system architecture. This model includes adaptive compensation terms in the fault tolerant control structure.

* _threeLinkFTC.m_: Main Matlab script for fault tolerant control of three-link horizontal robotic manipulator simulation that assigns simulation parameters, runs the simulation ('simThreeLinkFTC.slx') and plots the results ('plotlab.m'). 
* _simThreeLinkFTC.slx_: Simulink file that includes the three-link horizontal robotic manipulator system dynamics, including simulation of free-swing and locked joint faults and the developed fault tolerant control system architecture.

* _plotlab.m_: Interactive figure plotter that works on Simulink's simulation log files. The parameters should be logged during the simulation for them to appear in the interactive plot figure. It is an earlier version of the simplotter tool developed vy Arda Aksu (https://www.mathworks.com/matlabcentral/fileexchange/35827-simplotter-plot-tool-for-simulink-log-outputs).
* _twolinkplot.m_: Dynamic animation for two-link robotic manipulator. It is run by Simulink blocks, if it is enabled from the main file, through "visualFlag" parameter.
* _postVisualization.m: Re-animates two-link robotic manipulator simulation results. It can be run, while the sim results are present in the Matlab Workspace.




%% plotlab
% 21.02.2018
%
function plotlab(title)
%
[prf,gui,logData,logInfo,xpcData]=initiateGlobals;
getPrf;
createInterface;
refreshInterface;
%
%
%
%% createInterface
    function createInterface
        %com.mathworks.mwswing.MJUtilities.initJIDE; %to initialize jide!
        % tree
        gui.treeNode=javax.swing.tree.DefaultMutableTreeNode('');
        gui.treeModel=javax.swing.tree.DefaultTreeModel(gui.treeNode);
        gui.tree=javax.swing.JTree(gui.treeModel);
        set(handle(gui.tree.getSelectionModel,'CallbackProperties'),'ValueChangedCallback',@onSelectionTree);
        set(handle(gui.tree,'CallbackProperties'),'MousePressedCallback',@onMousePressedTree);
        icon=javax.swing.ImageIcon;
        renderer=javax.swing.tree.DefaultTreeCellRenderer;
        renderer.setLeafIcon(icon);
        renderer.setClosedIcon(icon);
        renderer.setOpenIcon(icon);
        gui.tree.setCellRenderer(renderer);
        gui.treePane=javax.swing.JScrollPane(gui.tree);
        % list
        gui.listModel=javax.swing.DefaultListModel;
        gui.list=javax.swing.JList(gui.listModel);
        set(handle(gui.list.getSelectionModel,'CallbackProperties'),'ValueChangedCallback',@onSelectionList);
        set(handle(gui.list,'CallbackProperties'),'MousePressedCallback',@onMousePressedList);
        gui.listPane=javax.swing.JScrollPane(gui.list);
        % split pane
        gui.splitPane=javax.swing.JSplitPane(javax.swing.JSplitPane.HORIZONTAL_SPLIT,gui.treePane,gui.listPane);
        gui.splitPane.setOneTouchExpandable(true); %gui.splitPane.setDividerSize(5);
        gui.splitPane.setSize(java.awt.Dimension(prf.sPaneWidth,0));
        gui.splitPane.getComponent(1).setMinimumSize(java.awt.Dimension(0,0));
        gui.splitPane.getComponent(0).setMinimumSize(java.awt.Dimension(0,0));
        gui.splitPane.setResizeWeight(1);
        gui.splitPane.setDividerLocation(prf.sPaneLoc);
        set(handle(gui.splitPane.getComponent(2),'CallbackProperties'),'ComponentMovedCallback',@onGetDividerLocation);
        % frame
        gui.frame=figure('name',prf.frameName,'tag','plotlab','userdata','plotlab','handle','off',...
            'numbertitle','off','windowstyle','normal','dock','off','integer','off','visible','off',...
            'menu','none','toolbar','none','position',prf.framePos,'closereq',@onFrameClose);
        % update icon
        updateFrameIcon;
        % window menus
        refreshMenuFigure;
        refreshMenuTools;
        refreshMenuModes;
        % right click menus
        refreshMenuRightClick;
        % get java frame
        getJavaFrame;
        % option pane
        gui.optionPane=javax.swing.JOptionPane;
        % finalize
        set(gui.frame,'visible','on'); %ensure
        updateFrameIcon; %just in case!
    end
%
%
%% extractLogData
    function [data,time,dimOk]=extractLogData(log,ind)
        if nargin<2
            ind=1;
        end
        try
            dimOk=1;
            switch prf.mode
                case {'sim','xpc'}
                    data=log.Data;
                    time=log.Time;
                    if isvector(time) && numel(time)>1
                        dataSize=size(data);
                        if numel(dataSize)>2
                            data=squeeze(data);
                            dataSize=size(data);
                        end
                        if numel(dataSize)>2
                            if find(dataSize==numel(time),1,'last')==numel(dataSize)
                                data=reshape(data,[],numel(time));
                                dataSize=size(data);
                            elseif find(dataSize==numel(time),1,'first')==1
                                data=reshape(data,numel(time),[]);
                                dataSize=size(data);
                            else
                                dimOk=0;
                            end
                        end
                        if numel(dataSize)==2
                            if size(data,1)~=numel(time)
                                data=data.';
                            end
                        else
                            dimOk=0;
                        end
                    elseif numel(time)==1
                        data=reshape(data,1,[]);
                    elseif ~(isempty(time) && isempty(data))
                        dimOk=0;
                    end
                case 'struct'
                    data=log;
                    time=NaN;
                    dataSize=size(data);
                    if numel(dataSize)>2
                        data=squeeze(data);
                        dataSize=size(data);
                    end
                    if numel(dataSize)>2
                        if find(dataSize==max(dataSize),1,'last')==numel(dataSize)
                            data=reshape(data,[],max(dataSize));
                            dataSize=size(data);
                        elseif find(dataSize==max(dataSize),1,'first')==1
                            data=reshape(data,max(dataSize),[]);
                            dataSize=size(data);
                        else
                            dimOk=0;
                        end
                    end
                    if numel(dataSize)==2
                        if dataSize(1)~=max(dataSize)
                            data=data.';
                        end
                    else
                        dimOk=0;
                    end
            end
            %
            if ~isempty(data)
                if nargin>1
                    if all(ind>0)
                        data=data(:,ind);
                    else
                        nanInd=isnan(data);
                        data(nanInd)=0;
                        ind=-ind;
                        temp=0;
                        for i=1:numel(ind)
                            temp=temp+bitand(abs(round(data)),2^(ind(i)-1))/2^(min(ind)-1);
                        end
                        data=temp;
                        if any(nanInd)
                            data(nanInd)=NaN;
                        end
                    end
                end
            end
        catch
            dimOk=0;
        end
        if ~dimOk
            time=NaN;
            data=NaN;
        end
    end
%
%
%% extractUniqueList
    function listData=extractUniqueList(listDataRef)
        if isempty(listDataRef)
            listData={};
            return
        end
        [listDataRef,listData]=cellfun(@getLastSub,listDataRef,'UniformOutput',0);
        for i=1:5 %5 steps max!
            [b,m,n]=unique(listData,'first');
            if numel(b)==numel(listData)
                return
            else
                duplicates=arrayfun(@findDuplicates,m,'UniformOutput',0);
                cellfun(@correctListData,duplicates,'UniformOutput',0);
            end
        end
        %
        % sub functions for cellfun
        function [outCell,outStr]=getLastSub(inCell)
            outCell=inCell;
            if numel(outCell)>0
                outStr=outCell{end};
                outCell(end)=[];
                if isempty(find(isstrprop(outStr,'digit')==0,1)) && numel(outCell)>0
                    outStr=[outCell{end} '.' outStr];
                    outCell(end)=[];
                end
            else
                outStr='';
            end
        end
        %
        function out=findDuplicates(in)
            out=(n==n(in));
        end
        %
        function correctListData(in)
            if sum(in)>1
                for ii=1:10 %10 steps max
                    [listDataRef(in),prefix]=cellfun(@getLastSub,listDataRef(in),'UniformOutput',0);
                    if numel(unique(prefix))>1
                        listData(in)=cellfun(@combineListData,prefix,listData(in),'UniformOutput',0);
                        break
                    end
                end
            end
        end
        %
        function out=combineListData(in1,in2)
            if isempty(in2)
                out=in1;
            elseif isempty(in1)
                out=in2;
            else
                out=[in1 '.' in2];
            end
        end
    end
%
%
%% getCompatibleData
    function [data,check]=getCompatibleData(data0,indArray)
        check=0;
        data=data0;
        try
            if size(indArray,1)~=1
                indArray=reshape(indArray,1,[]);
            end
            %
            data=NaN*zeros(size(data0,1),numel(indArray));
            j=0;
            signal='';
            for i=1:numel(indArray)
                if all(logInfo{indArray(i),2}>0)
                    j=j+1;
                    data(:,i)=data0(:,j);
                else %extract bit
                    if ~strcmp(logInfo{indArray(i),1},signal)
                        j=j+1;
                    end
                    dataSub=data0(:,j);
                    nanInd=isnan(dataSub);
                    dataSub(nanInd)=0;
                    ind=-logInfo{indArray(i),2};
                    temp=0;
                    for k=1:numel(ind)
                        temp=temp+bitand(abs(round(dataSub)),2^(ind(k)-1))/2^(min(ind)-1);
                    end
                    dataSub=temp;
                    if any(nanInd)
                        dataSub(nanInd)=NaN;
                    end
                    data(:,i)=dataSub;
                end
                signal=logInfo{indArray(i),1};
            end
            if j==size(data0,2)
                check=1;
            else
                check=0;
            end
        catch
            check=0;
        end
    end
%
%
%% getJavaFrame
    function getJavaFrame
        set(gui.frame,'visible','on');
        drawnow; pause(0.01);
        try
            mde=com.mathworks.mde.desk.MLDesktop.getInstance;
            gui.jFrame=mde.getClient(prf.frameName).getTopLevelAncestor;
            refreshWaitBar; %check if works!
        catch
            try
                warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame')
                gui.jFrame=get(gui.frame,'javaframe');
                gui.jFrame=gui.jFrame.fFigureClient.getWindow;
                refreshWaitBar; %check again!
            catch
                gui.jFrame=[];
            end
        end
        try
            fw=gui.jFrame.getSize.getWidth;
            fh=gui.jFrame.getSize.getHeight;
            sw=java.awt.Toolkit.getDefaultToolkit.getScreenSize.getWidth;
            sh=java.awt.Toolkit.getDefaultToolkit.getScreenSize.getHeight;
            x=gui.jFrame.getLocation.getX;
            x=max(1,min(x,sw-fw));
            y=gui.jFrame.getLocation.getY;
            y=max(1,min(y,sh-fh));
            if x~=gui.jFrame.getLocation.getX || y~=gui.jFrame.getLocation.getY
                gui.jFrame.setLocation(x,y);
            end
        catch
            try
                movegui(gui.frame);
            end
        end
    end
%
%
%% getPrf
    function getPrf
        % load
        prf=struct;
        try
            if exist([mfilename('fullpath') 'Prf.mat'],'file')==2
                prf=importdata([mfilename('fullpath') 'Prf.mat']);
            else
                allPrf=getpref('plotlab');
                if ~isempty(allPrf)
                    loaded=0;
                    times=0;
                    for i=1:9
                        try
                            folder=regexp(allPrf.(['prf' num2str(i)]).pwd,'(?<=.*\\)([^\\]*)$','match');
                            curPath=regexprep(mfilename('fullpath'),['\\{0,1}' mfilename '$'],'');
                            curFolder=regexp(curPath,'(?<=.*\\)([^\\]*)$','match');
                            if isequal(folder,curFolder)
                                prf=getpref('plotlab',['prf' num2str(i)]);
                                loaded=1;
                                break
                            else
                                tempPrf=getpref('plotlab',['prf' num2str(i)]);
                                times(i)=tempPrf.time;
                            end
                        catch
                            times(i)=0;
                        end
                    end
                    if ~loaded && max(times)>0 %load the latest prf
                        i=find(times==max(times),1);
                        prf=getpref('plotlab',['prf' num2str(i)]);
                    end
                end
            end
        catch
            prf=struct;
        end
        % check prf fields
        if ~isfield(prf,'converters') || ~iscell(prf.converters) || size(prf.converters,2)~=3
            prf.converters={'','Rad to Deg','180/pi';'','Deg to Rad','pi/180'};
        end
        if ~isfield(prf,'rules') || ~iscell(prf.rules) || size(prf.rules,2)~=4
            prf.rules={'euler','phi | theta | psi','d','180/pi'; 'bitFlag','a ; b,3 ; c ; d ; e,2','',''};
        end
        if ~isfield(prf,'plotProperties') || ~iscell(prf.plotProperties) || size(prf.plotProperties,2)~=2 || ...
                ~isequal(prf.plotProperties(:,1),{'LineStyle';'LineWidth';'Marker';'MarkerSize'})
            prf.plotProperties={'LineStyle','-';'LineWidth',1;'Marker','none';'MarkerSize',6};
        end
        if ~isfield(prf,'plotPropertiesStruct') || ~iscell(prf.plotPropertiesStruct) || size(prf.plotPropertiesStruct,2)~=2 ||  ...
                ~isequal(prf.plotPropertiesStruct(:,1),{'LineStyle';'LineWidth';'Marker';'MarkerSize'})
            prf.plotPropertiesStruct={'LineStyle','-';'LineWidth',1;'Marker','none';'MarkerSize',6};
        end
        if ~isfield(prf,'framePos') || ~isnumeric(prf.framePos) || numel(prf.framePos)~=4
            p=get(0,'screensize'); w=p(3); h=p(4);
            prf.framePos=[w/3 h/3 w/3 h/3];
        end
        if ~isfield(prf,'sPaneWidth') || ~isnumeric(prf.sPaneWidth) || numel(prf.sPaneWidth)~=1
            prf.sPaneWidth=0;
        end
        if ~isfield(prf,'sPaneWidthStruct') || ~isnumeric(prf.sPaneWidthStruct) || numel(prf.sPaneWidthStruct)~=1
            prf.sPaneWidthStruct=0;
        end
        if ~isfield(prf,'sPaneLoc') || ~isnumeric(prf.sPaneLoc) || numel(prf.sPaneLoc)~=1
            prf.sPaneLoc=0.5;
        end
        if ~isfield(prf,'sPaneLocStruct') || ~isnumeric(prf.sPaneLocStruct) || numel(prf.sPaneLocStruct)~=1
            prf.sPaneLocStruct=1;
        end
        if ~isfield(prf,'mode') || ~ischar(prf.mode) || ~any(strcmp(prf.mode,{'sim','xpc','struct'}))
            prf.mode='sim';
        end
        if ~isfield(prf,'filterMode') || ~ischar(prf.filterMode)
            prf.filterMode='off';
        end
        if ~isfield(prf,'menuLockLog') || ~ischar(prf.menuLockLog)
            prf.menuLockLog='off';
        end
        if ~isfield(prf,'userInd') || ~isnumeric(prf.userInd) || numel(prf.userInd)~=1
            prf.userInd=0;
        end
        if ~isfield(prf,'treeExpandPaths') || ~iscell(prf.treeExpandPaths) ...
                || ~(size(prf.treeExpandPaths,1)==1 || size(prf.treeExpandPaths,1)==0)...
                || ~isfield(prf,'treeSelections') || ~iscell(prf.treeSelections) ...
                || ~(size(prf.treeSelections,1)==1 || size(prf.treeSelections,1)==0)
            prf.treeExpandPaths={};
            prf.treeSelections={};
        end
        if ~isfield(prf,'treeExpandPathsStruct') || ~iscell(prf.treeExpandPathsStruct) ...
                || ~(size(prf.treeExpandPathsStruct,1)==1 || size(prf.treeExpandPathsStruct,1)==0)...
                || ~isfield(prf,'treeSelectionsStruct') || ~iscell(prf.treeSelectionsStruct) ...
                || ~(size(prf.treeSelectionsStruct,1)==1 || size(prf.treeSelectionsStruct,1)==0)
            prf.treeExpandPathsStruct={};
            prf.treeSelectionsStruct={};
        end
        % remove invalid fields
        prfFields=fieldnames(prf);
        for i=1:numel(prfFields)
            if 1 && ~any(strcmp(prfFields{i},{...
                    'converters'
                    'rules'
                    'plotProperties'
                    'plotPropertiesStruct'
                    'framePos'
                    'sPaneWidth'
                    'sPaneWidthStruct'
                    'sPaneLoc'
                    'sPaneLocStruct'
                    'mode'
                    'filterMode'
                    'menuShowLog'
                    'menuShowOrder'
                    'menuLockLog'
                    'userInd'
                    'treeExpandPaths'
                    'treeSelections'
                    'treeExpandPathsStruct'
                    'treeSelectionsStruct'
                    }))
                prf=rmfield(prf,prfFields{i});
            end
        end
        % unprotected fields (allow to change only those from tool menu)
        prf.unprotectedFields={'converters','rules','plotProperties','plotPropertiesStruct'};
        % override!
        prf.pwd=regexprep(mfilename('fullpath'),['\\{0,1}' mfilename '$'],'');
        prf.time=now;
        prf.listInd=[];
        prf.xAxis=[];
        prf.simLogBaseName=[];
        prf.structLogBaseName=[];
        prf.username=[getenv('username') ' ' getenv('computername')];
        prf.menuShowLog='off';
        prf.menuShowOrder='off';
        prf.menuLockLog='off';
        % title
        set(0,'ShowHiddenHandles','on');
        try
            prf.frameName=title;
            for i=1:numel(findobj('tag','plotlab','userdata','plotlab'))
                hFig=findobj('name',prf.frameName,'tag','plotlab','userdata','plotlab');
                if isempty(hFig)
                    break
                else
                    if i==1
                        prf.frameName=[prf.frameName ' 2'];
                    else
                        prf.frameName(end)=num2str(i+1);
                    end
                end
            end
        catch
            % check previous windows
            hFig=findobj('tag','plotlab','userdata','plotlab');
            if isempty(hFig)
                prf.frameName='PlotLab';
            else
                maxFigNo=1;
                for i=1:numel(hFig)
                    figNo=regexp(get(hFig(i),'name'),'(?<=^PlotLab )\d\d?','match');
                    try
                        maxFigNo=max(str2double(figNo{1}),maxFigNo);
                    end
                end
                prf.frameName=['PlotLab ' num2str(maxFigNo+1) ''];
            end
        end
        set(0,'ShowHiddenHandles','off'); %must be off!
        % global prf
        try
            prf0=getpref('plotlab','prf0');
        catch
            prf0=struct;
        end
        if ~isfield(prf0,'persistent') || ~isstruct(prf0.persistent)
            prf0.persistent=struct;
        end
        if ~isfield(prf0,'totalPlots') || ~isnumeric(prf0.totalPlots) || numel(prf0.totalPlots)~=1
            prf0.totalPlots=0;
        end
        if ~isfield(prf0,'prank') || ~isnumeric(prf0.prank) || numel(prf0.prank)~=1
            prf0.prank=1;
        end
        if ~isfield(prf0,'pranked') || ~isnumeric(prf0.pranked) || numel(prf0.pranked)~=1
            prf0.pranked=0;
        end
        % remove invalid fields
        prfFields=fieldnames(prf0);
        for i=1:numel(prfFields)
            if 1 && ~any(strcmp(prfFields{i},{...
                    'persistent'
                    'totalPlots'
                    'prank'
                    'pranked'
                    }))
                prf0=rmfield(prf0,prfFields{i});
            end
        end
        setpref('plotlab','prf0',prf0);
    end
%
%
%% getSelectedListIndices
    function indices=getSelectedListIndices(keepSelectionOrder)
        % call this fun every time selection changes!
        persistent preSelectedInd
        %
        if nargin<1
            keepSelectionOrder=1;
        end
        try
            indices=prf.listInd(gui.list.getSelectedIndices+1);
        catch
            indices=[];
        end
        lastSelectedInd=indices;
        [common,commonInd,commonExInd]=intersect(lastSelectedInd,preSelectedInd);
        indices(commonInd)=[];
        indices=[preSelectedInd(sort(commonExInd)) indices];
        if numel(lastSelectedInd)~=numel(intersect(lastSelectedInd,indices))
            indices=lastSelectedInd;
        end
        %
        preSelectedInd=indices;
        %
        if nargout>0 && ~keepSelectionOrder
            indices=sort(indices);
        end
    end
%
%
%% getSelectedTreeIndices
    function indices=getSelectedTreeIndices(keepSelectionOrder)
        % call this fun every time selection changes!
        persistent preSelectedInd
        %
        if nargin<1
            keepSelectionOrder=1;
        end
        if isempty(logInfo)
            indices=[];
            return
        end
        indices=[];
        selectedPaths=gui.tree.getSelectionPaths;
        for i=1:numel(selectedPaths)
            path=selectedPaths(i);
            try
                % 1.method
                selInd=get(path.getPathComponent(path.getPathCount-1),'userdata');
            catch
                % 2.method
                selInd=1:size(logInfo,1);
                for ind=path.getPathCount:-1:2 % skip 1 (root)
                    subPath=path.getPathComponent(ind-1).toString;
                    selInd=selInd(cellfun(@comparePath,logInfo(selInd,3)));
                    if isempty(selInd)
                        break
                    end
                end
            end
            indices=[indices,selInd];
        end
        indices=unique(indices,'first');
        lastSelectedInd=indices;
        [common,commonInd,commonExInd]=intersect(lastSelectedInd,preSelectedInd);
        indices(commonInd)=[];
        indices=[preSelectedInd(sort(commonExInd)) indices];
        if numel(lastSelectedInd)~=numel(intersect(lastSelectedInd,indices))
            indices=lastSelectedInd;
        end
        %
        preSelectedInd=indices;
        %
        if ~keepSelectionOrder
            indices=sort(indices);
        end
        %
        % sub function for cellfun
        function out=comparePath(in)
            try
                out=strcmp(in{ind-1},subPath); %first one is root!
            catch
                out=false;
            end
        end
    end
%
%
%% getTreeStates
    function getTreeStates
        % tree expansions and selection
        try
            if ~isempty(char(gui.treeModel.getRoot.toString))
                treeExpandPaths={}; treeSelections={};
                for i=0:gui.tree.getRowCount-1
                    path=gui.tree.getPathForRow(i);
                    if gui.tree.isExpanded(path)
                        treeExpandPaths{end+1}=char(path.toString);
                    end
                    if gui.tree.isPathSelected(path)
                        treeSelections{end+1}=char(path.toString);
                    end
                end
            end
            switch prf.mode
                case 'struct'
                    prf.treeExpandPathsStruct=treeExpandPaths;
                    prf.treeSelectionsStruct=treeSelections;
                case {'sim','xpc'}
                    prf.treeExpandPaths=treeExpandPaths;
                    prf.treeSelections=treeSelections;
            end
        end
    end
%
%
%% getUserData
    function value=getUserData(hObject,field)
        try
            userData=get(hObject,'userdata');
            value=userData.(field);
        catch
            value=[];
        end
    end
%
%
%% initiateFilterMode
    function initiateFilterMode(hFig,label)
        figOk=0;
        try
            hAxes=findobj(hFig,'type','axes','tag','');
            hLines=findobj(hAxes,'type','line');
            if numel(hLines)>10
                showError('Working on more than 10 lines is not allowed!');
                return
            end
            for i=1:numel(hLines)
                logInd=getUserData(hLines(i),'logInd');
                log=eval(logInfo{logInd,1});
                dataInd=logInfo{logInd,2};
                data=extractLogData(log,dataInd);
                data=reshape(data,1,[]);
                factor=getUserData(hLines(i),'logDataFactor');
                data=double(data)*factor;
                data2=double(reshape(get(hLines(i),'ydata'),1,[]));
                if isequalwithequalnans(data2,data)
                    figOk=1;
                else
                    figOk=0;
                    break
                end
            end
        catch
            figOk=0;
        end
        if ~figOk
            showError('Plot new data and try again!');
            return
        end
        state=uisuspend(hFig); uirestore(state);
        legend('off');
        set(hFig,'tag','filterFigure','pointer','crosshair','closerequestfcn',@onFilterFigureClose,...
            'windowbuttondownfcn',@onFilterFigureButtonDown,'keypressfcn',@onFilterFigureKeyPress,...
            'busyaction','cancel','interruptible','off');
        set(hAxes,'drawmode','fast')
        for i=1:numel(hLines)
            props={'displayname','linestyle','marker','markeredgecolor','markerfacecolor','color'};
            for j=1:numel(props)
                setUserData(hLines(i),props{j},get(hLines(i),props{j}));
            end
            set(hLines(i),'displayname','data','color',[0,0,1],'linestyle','-','marker','.')
            hold on;
            hLine2=plot(hAxes,NaN,NaN,'displayname','spikes','marker','o','linestyle','none','color','r','parent',hAxes);
            set(hLine2,'xdata',[],'ydata',[]);
        end
        % update tools menu
        switch label
            case 'Erase points'
                prf.filterMode='erase';
            case 'Select first index'
                prf.filterMode='first';
            case 'Select last index'
                prf.filterMode='last';
            otherwise
                prf.filterMode='off';
        end
        refreshMenuTools;
        % animation
        figure(hFig);
        state=uisuspend(hFig); uirestore(state);
        drawnow;
        for i=1:2
            pause(0.1); set(hLines,'marker','o','MarkerEdgeColor','r'); drawnow;
            pause(0.1); set(hLines,'marker','.','MarkerEdgeColor','b'); drawnow;
        end
    end
%
%
%% initiateGlobals
    function [prf,gui,logData,logInfo,xpcData]=initiateGlobals
        prf=struct;
        gui=struct;
        logData=[];
        logInfo={};
        xpcData.data=[];
        xpcData.time=[];
    end
%
%
%% isStructLogOk
    function check=isStructLogOk(logData0)
        check=1;
        try
            if numel(logData0)>1
                check=0;
            else
                size1=[];
                logs={'logData0',{},''};
                for counter=1:1000;
                    newLogs={};
                    for i=1:size(logs,1)
                        subLogs=fieldnames(eval(logs{i,1}));
                        for j=1:numel(subLogs)
                            logName=[logs{i,1} '.' subLogs{j}];
                            log=eval(logName);
                            if isstruct(log) && ~strcmpi(subLogs{j},'plotlabRulez') && numel(log)==1
                                newLogs{end+1,1}=logName;
                            elseif isnumeric(log)
                                [data,time,dimOk]=extractLogData(log);
                                if dimOk
                                    size1(end+1)=size(data,1);
                                end
                            end
                        end
                    end
                    logs=newLogs; % breaks if "logs" is empty
                    if isempty(logs)
                        break
                    end
                end
                if numel(unique(size1))~=1
                    check=0;
                end
            end
        catch
            check=0;
        end
    end
%
%
%% isMultipleCall
% http://www.mathworks.com/matlabcentral/fileexchange/26027-ismultiplecall
    function flag=isMultipleCall
        flag=false;
        try
            % Get the stack
            s=dbstack;
            if numel(s)<=2
                % Stack too short for a multiple call
                return
            end
            % How many calls to the calling function are in the stack?
            names={s(:).name};
            TF=strcmp(s(2).name,names);
            count=sum(TF);
            if count>1
                % More than 1
                flag=true;
            end
        end
    end
%
%
%% isXpcDataOk
    function check=isXpcDataOk(errorFlag)
        try
            %keep the original data, use it while exporting and saving
            xpcData.data0=xpcData.data; 
            xpcData.time0=xpcData.time;
            try
                dim=size(xpcData.data,2);
                if dim==size(logInfo,1)
                    check=1;
                else
                    [xpcData.data,check]=getCompatibleData(xpcData.data,1:size(logInfo,1));
                end
            catch
                check=0;
            end
            %
            if ~check
                xpcData.data=[];
                xpcData.time=[];
                if errorFlag
                    try
                        j=0;
                        signal='';
                        for i=1:size(logInfo,1)
                            if all(logInfo{i,2}>0)
                                j=j+1;
                            else %extract bit
                                if ~strcmp(logInfo{i,1},signal)
                                    j=j+1;
                                end
                            end
                            signal=logInfo{i,1};
                        end
                        dimText=['(' num2str(j) ')'];
                    catch
                        dimText='';
                    end
                    showError(['Dimension of xPC data (' num2str(dim) ') does not match \nwith dimension of log data ' dimText '!']);
                end
                return
            else
                try
                    %xpcData.data(1,:)=[]; %First row contains bulk data!
                    for i=1:size(xpcData.data,1)-1
                        if not(all(xpcData.data(i,:)==0))
                            break
                        end
                    end
                    xpcData.data(1:i-1,:)=[];
                    try
                        xpcData.time(1:i-1)=[];
                    end
                    for i=1:size(xpcData.data,1)-1
                        if not(all(xpcData.data(i,:)==xpcData.data(i+1,:)))
                            break
                        end
                    end
                    xpcData.data(1:i-1,:)=[];
                    try
                        xpcData.time(1:i-1)=[];
                    end
                    for i=size(xpcData.data,1):-1:2
                        if not(all(xpcData.data(i,:)==xpcData.data(i-1,:)))
                            break
                        end
                    end
                    xpcData.data(i+1:end,:)=[];
                    try
                        xpcData.time(i+1:end)=[];
                    end
                end
                if size(xpcData.data,1)~=size(xpcData.time,1)
                    xpcData.time=[];
                else
                    xpcData.time=xpcData.time-xpcData.time(1);
                end
            end
        catch
            check=0;
            xpcData.data=[];
            xpcData.time=[];
            if errorFlag
                showError('Invalid xPC data!');
            end
        end
    end
%
%
%% onFigureBinDec
    function onFigureBinDec(hObject,eventData)
        try
            if ~isempty(findobj('type','figure'))
                hLine=findobj(gca,'type','line','selected','on');
                if isempty(hLine)
                    hLine=findobj(gca,'type','line');
                end
                if numel(hLine)==1
                    xd=get(hLine,'xdata');
                    yd=get(hLine,'ydata');
                    dn=get(hLine,'displayname');
                    ind=(~isnan(xd)&~isnan(yd));
                    xd=xd(ind);
                    yd=yd(ind);
                    if ~isequal(yd,abs(round(yd)))
                        showError('Unsigned integer values are allowed only!');
                        return
                    end
                    bits=dec2bin(yd);
                    if size(bits,2)>32
                        showError('Data might have more than 32 bits!');
                        return
                    end
                    bitInd=ones(1,size(bits,2));
                    % bitIndCell={regexprep(num2str(bitInd),'\s','')};
                    % inputOk=0;
                    % while ~inputOk
                    %     bitIndCell=inputdlg({['Select sizes (total of ' num2str(size(bits,2)) ' bits)']},'Show Bits',1,bitIndCell);
                    %     drawnow; pause(0.001);
                    %     if numel(bitIndCell)~=1
                    %         return
                    %     else
                    %         bitIndStr=bitIndCell{1};
                    %         bitInd=[];
                    %         for i=1:numel(bitIndStr)
                    %             bitInd=[bitInd str2double(bitIndStr(i))];
                    %         end
                    %         if sum(bitInd)==size(bits,2)
                    %             inputOk=1;
                    %         else
                    %             showError(['Summation of sizes must be ' num2str(size(bits,2))]);
                    %         end
                    %     end
                    % end
                    figure('tag','plotlab figure','name',strtrim([dn ' (bits)']),'numbertitle','off','windowstyle','docked');
                    hold all; grid on; drawnow;
                    for k=1:numel(bitInd)
                        bitSize=bitInd(k);
                        if bitSize==1
                            dispName=num2str(k);
                        else
                            dispName=[num2str(k) ' (' num2str(bitSize) ')'];
                        end
                        plot(xd,bin2dec(bits(:,end-bitSize+1:end)),'.-','displayname',dispName);
                        bits(:,end-bitSize+1:end)=[];
                        drawnow;
                    end
                    legend('show');
                    set(legend,'interpreter','none','location','best');
                elseif numel(hLine)>1
                    xdu=[];
                    for i=1:numel(hLine)
                        xd{i}=get(hLine(i),'xdata');
                        yd{i}=get(hLine(i),'ydata');
                        dn{i}=get(hLine(i),'displayname');
                        xdv=xd{i};
                        xdv=xdv(~isnan(xdv));
                        if isempty(xdu)
                            xdu=xdv;
                        else
                            xdu=intersect(xdu,xdv);
                        end
                    end
                    for i=1:numel(hLine)
                        xdv=xd{i};
                        ydv=yd{i};
                        [temp,ixdv]=intersect(xdv,xdu);
                        ydv=ydv(ixdv);
                        if ~isequal(ydv,abs(round(ydv))) || any(ydv>1)
                            showError('For binary conversion select a line and try again.');
                            return
                        end
                        bits(:,i)=dec2bin(ydv);
                    end
                    figure('tag','plotlab figure','name','bin2dec','numbertitle','off','windowstyle','docked');
                    hold all; grid on; drawnow;
                    plot(xdu,bin2dec(bits),'.-')
                end
            end
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onFigureConvert
    function onFigureConvert(hObject,eventData,mode)
        try
            switch mode
                case 1
                    try
                        label=get(hObject,'label');
                        menuLabel=get(hObject,'tag');
                        equation=prf.converters{strcmp(menuLabel,prf.converters(:,1)) & strcmp(label,prf.converters(:,2)),3};
                        convert(equation,label);
                    end
                case 0
                    prf0=getpref('plotlab','prf0');
                    if ~(isfield(prf0.persistent,'convertHistory') && iscell(prf0.persistent.convertHistory) && numel(prf0.persistent.convertHistory)>0)
                        prf0.persistent.convertHistory={'clear history'};
                    end
                    factor=prf0.persistent.convertHistory{1};
                    if strcmp(factor,'clear history')
                        factor='';
                    end
                    setpref('plotlab','prf0',prf0);
                    w=170; h=155; l=get(0,'PointerLocation'); pos=[l(1)-w/2 l(2)-h/2 w h];
                    convertDialog=dialog('name','Convert','windowbuttondownfcn','','buttondownfcn','','position',pos,'closerequestfcn','delete(gcbf);');
                    uicontrol(convertDialog,'style','text','string','Factor / Equation','position',[10,120,150,20],'horizontalalignment','left');
                    hFactor=uicontrol(convertDialog,'style','edit','tag','factor','string',factor,'position',[10,102,123,20],'horizontalalignment','left','backgroundcolor',[1,1,1],'keypressfcn',@onOk);
                    uicontrol(convertDialog,'style','popupmenu','tag','history','string',prf0.persistent.convertHistory,'position',[143,102,17,20],'callback',@onPopup);
                    uicontrol(convertDialog,'style','text','string','Menu','position',[10,70,70,20],'horizontalalignment','left')
                    uicontrol(convertDialog,'style','edit','tag','menu','string','','position',[10,52,70,20],'horizontalalignment','left','backgroundcolor',[1,1,1])
                    uicontrol(convertDialog,'style','text','string','Label','position',[90,70,70,20],'horizontalalignment','left')
                    uicontrol(convertDialog,'style','edit','tag','label','string','','position',[90,52,70,20],'horizontalalignment','left','backgroundcolor',[1,1,1])
                    uicontrol(convertDialog,'style','pushbutton','position',[10,10,70,22],'string','OK','callback',@onOk);
                    uicontrol(convertDialog,'style','pushbutton','position',[90,10,70,22],'string','Cancel','callback','delete(gcbf);');
                    uicontrol(hFactor);
                    try
                        movegui(convertDialog);
                    end
                    drawnow; pause(0.01);
            end
        catch
            showError('Something went wrong!')
        end
        %
        % subfuns
        function onPopup(hObject,eventData)
            drawnow; pause(0.01);
            hHistory=findobj(convertDialog,'tag','history');
            ind=get(hHistory,'value');
            history=get(hHistory,'string');
            equation=strtrim(history{ind});
            if strcmp('clear history',equation)
                prf0=getpref('plotlab','prf0');
                prf0.persistent.convertHistory={'clear history'};
                setpref('plotlab','prf0',prf0);
                set(hHistory,'string',prf0.persistent.convertHistory);
                set(hHistory,'value',1);
                set(findobj(convertDialog,'tag','factor'),'string','');
                set(findobj(convertDialog,'tag','label'),'string','');
                set(findobj(convertDialog,'tag','menu'),'string','');
                uicontrol(findobj(convertDialog,'tag','factor'));
            elseif ~isempty(equation)
                delete(convertDialog);
                drawnow; pause(0.01);
                convert(equation);
                saveHistory(equation,history);
            end
        end
        %
        function onOk(hObject,eventData)
            if strcmp(get(hObject,'String'),'OK') || (numel(eventData.Modifier)==0 && strcmp(eventData.Key,'return'))
                drawnow; pause(0.01);
                hFactor=findobj(convertDialog,'tag','factor');
                hLabel=findobj(convertDialog,'tag','label');
                hMenu=findobj(convertDialog,'tag','menu');
                hHistory=findobj(convertDialog,'tag','history');
                equation=get(hFactor,'string');
                label=strtrim(get(hLabel,'string'));
                menuLabel=strtrim(get(hMenu,'string'));
                history=strtrim(get(hHistory,'string'));
                if ~isempty(equation)
                    if ~isempty(label)
                        prf.converters(end+1,1:3)={menuLabel,label,equation};
                        refreshMenuFigure;
                    end
                    delete(convertDialog);
                    drawnow; pause(0.01);
                    convert(equation,label);
                    saveHistory(equation,history);
                end
            end
        end
        %
        function saveHistory(equation,history)
            try
                history(strcmp(history,'clear history'))=[];
                history=[{equation} reshape(history,1,[]) {'clear history'}];
                [x,p]=unique(history,'first');
                history=history(sort(p));
                if numel(history)>20
                    history(21:end)=[];
                end
                prf0=getpref('plotlab','prf0');
                prf0.persistent.convertHistory=history;
                setpref('plotlab','prf0',prf0);
            end
        end
        %
        function convert(equation,figLabel)
            try
                if nargin<2 || isempty(figLabel)
                    figLabel='Custom conversion';
                end
                if ~isempty(findobj('type','figure'))
                    selection=1;
                    hhLine=findobj(gca,'type','line','selected','on');
                    hXLabel=get(gca,'XLabel');
                    if isempty(hhLine)
                        selection=0;
                        hhLine=findobj(gca,'type','line');
                    end
                    if ~isempty(hhLine)
                        xVar=~isempty(regexp([' ' equation ' '],'\Wx\W','once'));
                        yVar=~isempty(regexp([' ' equation ' '],'\Wy\W','once'));
                        newData=~isempty(regexp([' ' equation ' '],'\Wy{\d+}\W','once'));
                        if ~xVar && ~yVar
                            for ii=1:numel(hhLine)
                                x=get(hhLine(ii),'xdata');
                                y=get(hhLine(ii),'ydata');
                                factor=protectedEvalXY(equation,x,y);
                                if isnumeric(factor) && numel(factor)==1
                                    set(hhLine(ii),'ydata',y*factor);
                                    if ~selection
                                        ylim('auto');
                                    end
                                else
                                    showError('Invalid factor or equation!\nUse a scalar to multiply, use x/y to manipulate axes, or use y{} to create new data.')
                                    return
                                end
                            end
                        elseif xVar && ~yVar
                            for ii=1:numel(hhLine)
                                x=get(hhLine(ii),'xdata');
                                y=get(hhLine(ii),'ydata');
                                xn=protectedEvalXY(equation,x,y);
                                if isnumeric(xn) && numel(xn)==numel(x)
                                    set(hhLine(ii),'xdata',xn);
                                    if ~selection
                                        xlim('auto');
                                    end
                                else
                                    showError('Invalid factor or equation!\nUse a scalar to multiply, use x/y to manipulate axes, or use y{} to create new data.')
                                    return
                                end
                            end
                        else
                            if newData
                                hhLine=findobj(gca,'type','line');
                                if numel(hhLine)>1
                                    hhLine=flipud(reshape(hhLine,[],1));
                                    x=get(hhLine,'xdata');
                                    y=get(hhLine,'ydata');
                                    xLeng=cellfun('length',x);
                                    yLeng=cellfun('length',y);
                                    %
                                    if numel(unique([reshape(xLeng,1,[]) reshape(yLeng,1,[])]))~=1
                                        try
                                            xLeng=[];
                                            yLeng=[];
                                            xUnion=zeros(1,sum(cellfun('length',x)));
                                            n=0;
                                            for i=1:numel(x)
                                                xUnion(n+1:n+numel(x{i}))=x{i};
                                                n=n+numel(x{i});
                                            end
                                            xUnion=unique(xUnion);
                                            ind=zeros(numel(x),length(xUnion));
                                            for i=1:numel(x)
                                                [c,ia,ib]=intersect(xUnion,x{i});
                                                ind(i,ia)=1;
                                            end
                                            xUnion=xUnion(all(ind));
                                            for i=1:numel(x)
                                                [c,ia,ib]=intersect(xUnion,x{i});
                                                x{i}=x{i}(ib);
                                                y{i}=y{i}(ib);
                                            end
                                            xLeng=cellfun('length',x);
                                            yLeng=cellfun('length',y);
                                        end
                                    end
                                    %
                                    if numel(unique([reshape(xLeng,1,[]) reshape(yLeng,1,[])]))==1
                                        yn=protectedEvalXY(equation,x,y);
                                        if isnumeric(yn) && length(yn)==length(x{1})
                                            figure('tag','plotlab figure','name',figLabel,'numbertitle','off','windowstyle','docked');
                                            hold all; grid on; drawnow;
                                            xlabel(get(hXLabel,'String'),'Interpreter',get(hXLabel,'Interpreter'));
                                            plot(x{1},yn,'linestyle',get(hhLine(1),'linestyle'),'linewidth',get(hhLine(1),'linewidth')...
                                                ,'marker',get(hhLine(1),'marker'),'markersize',get(hhLine(1),'markersize'));
                                        else
                                            showError('Invalid factor or equation!\nUse a scalar to multiply, use x/y to manipulate axes, or use y{} to create new data.')
                                            return
                                        end
                                    else
                                        showError('All sizes must be same!')
                                        return
                                    end
                                else
                                    showError('Invalid factor or equation!\nUse a scalar to multiply, use x/y to manipulate axes, or use y{} to create new data.')
                                    return
                                end
                            else
                                for ii=1:numel(hhLine)
                                    x=get(hhLine(ii),'xdata');
                                    y=get(hhLine(ii),'ydata');
                                    yn=protectedEvalXY(equation,x,y);
                                    if isnumeric(yn) && numel(yn)==numel(y)
                                        set(hhLine(ii),'ydata',yn);
                                        if ~selection
                                            ylim('auto');
                                        end
                                    else
                                        showError('Invalid factor or equation!\nUse a scalar to multiply, use x/y to manipulate axes, or use y{} to create new data.')
                                        return
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
%
%
%% onFigureCrop
    function onFigureCrop(hObject,eventData)
        try
            if ~isempty(findobj('type','figure'))
                yLims=get(gca,'ylim');
                xLims=get(gca,'xlim');
                hLine=findobj(gca,'type','line','selected','on');
                if isempty(hLine)
                    hLine=findobj(gca,'type','line');
                end
                if ~isempty(hLine)
                    answer=inputdlg({'xlim','ylim'},'Crop',1,{num2str(xLims),num2str(yLims)});
                    drawnow; pause(0.01);
                    try
                        if ~(numel(answer)==2 && numel(str2num(answer{1}))==2 && numel(str2num(answer{2}))==2)
                            return
                        end
                    catch
                        return
                    end
                    xLims=str2num(answer{1});
                    yLims=str2num(answer{2});
                    for i=1:numel(hLine)
                        xVals=get(hLine(i),'xdata');
                        yVals=get(hLine(i),'ydata');
                        ind=(xVals<xLims(1) | xVals>xLims(2) | yVals<yLims(1) | yVals>yLims(2));
                        set(hLine(i),'xdata',xVals(~logical(ind)),'ydata',yVals(~logical(ind)));
                    end
                end
            end
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onFigureDiffColors
    function onFigureDiffColors(hObject,eventData)
        try
            if ~isempty(findobj('type','figure'))
                colors=[0,0,1;0,0.5,0;1,0,0;0,0.75,0.75;0.75,0,0.75;0.75,0.75,0;0.25,0.25,0.25];
                hLine=findobj(gca,'type','line');
                if numel(hLine)==2
                    colors([2,3],:)=colors([3,2],:);
                end
                for i=1:numel(hLine)
                    colorInd=mod(i,7);
                    if colorInd==0
                        colorInd=7;
                    end
                    set(hLine(numel(hLine)-i+1),'color',colors(colorInd,:))
                end
            end
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onFigureFFT
    function onFigureFFT(hObject,eventData)
        try
            if ~isempty(findobj('type','figure'))
                ylims=get(gca,'ylim');
                xlims=get(gca,'xlim');
                hLine=findobj(gca,'type','line','selected','on');
                if isempty(hLine)
                    hLine=findobj(gca,'type','line');
                end
                if isempty(hLine)
                    return
                end
                hFig=[];
                hLine=fliplr(reshape(hLine,1,[]));
                for i=1:numel(hLine)
                    y=get(hLine(i),'ydata');
                    x=get(hLine(i),'xdata');
                    dn=get(hLine(i),'displayname');
                    ind=find(y>=ylims(1) & y<=ylims(2) & x>=xlims(1) & x<=xlims(2));
                    if numel(ind)>=2
                        % inputs
                        [b,m,n]=unique(round(diff(x(ind))*1e7)/1e7);
                        mode=0;
                        dt=[];
                        if any(b==0)
                            showError('Time data must be distinct and monotonically increasing!')
                            return
                        elseif all(b>=1) %means x values are index
                            mode=1;
                        elseif numel(b)<50
                            mode=0;
                            for j=1:numel(b)
                                if sum(n==j)>numel(n)/2 && b(j)<1
                                    dt=b(j);
                                    break
                                end
                            end
                        end
                        if isempty(dt)
                            if mode==0 || (mode==1 && isempty(hFig))
                                prf0=getpref('plotlab','prf0');
                                if ~(isfield(prf0.persistent,'FigureFFT') && iscell(prf0.persistent.FigureFFT) && ...
                                        numel(prf0.persistent.FigureFFT)==1 && ischar(prf0.persistent.FigureFFT{1}))
                                    prf0.persistent.FigureFFT={''};
                                end
                                answer=inputdlg({'Sampling period [ms]'},dn,1,prf0.persistent.FigureFFT);
                                drawnow; pause(0.01);
                            end
                            try
                                dt=str2num(answer{1})*1e-3;
                                if ~isnumeric(dt) || numel(dt)~=1 || dt<=0
                                    return
                                end
                                prf0.persistent.FigureFFT=answer;
                                setpref('plotlab','prf0',prf0);
                            catch
                                return
                            end
                        end
                        % window
                        x=x(ind);
                        y=y(ind);
                        % interpolate
                        nanInd=(isnan(x)|isnan(y));
                        x=x(~nanInd);
                        y=y(~nanInd);
                        if mode
                            xref=min(x):1:max(x);
                            y=interp1(x,y,xref);
                            x=xref*dt;
                        else
                            xref=min(x):dt:max(x);
                            y=interp1(x,y,xref);
                            x=xref;
                        end
                        %fft
                        y=y-mean(y);
                        s=2^nextpow2(length(y));
                        Y=fft(y,s)/length(y);
                        Y=reshape(Y,1,length(Y));
                        Y=[Y(1) 2*abs(Y(2:s/2))];
                        f=(1/dt)/2*linspace(0,1,s/2);
                        % plot
                        if isempty(hFig)
                            hFig=figure('tag','plotlab figure','name',strtrim([get(gcf,'name') ' (fft)']),...
                                'numbertitle','off','windowstyle','docked');
                            subplot(2,1,1); hold all; grid on;
                            xlabel('time [s]'); ylabel('data');
                            subplot(2,1,2); hold all; grid on;
                            xlabel('frequency [Hz]'); ylabel('magnitude');
                        end
                        figure(hFig)
                        subplot(2,1,1);
                        plot(x,y,'displayname',dn,'color',get(hLine(i),'color'));
                        subplot(2,1,2);
                        plot(f,Y,'displayname',dn,'color',get(hLine(i),'color'));
                    end
                end
            end
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onFigureFitPoly
    function onFigureFitPoly(hObject,eventData)
        try
            if ~isempty(findobj('type','figure'))
                ylims=get(gca,'ylim');
                xlims=get(gca,'xlim');
                hLine=findobj(gca,'type','line','selected','on');
                if isempty(hLine)
                    hLine=findobj(gca,'type','line');
                end
                degree=[];
                clipboardText=[];
                if isempty(hLine)
                    return
                end
                hLine=fliplr(reshape(hLine,1,[]));
                for i=1:numel(hLine)
                    y=get(hLine(i),'ydata');
                    x=get(hLine(i),'xdata');
                    c=get(hLine(i),'color'); %#ok<NASGU>
                    dn=get(hLine(i),'displayname'); %#ok<NASGU>
                    ind=find(y>=ylims(1) & y<=ylims(2) & x>=xlims(1) & x<=xlims(2));
                    if numel(ind)>=2 && ~strcmp(get(hLine(i),'tag'),'polynomialCurveFit')
                        if isempty(degree)
                            prf0=getpref('plotlab','prf0');
                            if ~(isfield(prf0.persistent,'FigureFitPoly') && iscell(prf0.persistent.FigureFitPoly) ...
                                    && numel(prf0.persistent.FigureFitPoly)==1 && ischar(prf0.persistent.FigureFitPoly{1}))
                                prf0.persistent.FigureFitPoly={''};
                            end
                            answer=inputdlg({'Degree of polynomial'},'Line Fit',1,prf0.persistent.FigureFitPoly);
                            drawnow; pause(0.01);
                            if isempty(answer)
                                return
                            else
                                degree=str2num(answer{1});
                                if ~isnumeric(degree) || numel(degree)~=1 || degree<0
                                    return
                                end
                                prf0.persistent.FigureFitPoly=answer;
                                setpref('plotlab','prf0',prf0);
                            end
                        end
                        if degree<=4
                            t=now; pause(1e-5);
                            p=polyfit(x(ind),y(ind),degree);
                            dispName=regexprep(['[' num2str(p) ']'],'(?<=\S)\s*',' ');
                            hold on; plot(x(ind),polyval(p,x(ind)),'linestyle','-','linewidth',2',...
                                'color','k','parent',gca,'displayname','fit','tag','polynomialCurveFit','userdata',t,...
                                'deletefcn','delete(findobj(''type'',''text'',''userdata'',get(gcbo,''userdata'')))');
                            text(max(x(ind)),polyval(p,max(x(ind))),dispName,'horizontalalignment','right',...
                                'verticalalignment','top','fontweight','bold','userdata',t);
                        else
                            p=polyfit(x(ind),y(ind),degree);
                            dispName=regexprep(['[' num2str(p) ']'],'(?<=\S)\s*',' ');
                            clipboardText=[clipboardText,dispName,sprintf('\n')];
                            hold on; plot(x(ind),polyval(p,x(ind)),'linestyle','-','linewidth',2',...
                                'color','k','parent',gca,'displayname','fit','tag','polynomialCurveFit');
                        end
                    end
                end
                if ~isempty(degree) && degree>4 && ~isempty(clipboardText)
                    answer=questdlg('Copy coefficients to clipboard?','Confirmation','Yes','No','Yes');
                    drawnow; pause(0.01);
                    if strcmp(answer,'Yes')
                        clipboardText=regexprep(clipboardText,'\n$','');
                        clipboard('copy',clipboardText)
                    end
                end
            end
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onFigureMeanAndStd
    function onFigureMeanAndStd(hObject,eventData)
        try
            if ~isempty(findobj('type','figure'))
                ylims=get(gca,'ylim');
                xlims=get(gca,'xlim');
                hLine=findobj(gca,'type','line','selected','on');
                if isempty(hLine)
                    hLine=findobj(gca,'type','line');
                end
                clipboardText=[];
                if isempty(hLine)
                    return
                end
                hLine=fliplr(reshape(hLine,1,[]));
                for i=1:numel(hLine)
                    y=get(hLine(i),'ydata');
                    x=get(hLine(i),'xdata');
                    c=get(hLine(i),'color');
                    dn=get(hLine(i),'displayname');
                    ind=find(y>=ylims(1) & y<=ylims(2) & x>=xlims(1) & x<=xlims(2));
                    if numel(ind)>=2 && ~strcmp(get(hLine(i),'tag'),'polynomialCurveFit')
                        clipboardText=[clipboardText '\color[rgb]{' num2str(c) '}' dn ...
                            '  mean:' num2str(mean(y(ind))) ' std:' num2str(std(y(ind))) sprintf('\n')];
                    end
                end
                if ~isempty(clipboardText)
                    clipboardText=regexprep(clipboardText,'\n$','');
                    delete(findobj(gca,'type','Text','tag','mean'))
                    text(xlims(1),ylims(2),clipboardText,'tag','mean','fontweight','bold','EdgeColor','black',...
                        'horizontalalignment','left','verticalalignment','top','BackgroundColor',[1 1 1]);
                end
            end
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onFigureLineMark
    function onFigureLineMark(hObject,eventData)
        try
            if ~isempty(findobj('type','figure'))
                hLine=findobj(gca,'type','line','selected','on');
                if isempty(hLine)
                    hLine=findobj(gcf,'type','line');
                end
                if isempty(hLine)
                    return
                elseif numel(hLine)==1
                    lineS=get(hLine,'linestyle');
                    markS=get(hLine,'marker');
                elseif numel(hLine)>1
                    lineS=unique(get(hLine,'linestyle'));
                    markS=unique(get(hLine,'marker'));
                    if numel(lineS)==1 && iscell(lineS)
                        lineS=lineS{1};
                    end
                    if numel(markS)==1 && iscell(markS)
                        markS=markS{1};
                    end
                end
                if ischar(lineS) && strcmp(lineS,'-') && ...
                        ischar(markS) && strcmp(markS,'none')
                    lineS='-';
                    markS='.';
                elseif ischar(lineS) && strcmp(lineS,'-') && ...
                        ischar(markS) && strcmp(markS,'.')
                    lineS='none';
                    markS='.';
                else
                    lineS='-';
                    markS='none';
                end
                for i=1:numel(hLine)
                    set(hLine(i),'linestyle',lineS);
                    set(hLine(i),'marker',markS);
                end
                grid on;
            end
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onFigureScale
    function onFigureScale(hObject,eventData)
        try
            if ~isempty(findobj('type','figure'))
                hLine=findobj(gca,'type','line');
                hRefLine=findobj(gca,'type','line','selected','on');
                ylims=get(gca,'ylim');
                xlims=get(gca,'xlim');
                if numel(hRefLine)~=1
                    hRefLine=hLine(end);
                end
                if numel(hLine)>1
                    if isempty(legend)
                        leg=0;
                    else
                        leg=1;
                        delete(legend);
                    end
                    mode=getUserData(gca,'scaleMode');
                    if ~(ischar(mode) && strcmp(mode,'scaled'))
                        setUserData(gca,'scaleMode','scaled');
                        x=get(hRefLine,'xdata');
                        y=get(hRefLine,'ydata');
                        ind=(y>=ylims(1) & y<=ylims(2) & x>=xlims(1) & x<=xlims(2));
                        ref_std=std(y(~isnan(y) & ind));
                        ref_mean=mean(y(~isnan(y) & ind));
                        hLine=fliplr(reshape(hLine,1,[]));
                        for i=1:numel(hLine)
                            yDisp=get(hLine(i),'displayname');
                            x=get(hLine(i),'xdata');
                            y=get(hLine(i),'ydata');
                            ind=(y>=ylims(1) & y<=ylims(2) & x>=xlims(1) & x<=xlims(2));
                            props={'xdata','ydata','displayname'};
                            for j=1:numel(props)
                                setUserData(hLine(i),props{j},get(hLine(i),props{j}));
                            end
                            if hLine(i)~=hRefLine
                                cur_std=std(y(~isnan(y) & ind));
                                cur_mean=mean(y(~isnan(y) & ind));
                                scale=ref_std/cur_std;
                                if isnan(scale) || scale==Inf || scale==0 || abs(scale-1)<0.1
                                    scale=1;
                                end
                                if scale>=1
                                    scale=round(scale*10)/10;
                                else
                                    scaleFix=str2double(num2str(scale,1));
                                    if ~isnan(scaleFix)
                                        scale=scaleFix;
                                    end
                                end
                                bias=cur_mean*scale-ref_mean;
                                if isnan(bias) || bias==Inf || abs(bias)<ref_std*2
                                    bias=0;
                                end
                                if abs(bias)>=1
                                    bias=round(bias*10)/10;
                                else
                                    biasFix=str2double(num2str(bias,1));
                                    if ~isnan(biasFix)
                                        bias=biasFix;
                                    end
                                end
                                set(hLine(i),'ydata',y*scale-bias)
                                if isempty(yDisp)
                                    yDisp=['data' num2str(i)];
                                end
                                if ~strcmp(num2str(scale),'1')
                                    yDisp=[yDisp ' *' num2str(scale)];
                                end
                                if ~strcmp(num2str(bias),'0')
                                    if bias>0
                                        yDisp=[yDisp ' -' num2str(abs(bias))];
                                    else
                                        yDisp=[yDisp ' +' num2str(abs(bias))];
                                    end
                                end
                            elseif isempty(yDisp)
                                yDisp=['data' num2str(i)];
                            end
                            set(hLine(i),'displayname',yDisp)
                        end
                    else
                        setUserData(gca,'scaleMode','normal');
                        for i=1:numel(hLine)
                            try
                                props={'xdata','ydata','displayname'};
                                for j=1:numel(props)
                                    value=getUserData(hLine(i),props{j});
                                    set(hLine(i),props{j},value)
                                end
                            end
                        end
                    end
                    xlim('auto'); ylim('auto');
                    if leg
                        legend('show');
                        set(legend,'interpreter','none','location','best');
                    end
                end
            end
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onFilterFigureButtonDown
    function onFilterFigureButtonDown(hObject,eventData)
        try
            hAxes=findobj(hObject,'type','axes','tag','');
            hLine1=findobj(hAxes,'type','line','displayname','data');
            hLine2=findobj(hAxes,'type','line','displayname','spikes');
            if isempty(hLine1) || isempty(hLine2) || numel(hLine1)~=numel(hLine2)
                showError('Plot new data and try again!');
                terminateFilterMode;
                return
            end
            loc=get(hAxes,'CurrentPoint');
            xVal=loc(1,1); yVal=loc(1,2);
            xVals1=get(hLine1,'xdata'); yVals1=get(hLine1,'ydata');
            if ~iscell(xVals1)
                xVals1={xVals1};
                yVals1={yVals1};
            end
            xVals2=get(hLine2,'xdata'); yVals2=get(hLine2,'ydata');
            if ~iscell(xVals2)
                xVals2={xVals2};
                yVals2={yVals2};
            end
            xLim=get(hAxes,'XLim'); yLim=get(hAxes,'YLim');
            scale=(xLim(2)-xLim(1))/(yLim(2)-yLim(1));
            switch get(hObject,'SelectionType')
                case 'normal'
                    switch prf.filterMode
                        case 'erase'
                            for i=1:numel(xVals1)
                                ind=find(xVals1{i}>=xLim(1) & xVals1{i}<=xLim(2) & yVals1{i}>=yLim(1) & yVals1{i}<=yLim(2) & ...
                                    ~(ismember(xVals1{i},xVals2{i})&ismember(yVals1{i},yVals2{i})));
                                dist=reshape(sqrt((xVals1{i}(ind)-xVal).^2+((yVals1{i}(ind)-yVal)*scale).^2),1,[]);
                                if isempty(dist)
                                    sel(i)=0;
                                    minDist(i)=Inf;
                                else
                                    sel(i)=ind(find(dist==min(dist),1));
                                    minDist(i)=min(dist);
                                end
                            end
                            id=find(minDist==min(minDist));
                            for i=1:numel(id)
                                if minDist(id(i))~=Inf
                                    set(hLine2(id(i)),'xdata',[xVals2{id(i)} xVals1{id(i)}(sel(id(i)))],...
                                        'ydata',[yVals2{id(i)} yVals1{id(i)}(sel(id(i)))]);
                                end
                            end
                        case 'first'
                            for i=1:numel(xVals1)
                                ind=find(xVals1{i}>=xLim(1) & xVals1{i}<=xLim(2) & yVals1{i}>=yLim(1) & yVals1{i}<=yLim(2));
                                dist=sqrt((xVals1{i}(ind)-xVal).^2+((yVals1{i}(ind)-yVal)*scale).^2);
                                if isempty(dist)
                                    sel(i)=0;
                                    minDist(i)=Inf;
                                else
                                    sel(i)=ind(find(dist==min(dist),1));
                                    minDist(i)=min(dist);
                                end
                            end
                            id=find(minDist==min(minDist),1);
                            if minDist(id)~=Inf
                                ind=((1:numel(xVals1{i}))<=sel(id));
                                for i=1:numel(xVals1)
                                    set(hLine2(i),'xdata',xVals1{i}(ind),'ydata',yVals1{i}(ind));
                                end
                            end
                        case 'last'
                            for i=1:numel(xVals1)
                                ind=find(xVals1{i}>=xLim(1) & xVals1{i}<=xLim(2) & yVals1{i}>=yLim(1) & yVals1{i}<=yLim(2));
                                dist=sqrt((xVals1{i}(ind)-xVal).^2+((yVals1{i}(ind)-yVal)*scale).^2);
                                if isempty(dist)
                                    sel(i)=0;
                                    minDist(i)=Inf;
                                else
                                    sel(i)=ind(find(dist==min(dist),1));
                                    minDist(i)=min(dist);
                                end
                            end
                            id=find(minDist==min(minDist),1);
                            if minDist(id)~=Inf
                                ind=((1:numel(xVals1{i}))>=sel(id));
                                for i=1:numel(xVals1)
                                    set(hLine2(i),'xdata',xVals1{i}(ind),'ydata',yVals1{i}(ind));
                                end
                            end
                    end
                case 'alt'
                    switch prf.filterMode
                        case 'erase'
                            for i=1:numel(xVals2)
                                dist=sqrt((xVals2{i}-xVal).^2+((yVals2{i}-yVal)*scale).^2);
                                if isempty(dist)
                                    sel(i)=0;
                                    minDist(i)=Inf;
                                else
                                    sel(i)=find(dist==min(dist),1);
                                    minDist(i)=min(dist);
                                end
                            end
                            id=find(minDist==min(minDist));
                            for i=1:numel(id)
                                if minDist(id(i))~=Inf
                                    xVals2{id(i)}(sel(id(i)))=[]; yVals2{id(i)}(sel(id(i)))=[];
                                    set(hLine2(id(i)),'xdata',xVals2{id(i)},'ydata',yVals2{id(i)});
                                end
                            end
                        case 'first'
                            %do nothing!
                        case 'last'
                            %do nothing!
                    end
            end
            drawnow;
        catch
            showError('Plot new data and try again!');
            terminateFilterMode;
            return
        end
    end
%
%
%% onFilterFigureClose
    function onFilterFigureClose(hObject,eventData)
        try
            terminateFilterMode;
        end
        delete(hObject);
    end
%
%
%% onFilterFigureKeyPress
    function onFilterFigureKeyPress(hObject,eventData)
        try
            hAxes=findobj(hObject,'type','axes','tag','');
            hLine1=findobj(hAxes,'type','line','displayname','data');
            hLine2=findobj(hAxes,'type','line','displayname','spikes');
            xVals1=get(hLine1,'xdata'); yVals1=get(hLine1,'ydata');
            if ~iscell(xVals1)
                xVals1={xVals1};
                yVals1={yVals1};
            end
            xVals2=get(hLine2,'xdata'); yVals2=get(hLine2,'ydata');
            if ~iscell(xVals2)
                xVals2={xVals2};
                yVals2={yVals2};
            end
            if isempty(hLine1) || isempty(hLine2) || numel(hLine1)~=numel(hLine2) || ...
                    numel(unique(cellfun(@(x)(numel(x)),xVals1,'uniformoutput',1)))~=1
                showError('Plot new data and try again!');
                terminateFilterMode;
                return
            end
            for i=1:numel(hLine1)
                ind=getUserData(hLine1(i),'logInd');
                log=eval(logInfo{ind,1});
                dataInd=logInfo{ind,2};
                data=extractLogData(log,dataInd);
                data=reshape(data,[],1);
                factor=getUserData(hLine1(i),'logDataFactor');
                data=double(data)*factor;
                data2=double(reshape(yVals1{i},[],1));
                if ~isequalwithequalnans(data,data2)
                    showError('Plot new data and try again!');
                    terminateFilterMode;
                    return
                end
            end
            switch lower(eventData.Key)
                case 'return'
                    ind1=zeros(size(xVals1{i}));
                    for i=1:numel(xVals1)
                        ind1=logical(ind1 | (ismember(xVals1{i},xVals2{i}) & ismember(yVals1{i},yVals2{i})));
                    end
                    if sum(ind1)>0
                        signal='';
                        for i=1:size(logInfo,1)
                            if ~strcmp(logInfo{i,1},signal)
                                signal=logInfo{i,1};
                                eval([signal '(ind1,:)=[];'])
                            end
                        end
                        for i=1:numel(xVals1)
                            ind2=(ismember(xVals2{i},xVals1{i}) & ismember(yVals2{i},yVals1{i}));
                            xVals1{i}(ind1)=[]; yVals1{i}(ind1)=[];
                            xVals2{i}(ind2)=[]; yVals2{i}(ind2)=[];
                            set(hLine1(i),'xdata',xVals1{i},'ydata',yVals1{i});
                            set(hLine2(i),'xdata',xVals2{i},'ydata',yVals2{i});
                        end
                    end
                case {'space','n','l'} %doesnt change bit signals
                    for i=1:numel(xVals1)
                        ind1=(ismember(xVals1{i},xVals2{i}) & ismember(yVals1{i},yVals2{i}));
                        ind2=(ismember(xVals2{i},xVals1{i}) & ismember(yVals2{i},yVals1{i}));
                        if sum(ind1)>0
                            ind=getUserData(hLine1(i),'logInd');
                            data=double(eval(logInfo{ind,1}));
                            if logInfo{ind,2}<1 %bit signal
                                %dont change log
                                %xVals1{i}(ind1)=NaN; yVals1{i}(ind1)=NaN;
                                %xVals2{i}(ind2)=[]; yVals2{i}(ind2)=[];
                                %set(hLine1(i),'xdata',xVals1{i},'ydata',yVals1{i});
                                %set(hLine2(i),'xdata',xVals2{i},'ydata',yVals2{i});
                            else
                                switch lower(eventData.Key)
                                    case 'space'
                                        data(ind1,logInfo{ind,2})=NaN;
                                        eval([logInfo{ind,1} '=data;'])
                                        yVals1{i}(ind1)=NaN;
                                        xVals2{i}(ind2)=[]; yVals2{i}(ind2)=[];
                                        set(hLine1(i),'xdata',xVals1{i},'ydata',yVals1{i});
                                        set(hLine2(i),'xdata',xVals2{i},'ydata',yVals2{i});
                                    case 'l'
                                        xi=xVals1{i}(ind1);
                                        baseX=xVals1{i}(~ind1);
                                        baseY=yVals1{i}(~ind1);
                                        nanInd=(isnan(baseX)|isnan(baseY));
                                        baseX(nanInd)=[];
                                        baseY(nanInd)=[];                                        
                                        newValues=interp1(baseX,baseY,xi,'linear','extrap');
                                        factor=getUserData(hLine1(i),'logDataFactor');
                                        data(ind1,logInfo{ind,2})=newValues/factor;
                                        eval([logInfo{ind,1} '=data;'])
                                        yVals1{i}(ind1)=newValues/factor*factor;
                                        xVals2{i}(ind2)=[]; yVals2{i}(ind2)=[];
                                        set(hLine1(i),'xdata',xVals1{i},'ydata',yVals1{i});
                                        set(hLine2(i),'xdata',xVals2{i},'ydata',yVals2{i});
                                    case 'n'
                                        xi=xVals1{i}(ind1);
                                        baseX=xVals1{i}(~ind1);
                                        baseY=yVals1{i}(~ind1);
                                        nanInd=(isnan(baseX)|isnan(baseY));
                                        baseX(nanInd)=[];
                                        baseY(nanInd)=[];                                        
                                        newValues=interp1(baseX,baseY,xi,'nearest','extrap');
                                        factor=getUserData(hLine1(i),'logDataFactor');
                                        data(ind1,logInfo{ind,2})=newValues/factor;
                                        eval([logInfo{ind,1} '=data;'])
                                        yVals1{i}(ind1)=newValues;
                                        xVals2{i}(ind2)=[]; yVals2{i}(ind2)=[];
                                        set(hLine1(i),'xdata',xVals1{i},'ydata',yVals1{i});
                                        set(hLine2(i),'xdata',xVals2{i},'ydata',yVals2{i});
                                end
                            end
                        end
                    end
                case 'escape'
                    for i=1:numel(xVals1)
                        ind1=(ismember(xVals1{i},xVals2{i}) & ismember(yVals1{i},yVals2{i}));
                        ind2=(ismember(xVals2{i},xVals1{i}) & ismember(yVals2{i},yVals1{i}));
                        xVals2{i}(ind2)=[]; yVals2{i}(ind2)=[];
                        set(hLine1(i),'xdata',xVals1{i},'ydata',yVals1{i});
                        set(hLine2(i),'xdata',xVals2{i},'ydata',yVals2{i});
                    end
            end
            drawnow;
        catch
            showError('Plot data and try again!');
            terminateFilterMode;
            return
        end
    end
%
%
%% onFrameClose
    function onFrameClose(hObject,eventData)
        % delete frame
        try
            terminateFilterMode;
            setPrf;
        end
        delete(hObject);
        drawnow; pause(0.01);
        % save info and check update
        try
            set(0,'ShowHiddenHandles','on');
            hFig=findobj('tag','plotlab','userdata','plotlab');
            set(0,'ShowHiddenHandles','off');
            if isempty(hFig)
                % check to continue
                if ~exist('\\Cezeri\kullanicilar\AAKSU\Matlab\plotlab.m','file')
                    %return
                end
                % save stats
                try
                    prf0=getpref('plotlab','prf0');
                    statFile=load('\\Cezeri\kullanicilar\AAKSU\Matlab\stats.mat');
                    if isfield(statFile,'stats')
                        stats=statFile.stats;
                        idOk=0;
                        if isstruct(stats) && ~isempty(fieldnames(stats))
                            try
                                idInd=prf.userInd;
                                if strcmp(stats(idInd).id,prf.username)
                                    idOk=1;
                                end
                            end
                            if ~idOk
                                for i=1:numel(stats)
                                    try
                                        if strcmp(stats(i).id,prf.username)
                                            idOk=1;
                                            idInd=i;
                                            prf.userInd=idInd;
                                            setPrf;
                                        end
                                    end
                                end
                            end
                            if ~idOk
                                idInd=numel(stats)+1;
                                prf.userInd=idInd;
                                setPrf;
                            end
                        else
                            stats=struct;
                            idInd=1;
                            prf.userInd=idInd;
                            setPrf;
                        end
                    else
                        stats=struct;
                        idInd=1;
                        prf.userInd=idInd;
                        setPrf;
                    end
                    clockNum=clock;
                    clockstr=regexprep(num2str(clockNum(1:5)),' *',' ');
                    stats(idInd).id=prf.username;
                    stats(idInd).date=clockstr;
                    stats(idInd).totalPlots=prf0.totalPlots;
                    statFile=struct;
                    statFile.stats=stats;
                    save('\\Cezeri\kullanicilar\AAKSU\Matlab\stats.mat','-struct','statFile');
                end
                %
                try
                    if  any(strcmpi(getenv('username'),{'ulas.ates','arda.aksu','AKIF.ALTUN','SULEYMAN.BUYUKKOCAK',...
                            'berk.gezer','ANIL.SEL','ozgun.dulgar','gorkem.essiz','can.babaoglu'}))
                        try
                            stop(timerfind('userdata','plotlabprank'))
                            delete(timerfind('userdata','plotlabprank'))
                        end
                    end
                end
                %
                % update
                try
                    f=fileread([mfilename('fullpath') '.m']);
                    v=regexp(f,'(?<=\n% )\d\d\.\d\d\.\d\d\d\d(?=[^\r]*\r\n)','match');
                    myVer=datenum(v{1},'dd.mm.yyyy');
                    f=fileread('\\Cezeri\kullanicilar\AAKSU\Matlab\plotlab.m');
                    v=regexp(f,'(?<=\n% )\d\d\.\d\d\.\d\d\d\d(?=\r\n)','match');
                    newVer=datenum(v{1},'dd.mm.yyyy');
                    if newVer>myVer
                        try
                            copyfile('\\Cezeri\kullanicilar\AAKSU\Matlab\plotlab.m',[mfilename('fullpath') '.m']);
                            % do not do anything else after this!
                        catch
                            wDlg=warndlg(['New version is available at:' sprintf('\n') ...
                                '\\Cezeri\kullanicilar\AAKSU\Matlab\'],'plotlab','replace');
                            set(wDlg,'WindowStyle','modal','closerequestfcn','delete(gcbf);')
                            uiwait(wDlg);
                            drawnow; pause(0.01);
                        end
                    else
                        continue_with_catch
                    end
                catch
                    allPrf=getpref('plotlab');
                    fn=fieldnames(allPrf);
                    for i=1:numel(fn)
                        try
                            if isempty(strfind(lower(allPrf.(fn{i}).pwd),'\aaksu\matlab')) && ...
                                    exist([allPrf.(fn{i}).pwd '\plotlab.m'],'file')
                                f=fileread([allPrf.(fn{i}).pwd '\plotlab.m']);
                                v=regexp(f,'(?<=\n% )\d\d\.\d\d\.\d\d\d\d(?=[^\r]*\r\n)','match');
                                ver=datenum(v{1},'dd.mm.yyyy');
                                if ver<myVer
                                    copyfile([mfilename('fullpath') '.m'],[allPrf.(fn{i}).pwd '\plotlab.m']);
                                end
                            end
                        end
                    end
                end
            end
        end
    end
%
%
%% onGetDividerLocation
    function onGetDividerLocation(hObject,eventData)
        sPaneSize=gui.splitPane.getSize;
        sPaneWidth=sPaneSize.getWidth;
        sPaneLoc=gui.splitPane.getDividerLocation/(sPaneSize.getWidth-gui.splitPane.getDividerSize);
        sPaneLoc=max(0,sPaneLoc); sPaneLoc=min(1,sPaneLoc);
        switch prf.mode
            case 'struct'
                prf.sPaneLocStruct=sPaneLoc;
                prf.sPaneWidthStruct=sPaneWidth;
            otherwise
                prf.sPaneLoc=sPaneLoc;
                prf.sPaneWidth=sPaneWidth;
        end
    end
%
%
%% onModeChange
    function onModeChange(hObject,eventData)
        try
            switch get(hObject,'label')
                case 'Simulation'
                    prf.mode='sim';
                    if ~isempty(findobj(gui.menuMode,'label','Structure','checked','on'))
                        refreshInterface;
                    end
                case 'xPC'
                    prf.mode='xpc';
                    if ~isempty(findobj(gui.menuMode,'label','Structure','checked','on'))
                        refreshInterface;
                    end
                case 'Structure'
                    prf.mode='struct';
                    if ~isempty(findobj(gui.menuMode,'label','Structure','checked','off'))
                        refreshInterface;
                    end
            end
            refreshMenuModes;
            refreshMenuTools;
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onMousePressedList
    function onMousePressedList(hObject,eventData)
        try
            if eventData.isMetaDown
                % show menu
                gui.listMenu.show(gui.list,eventData.getX,eventData.getY);
                gui.listMenu.revalidate;
                gui.listMenu.repaint;
            end
        end
        drawnow;
    end
%
%
%% onMousePressedTree
    function onMousePressedTree(hObject,eventData)
        try
            if eventData.isMetaDown  %right-click
                % show menu
                gui.treeMenu.show(gui.tree,eventData.getX,eventData.getY);
                gui.treeMenu.revalidate;
                gui.treeMenu.repaint;
            end
        end
    end
%
%
%% onRightClickPlot
    function onRightClickPlot(hObject,eventData,mode,type)
        try
            % check data and refresh quickly
            switch prf.mode
                case 'sim'
                    if isempty(logData)
                        showError('Log is empty!');
                        return
                    end
                    if ~isempty(prf.simLogBaseName)
                        if isempty(findobj(gui.menuTools,'label','Lock log','checked','on'))
                            try
                                if strcmp(get_param(logData.name,'SimulationStatus'),'running')
                                    set_param(logData.name,'SimulationCommand','WriteDataLogs');
                                end
                            end
                            try
                                simLogNew=evalin('base',prf.simLogBaseName);
                                if strcmp(simLogNew.Name,logData.Name)
                                    logData=simLogNew;
                                end
                            end
                        end
                    else
                        showError('Refresh log and try again!');
                        return
                    end
                case 'xpc'
                    if isempty(xpcData.data)
                        showError('xPC data is empty!');
                        return
                    end
                case 'struct'
                    filterMode=0;
                    if ~isempty(findobj(gui.menuToolsStruct,'label','Erase points','checked','on'))
                        filterMode=1;
                    end
                    terminateFilterMode; %make sure there wont be any other filter figure
                    if isempty(logData)
                        showError('Data is empty!');
                        return
                    end
            end
            % get selection
            switch mode
                case 'tree'
                    selection=getSelectedTreeIndices;
                case 'list'
                    selection=getSelectedListIndices;
            end
            % check plot types
            if type==2 && isempty(findobj('type','figure'))
                type=1;
            end
            if numel(selection)>30
                input=gui.optionPane.showOptionDialog(gui.jFrame,...
                    ['You are about to plot ' num2str(numel(selection)) ' lines.']...
                    ,'',0,3,[],{'Ok','Cancel'},{'Ok'});
                drawnow; pause(0.01);
                if input~=0
                    return
                end
            end
            % check xAxis assignment and get data
            if ~isempty(prf.xAxis)
                switch prf.mode
                    case 'sim'
                        try
                            log=eval(logInfo{prf.xAxis,1});
                        catch
                            showError('Refresh log and try again!');
                            return
                        end
                        dataInd=logInfo{prf.xAxis,2};
                        [data,time,dimOk]=extractLogData(log,dataInd);
                        if ~dimOk
                            showError('Refresh log and try again!');
                            return
                        end
                        xData=data;
                        xTime=time;
                    case 'xpc'
                        xData=xpcData.data(:,prf.xAxis);
                        xTime=1:numel(xData);
                    case 'struct'
                        log=eval(logInfo{prf.xAxis,1});
                        dataInd=logInfo{prf.xAxis,2};
                        data=extractLogData(log,dataInd);
                        xData=data;
                        xTime=1:numel(xData);
                end
                if isempty(logInfo{prf.xAxis,4}) || ~isempty(strfind(logInfo{prf.xAxis,4},';'))
                    xLab=logInfo{prf.xAxis,3}{end};
                    if isempty(find(isstrprop(xLab,'digit')==0,1)) && numel(logInfo{prf.xAxis,3})>1
                        xLab=[logInfo{prf.xAxis,3}{end-1} '.' logInfo{prf.xAxis,3}{end}];
                    end
                else
                    xLab=logInfo{prf.xAxis,4};
                end
                try
                    factorx=str2num(logInfo{prf.xAxis,6});
                    if numel(factorx)==1
                        xData=double(xData)*factorx;
                    end
                end
                try
                    unit=logInfo{prf.xAxis,5};
                    if ~isempty(unit)
                        xLab=[strtrim(xLab) ' [' unit ']'];
                    end
                end
            else
                switch prf.mode
                    case 'sim'
                        xLab='time [s]';
                    case 'xpc'
                        if isempty(xpcData.time)
                            xLab='';
                        else
                            xLab='time [s]';
                        end
                    case 'struct'
                        xLab='';
                end
                xData=[];
                xTime=[];
            end
            % get ydata, ytime, displayname
            yTime={}; yData={}; yDisp={}; figNames={};
            for i=1:numel(selection)
                switch prf.mode
                    case 'sim'
                        try
                            log=eval(logInfo{selection(i),1});
                        catch
                            showError('Refresh log and try again!');
                            return
                        end
                        dataInd=logInfo{selection(i),2};
                        [data,time,dimOk]=extractLogData(log,dataInd);
                        if ~dimOk
                            showError('Refresh log and try again!');
                            return
                        end
                        yData{i}=data;
                        yTime{i}=time;
                    case 'xpc'
                        yData{i}=xpcData.data(:,selection(i));
                        if isempty(xpcData.time)
                            yTime{i}=1:numel(xpcData.data(:,selection(i)));
                        else
                            yTime{i}=xpcData.time;
                        end
                    case 'struct'
                        log=eval(logInfo{selection(i),1});
                        dataInd=logInfo{selection(i),2};
                        data=extractLogData(log,dataInd);
                        yData{i}=data;
                        yTime{i}=1:numel(data);
                end
                figNames{i}=logInfo{selection(i),3};
                if isempty(logInfo{selection(i),4}) || ~isempty(strfind(logInfo{selection(i),4},';'))
                    yDisp{i}=logInfo{selection(i),3};
                else
                    yDisp{i}=logInfo(selection(i),4);
                end
            end
            % yDisp was cell array of cells not string! get string list here
            yDisp=extractUniqueList(yDisp);
            figNames=extractUniqueList(figNames);
            % check to continue
            if isempty(yDisp)
                return
            end
            % correct data with factor and unit
            factor=ones(1,numel(selection));
            for i=1:numel(selection)
                try
                    factory=str2num(logInfo{selection(i),6});
                    if numel(factory)==1 && isempty(strfind(logInfo{selection(i),4},';'))
                        yData{i}=double(yData{i})*factory;
                        factor(i)=factory;
                    end
                end
                try
                    unit=logInfo{selection(i),5};
                    if ~isempty(unit) && isempty(strfind(logInfo{selection(i),4},';'))
                        yDisp{i}=[strtrim(yDisp{i}) ' [' unit ']'];
                    end
                end
            end
            % get figurename and ylabel
            yLab=yDisp{1};
            figName=regexprep(figNames{1},'(( \[)[^\[]*(\]$))|([ \*]$)','');
            if numel(yDisp)>1
                figName=[figName '  ...'];
                yLab='';
            end
            if type==1
                figure('tag','plotlab figure','name',figName,'numbertitle','off','windowstyle','docked');
                ylabel(yLab,'Interpreter','none');
                xlabel(xLab,'Interpreter','none');
                hold('all'); grid('on');
                drawnow;
            elseif type==2
                figure(gcf)
                legend('off');
                hold('all'); grid('on');
                drawnow;
            end
            % plot
            for i=1:numel(selection)
                % create figure if type is 3
                if type==3
                    figName=regexprep(figNames{i},'(( \[)[^\[]*(\]$))|([ \*]$)','');
                    figure('tag','plotlab figure','name',figName,'numbertitle','off','windowstyle','docked');
                    hold('all'); grid('on');
                    ylabel(yDisp{i},'Interpreter','none');
                    xlabel(xLab,'Interpreter','none');
                end
                % plot
                if isempty(prf.xAxis)
                    switch prf.mode
                        case {'sim','xpc'}
                            hLine=plot(yTime{i},yData{i},'display',yDisp{i},'visible','off');
                        case 'struct'
                            hLine=plot(yTime{i},yData{i},'display',yDisp{i},'visible','off');
                            setUserData(hLine,'logInd',selection(i));
                            setUserData(hLine,'logDataFactor',factor(i));
                    end
                else
                    switch prf.mode
                        case 'sim'
                            [temp,yTimeInd,xTimeInd]=intersect(round(double(yTime{i})*1e6),round(double(xTime)*1e6));
                            hLine=plot(xData(xTimeInd),yData{i}(yTimeInd),'display',yDisp{i},'visible','off');
                        case 'xpc'
                            %size should already be same with xData
                            if numel(xData)~=numel(yData{i})
                                showError('Something went wrong!');
                            end
                            hLine=plot(xData,yData{i},'display',yDisp{i},'visible','off');
                        case 'struct'
                            if numel(xData)~=numel(yData{i})
                                showError('Something went wrong!');
                            end
                            %size should already be same with xData
                            hLine=plot(xData,yData{i},'display',yDisp{i},'visible','off');
                            setUserData(hLine,'logInd',selection(i));
                            setUserData(hLine,'logDataFactor',factor(i));
                    end
                end
                % line properties
                try
                    switch prf.mode
                        case {'sim','xpc'}
                            set(hLine,prf.plotProperties(:,1).',prf.plotProperties(:,2).');
                        case 'struct'
                            set(hLine,prf.plotPropertiesStruct(:,1).',prf.plotPropertiesStruct(:,2).');
                    end
                end
                % make line visible
                set(hLine,'visible','on')
                if type==3
                    drawnow;
                    hold('off');
                end
            end
            % check legend
            if type==1 && numel(yDisp)>1 && numel(yDisp)<5
                legend('show');
                set(legend,'interpreter','none','location','best');
            else
                set(legend,'interpreter','none','location','best'); %doesnt work!
            end
            % release plot
            if type~=3
                hold('off');
            end
            % check filter for struct mode
            if strcmp(prf.mode,'struct') && type==1 && filterMode==1
                initiateFilterMode(gcf,'Erase points')
            end
            drawnow;
            % counters
            try
                prf0=getpref('plotlab','prf0');
                prf0.totalPlots=prf0.totalPlots+1;
                setpref('plotlab','prf0',prf0);
            end
            % prank
            try
                prf0=getpref('plotlab','prf0');
                if prf0.prank<2 && any(strcmpi(getenv('username'),{'can.babaoglu'}))
                    for t=0:10
                        set(get(gca,'children'),'visible','off')
                        pause(0.1)
                        set(get(gca,'children'),'visible','on')
                        pause(0.1)
                    end
                    %
                    warning('off','images:initSize:adjustingMag')
                    a=[]; b=[]; x=[];
                    load('\\Cezeri\kullanicilar\AAKSU\Matlab\data.mat');
                    sound(a,b);
                    f=figure('windowstyle','normal','menubar','none','numbertitle','off','toolbar','none','name','','position',[1,1,10,10]);
                    figure(f)
                    imshow(imresize(x,0.5))
                    xs=get(f,'position');
                    for t=0:1/30:4
                        p=get(0,'PointerLocation')+randn(1,2)*5;
                        set(f,'position',[p(1)-xs(3)/2 p(2)-xs(4)/2 xs(3) xs(4)])
                        pause(1/30)
                    end
                    close(f)
                    prf0.prank=2;
                    [status,result]=system('rundll32.exe user32.dll, LockWorkStation');
                end
                setpref('plotlab','prf0',prf0);
            end
        catch
            switch prf.mode
                case 'struct'
                    showError('Something went wrong!');
                otherwise
                    showError('Something went wrong!\nRefresh log and try again.');
            end
            return
        end
    end
%
%
%% onRightClickAssignX
    function onRightClickAssignX(hObject,eventData,mode)
        try
            switch mode
                case 'tree'
                    prf.xAxis=getSelectedTreeIndices;
                case 'list'
                    prf.xAxis=getSelectedListIndices;
            end
            if numel(prf.xAxis)>1
                prf.xAxis=[];
                showError('Multiple assignment is not allowed!');
            elseif numel(prf.xAxis)==1 && any(logInfo{prf.xAxis,2}<0)
                prf.xAxis=[];
                showError('Bit assignment is not allowed!');
            elseif numel(prf.xAxis)==1
                %ok
            else
                prf.xAxis=[];
            end
            refreshMenuRightClick;
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onRightClickClearX
    function onRightClickClearX(hObject,eventData)
        try
            prf.xAxis=[];
            refreshMenuRightClick;
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onRightClickCopyLog
    function onRightClickCopyLog(hObject,eventData,mode)
        if isempty(logInfo)
            return
        end
        try
            switch mode
                case 'tree'
                    ind=getSelectedTreeIndices(false);
                case 'list'
                    ind=getSelectedListIndices(false);
            end
            logList={};
            for i=ind
                logList{end+1}=logInfo{i,1};
            end
            [temp,p]=unique(logList,'first');
            logList=logList(sort(p));
            switch prf.mode
                case 'struct'
                    logList=regexprep(logList,'^logData',regexptranslate('escape',prf.structLogBaseName));
                otherwise
                    logList=regexprep(logList,'^logData',regexptranslate('escape',prf.simLogBaseName));
            end
            logStr='';
            for i=1:numel(logList)
                logStr=[logStr logList{i}];
                if i~=numel(logList)
                    logStr=[logStr sprintf('\n')];
                end
            end
            if ~isempty(logStr)
                clipboard('copy',logStr)
            end
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onRightClickDefineRule
    function onRightClickDefineRule(hObject,eventData,mode)
        if isempty(logData)
            return
        end
        try
            switch mode
                case 'tree'
                    ind=getSelectedTreeIndices(false);
                case 'list'
                    ind=getSelectedListIndices(false);
            end
            logs=regexprep(logInfo(ind,1),'^logData\.','');
            [temp,p]=unique(logs,'first');
            logs=logs(sort(p));
            newEntry=cell(numel(logs),4);
            try
                newEntry(:,1)=logs; %logs might be empty
            end
            switch prf.mode
                case 'struct'
                    showEditDialog('rules struct',newEntry)
                otherwise
                    showEditDialog('rules',newEntry)
            end
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onSelectionList
    function onSelectionList(hObject,eventData)
        getSelectedListIndices; %to track selection
    end
%
%
%% onSelectionTree
    function onSelectionTree(hObject,eventData)
        refreshList; %includes getSelectedTreeIndices
    end
%
%
%% onToolsRefreshLog
    function onToolsRefreshLog(hObject,eventData)
        refreshInterface;
    end
%
%
%% onToolsLockLog
    function onToolsLockLog(hObject,eventData)
        try
            if strcmp(get(hObject,'checked'),'off')
                prf.menuLockLog='on';
            else
                prf.menuLockLog='off';
            end
            refreshMenuTools;
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onToolsRefreshXpc
    function onToolsRefreshXpc(hObject,eventData)
        try
            if strcmp(prf.mode,'xpc') && ~isempty(logInfo)
                refreshWaitBar('Checking data...')
                xpcData.data=[];
                xpcData.time=[];
                % get a short data to check
                try
                    targetPc=xpc;
                    xpcData.data=getlog(targetPc,'OutputLog',1,1,1);
                catch
                    xpcData.data=[];
                end
                if size(xpcData.data,1)<1
                    xpcData.data=[];
                    refreshWaitBar;
                    showError('Check target computer!')
                    return
                end
                % check xpc before
                refreshWaitBar;
                check=isXpcDataOk(1);
                if ~check
                    return
                end
                % get all data
                refreshWaitBar('Loading data...')
                try
                    targetPc=xpc;
                    xpcData.data=getlog(targetPc,'OutputLog');
                    try
                        xpcData.time=getlog(targetPc,'TimeLog');
                    catch
                        xpcData.time=zeros(size(xpcData.data,1),1);
                    end
                    if isempty(xpcData.time) || sum(xpcData.time)==0
                        xpcData.time=[];
                    end
                catch
                    xpcData.data=[];
                    xpcData.time=[];
                end
                if size(xpcData.data,1)<1
                    xpcData.time=[];
                    xpcData.data=[];
                    showError('Check target computer!')
                    refreshWaitBar;
                    return
                end
                refreshWaitBar;
                % check xpc last time
                isXpcDataOk(1);
            else
                showError('Log is empty!');
                return
            end
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onToolsLoadData
    function onToolsLoadData(hObject,eventData)
        persistent path
        try
            if isempty(path) || ~ischar(path)
                path=[pwd '\'];
            end
            [file,pathSelected]=uigetfile([path '\plotlabLogs.mat'],'Load data');
            drawnow; pause(0.01);
            if ischar(file) && ischar(path)
                path=pathSelected;
                refreshWaitBar('Loading...')
                try
                    matFile=load('-mat',[path file]);
                catch
                    refreshWaitBar;
                    showError(['Unable to read ' file '!'])
                    return
                end
                matFileWhos=whos('matFile');
                if strcmp(matFileWhos.class,'struct') && numel(fieldnames(matFile))<=4
                    % xpc
                    fn=fieldnames(matFile);
                    xpcDataCell={};
                    logDataFound=0;
                    xpcDataFound=0;
                    for i=1:numel(fn)
                        sub=matFile.(fn{i});
                        subWhos=whos('sub');
                        if strcmp(subWhos.class,'Simulink.ModelDataLogs')
                            tempLogData=sub;
                            logDataFound=logDataFound+1;
                        elseif isnumeric(sub) && size(sub,1)>0
                            xpcDataCell{end+1}=sub;
                            xpcDataFound=xpcDataFound+1;
                        end
                    end
                    if logDataFound~=1
                        refreshWaitBar;
                        showError('Invalid data file!')
                        return
                    elseif xpcDataFound==0
                        assignin('base','logsout_loaded',tempLogData);
                        refreshInterface('logsout_loaded');
                        prf.mode='sim'; %force
                        refreshMenuModes;
                        refreshMenuTools;
                    else
                        if numel(xpcDataCell)==1
                            tempXpcData=xpcDataCell{1};
                            tempXpcTime=[];
                        else
                            if size(xpcDataCell{1},1)~=size(xpcDataCell{2},1) || ~(size(xpcDataCell{1},2)==1 || size(xpcDataCell{2},2)==1)
                                refreshWaitBar;
                                showError('Invalid data file!')
                                return
                            else
                                if size(xpcDataCell{2},2)==1
                                    tempXpcData=xpcDataCell{1};
                                    tempXpcTime=xpcDataCell{2};
                                else
                                    tempXpcData=xpcDataCell{2};
                                    tempXpcTime=xpcDataCell{1};
                                end
                            end
                        end
                        assignin('base','logsout_loaded',tempLogData);
                        refreshInterface('logsout_loaded');
                        xpcData.data=tempXpcData;
                        xpcData.time=tempXpcTime;
                        assignin('base','xpcData_loaded',tempXpcData);
                        assignin('base','xpcTime_loaded',tempXpcTime);
                        check=isXpcDataOk(0);
                        if check
                            prf.mode='xpc'; %force
                            refreshMenuModes;
                            refreshMenuTools;
                        else
                            %keep the mode same
                            xpcData.data=[];
                            xpcData.time=[];
                            refreshWaitBar;
                            showError('Invalid xPC data file!')
                            return
                        end
                    end
                else
                    % invalid file
                    refreshWaitBar;
                    showError('Invalid data file!')
                    return
                end
            end
        catch
            showError('Something went wrong!')
        end
        refreshWaitBar;
    end
%
%
%% onToolsSaveData
    function onToolsSaveData(hObject,eventData)
        persistent path
        try
            if isempty(path) || ~ischar(path)
                path=[pwd '\'];
            end
            if isempty(logData)
                return
            end
            [file,pathSelected]=uiputfile([path '\plotlabLogs.mat'],'Save mat file');
            drawnow; pause(0.01);
            if ischar(file) && ischar(path)
                path=pathSelected;
                refreshWaitBar('Saving...')
                temp.(prf.simLogBaseName)=logData;
                temp.logInfo=logInfo;
                if ~isempty(xpcData.data) && strcmp(prf.mode,'xpc')
                    temp.xpcData=xpcData.data0;
                    if ~isempty(xpcData.time)
                        temp.xpcTime=xpcData.time0;
                    end
                end
                save([path file],'-struct','temp');
            end
        catch
            showError('Something went wrong!')
        end
        refreshWaitBar;
    end
%
%
%% onToolsImportXpc
    function onToolsImportXpc(hObject,eventData)
        try
            if ~isempty(logInfo)
                xpcData.data=[];
                xpcData.time=[];
                % check xpc mode
                if ~strcmp(prf.mode,'xpc') || isempty(logInfo)
                    return
                end
                % get data
                vars=evalin('base','whos');
                varList={}; varInd=[];
                for i=1:length(vars)
                    varSize=vars(i).size;
                    if varSize(1)>0 && numel(varSize)==2
                        varList{end+1}=[vars(i).name '  (' num2str(vars(i).size(1)) 'x' num2str(vars(i).size(2)) ')'];
                        varInd(end+1)=i;
                    end
                end
                if isempty(varList)
                    return
                end
                while true
                    [ind,ok]=listdlg('PromptString','Select xPC data and time (optional)','SelectionMode','multiple','ListSize',[150,250],'liststring',varList);
                    drawnow; pause(0.01);
                    if ~ok
                        return
                    elseif numel(ind)==2 || numel(ind)==1
                        break
                    end
                end
                if numel(ind)==1
                    xpcData.data=evalin('base',vars(varInd(ind(1))).name);
                    xpcData.time=[];
                    isXpcDataOk(1);
                else
                    data1=evalin('base',vars(varInd(ind(1))).name);
                    data2=evalin('base',vars(varInd(ind(2))).name);
                    if size(data1,1)~=size(data2,1) || ~(size(data1,2)==1 || size(data2,2)==1)
                        showError('Data and time does not match!');
                        return
                    end
                    if size(data2,2)==1
                        xpcData.data=data1;
                        xpcData.time=data2;
                    else
                        xpcData.data=data2;
                        xpcData.time=data1;
                    end
                    isXpcDataOk(1);
                end
            else
                showError('Log is empty!');
                return
            end
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onToolsExportXpc
    function onToolsExportXpc(hObject,eventData)
        try
            if ~isempty(xpcData.data)
                if isempty(xpcData.time)
                    answer=inputdlg({'xPC data variable:'},'',1,{'xpcdata'});
                    if numel(answer)>0
                        if isvarname(answer{1})
                            assignin('base',answer{1},xpcData.data0)
                        else
                            showError('Invalid variable name!')
                        end
                    end
                else
                    answer=inputdlg({'xPC data variable:','xPC time variable:'},'',1,{'xpcData','xpcTime'});
                    if numel(answer)>0
                        if isvarname(answer{1}) && isvarname(answer{2})
                            assignin('base',answer{1},xpcData.data0)
                            assignin('base',answer{2},xpcData.time0)
                        else
                            showError('Invalid variable name!')
                        end
                    end
                end
            else
                showError('xPC data is empty!');
                return
            end
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onToolsPlotFolder
    function onToolsPlotFolder(hObject,eventData)
        persistent path
        try
            if isempty(path) || ~ischar(path)
                path=[pwd '\'];
            end
            prf0=getpref('plotlab','prf0');
            if ~isfield(prf0.persistent,'plotLinePropNames') || ~ischar(prf0.persistent.plotLinePropNames) || ~iscell(protectedEval(prf0.persistent.plotLinePropNames)) ...
                    || ~isfield(prf0.persistent,'plotLinePropVals') || ~ischar(prf0.persistent.plotLinePropVals) || ~iscell(protectedEval(prf0.persistent.plotLinePropVals)) ...
                    || ~isequal(size(protectedEval(prf0.persistent.plotLinePropNames)),size(protectedEval(prf0.persistent.plotLinePropVals)))
                prf0.persistent.plotLinePropNames='{''color'',''linewidth'',''marker''}';
                prf0.persistent.plotLinePropVals='{''b'',1,''none''}';
            end
            if ~isfield(prf0.persistent,'plotSave') || ~(isequal(prf0.persistent.plotSave,1) || isequal(prf0.persistent.plotSave,0))
                prf0.persistent.plotSave=1;
            end
            if ~isfield(prf0.persistent,'plotSamp') || isnan(str2double(prf0.persistent.plotSamp))
                prf0.persistent.plotSamp='1';
            end
            setpref('plotlab','prf0',prf0);
            %
            if isempty(logInfo)
                return
            elseif numel(gui.tree.getSelectionRows)~=1
                showError('Select saved signal from signal browser and try again!')
                return
            elseif isempty(getSelectedListIndices(false))
                showError('Select logs from list to plot!')
                return
            elseif ~isempty(prf.xAxis) && isempty(find(getSelectedTreeIndices==prf.xAxis,1))
                showError('X axis assignment must be within saved signal!')
                return
            end
            % dialog
            w=400; h=160; l=get(0,'PointerLocation'); pos=[l(1)-w/2 l(2)-h/2 w h];
            plotDialog=dialog('name','Preferences','windowbuttondownfcn','','buttondownfcn','','position',pos,'closerequestfcn','delete(gcbf);');
            uicontrol(plotDialog,'style','text','string','Directory','position',[10,130,350,20],'horizontalalignment','left');
            uicontrol(plotDialog,'style','edit','tag','dir','string',path,'position',[10,110,350,20],'horizontalalignment','left','backgroundcolor',[1,1,1],'callback',@onTextDir);
            uicontrol(plotDialog,'style','pushbutton','string','...','fontweight','bold','position',[370,110,20,20],'callback',@onButtonDir);
            uicontrol(plotDialog,'style','text','string','Line Property Names','position',[10,75,170,20],'horizontalalignment','left')
            uicontrol(plotDialog,'style','edit','string',prf0.persistent.plotLinePropNames,'position',[10,55,170,20],'callback',@onTextPropNames,'horizontalalignment','left','backgroundcolor',[1,1,1])
            uicontrol(plotDialog,'style','text','string','Line Property Values','position',[200,75,110,20],'horizontalalignment','left')
            uicontrol(plotDialog,'style','edit','string',prf0.persistent.plotLinePropVals,'position',[200,55,110,20],'callback',@onTextPropVals,'horizontalalignment','left','backgroundcolor',[1,1,1])
            uicontrol(plotDialog,'style','text','string','Sampling','position',[330,75,60,20],'horizontalalignment','left')
            uicontrol(plotDialog,'style','edit','string',prf0.persistent.plotSamp,'position',[330,55,60,20],'callback',@onTextSamp,'horizontalalignment','left','backgroundcolor',[1,1,1])
            uicontrol(plotDialog,'style','checkbox','string','Save figures','value',prf0.persistent.plotSave,'position',[10,15,120,20],'callback',@onCheckSave)
            uicontrol(plotDialog,'style','pushbutton','position',[240,15,70,20],'string','OK','callback',@onButtonOk);
            uicontrol(plotDialog,'style','pushbutton','position',[320,15,70,20],'string','Cancel','callback','delete(gcbf);');
            try
                movegui(plotDialog)
            end
            drawnow; pause(0.01);
        catch
            showError('Something went wrong!');
        end
        %
        %
        % subfuns
        function onButtonDir(hObject,eventData)
            dirName=uigetdir(path);
            drawnow; pause(0.001);
            if ischar(dirName) && isdir(dirName)
                hDir=findobj(plotDialog,'tag','dir');
                set(hDir,'string',dirName);
                path=dirName;
            end
        end
        %
        function onTextDir(hObject,eventData)
            dirName=get(hObject,'string');
            if ischar(dirName) && isdir(dirName)
                path=dirName;
            end
        end
        %
        function onTextSamp(hObject,eventData)
            prf0.persistent.plotSamp=get(hObject,'string');
            setpref('plotlab','prf0',prf0);
        end
        %
        function onCheckSave(hObject,eventData)
            prf0.persistent.plotSave=get(hObject,'value');
            setpref('plotlab','prf0',prf0);
        end
        %
        function onTextPropNames(hObject,eventData)
            prf0.persistent.plotLinePropNames=get(hObject,'string');
            setpref('plotlab','prf0',prf0);
        end
        %
        function onTextPropVals(hObject,eventData)
            prf0.persistent.plotLinePropVals=get(hObject,'string');
            setpref('plotlab','prf0',prf0);
        end
        %
        function onButtonOk(hObject,eventData)
            try
                delete(plotDialog);
                drawnow; pause(0.01);
                % properties
                propN=protectedEval(prf0.persistent.plotLinePropNames);
                propV=protectedEval(prf0.persistent.plotLinePropVals);
                samp=protectedEval(prf0.persistent.plotSamp);
                dirName=path;
                % checks
                treeSelections=getSelectedTreeIndices(false);
                listSelections=getSelectedListIndices(false);
                files=dir([dirName '\*.mat']);
                if isempty(files)
                    if isdir(dirName)
                        showError('No mat file in directory!')
                    else
                        showError('Directory is not found!')
                    end
                    return
                end
                try
                    hTempFig=figure('windowstyle','normal','visible','off'); grid on;
                    hTempAxes=get(hTempFig,'children');
                    hTempLine=plot(hTempAxes,0:10,0:10);
                    set(hTempLine,propN,propV)
                    delete(hTempFig)
                catch
                    showError('Invalid line property name or value!')
                    delete(hTempFig)
                    return
                end
                refreshWaitBar('Loading...');
                % x-axis
                if ~isempty(prf.xAxis)
                    xl=logInfo{prf.xAxis,3}{end};
                    if isempty(find(isstrprop(xl,'digit')==0,1)) && numel(logInfo{prf.xAxis,3})>1
                        xl=strtrim([logInfo{prf.xAxis,3}{end-1} '.' logInfo{prf.xAxis,3}{end}]);
                    end
                    try
                        unit=logInfo{prf.xAxis,5};
                        if ~isempty(unit)
                            xl=[xl ' [' unit ']'];
                        end
                    end
                else
                    xl=[];
                end
                try
                    xfactor=str2num(logInfo{prf.xAxis,6});
                    if numel(xfactor)~=1
                        xfactor=1;
                    end
                catch
                    xfactor=1;
                end
                % figures
                for j=1:numel(listSelections)
                    figName=logInfo{listSelections(j),3}{end};
                    if isempty(find(isstrprop(figName,'digit')==0,1)) && numel(logInfo{listSelections(j),3})>1
                        figName=strtrim([logInfo{listSelections(j),3}{end-1} '.' logInfo{listSelections(j),3}{end}]);
                    end
                    yl=figName;
                    try
                        unit=logInfo{listSelections(j),5};
                        if ~isempty(unit)
                            yl=[yl ' [' unit ']'];
                        end
                    end
                    try
                        factor(j)=str2num(logInfo{listSelections(j),6});
                    catch
                        factor(j)=1;
                    end
                    hFigs(j)=figure('name',figName,'numbertitle','off','windowstyle','docked','visible','off');
                    hold all; grid on;
                    hAxes(j)=get(hFigs(j),'children');
                    set(hAxes(j),'drawmode','fast')
                    xlabel(xl,'Interpreter','none');
                    ylabel(yl,'Interpreter','none');
                end
                drawnow;
                % check dimension
                j=0;
                signal='';
                for i=treeSelections
                    if all(logInfo{i,2}>0)
                        j=j+1;
                    else %extract bit
                        if ~strcmp(logInfo{i,1},signal)
                            j=j+1;
                        end
                    end
                    signal=logInfo{i,1};
                end
                dim=j;
                % load and plot
                for fn=1:numel(files)
                    try
                        dataLoad=load([dirName '\' files(fn).name]);
                    catch
                        refreshWaitBar;
                        showError(['Unable to read ' files(fn).name '!'])
                        return
                    end
                    vn=fieldnames(dataLoad);
                    if numel(vn)==1
                        data=dataLoad.(vn{1});
                    else
                        showError(['Invalid data in file "' files(fn).name '"!'])
                        break
                    end
                    check=0;
                    if size(data,2)==dim
                        check=1;
                        xdata=(1:size(data,1)).';
                    elseif size(data,1)==dim+1
                        check=1;
                        xdata=data(1,:).';
                        data=data(2:end,:).';
                    end
                    if size(data,2)~=numel(treeSelections)
                        [data,check]=getCompatibleData(data,treeSelections);
                    end
                    % check to continue
                    if ~check
                        showError(['Dimension of data in "' files(fn).name '" does not match with selected source signal!'])
                        if fn==1
                            close(hFigs)
                        else
                            break
                        end
                    end
                    % check x-axis assignment
                    if ~isempty(prf.xAxis)
                        ind=find(treeSelections==prf.xAxis,1,'first');
                        xdata=data(:,ind);
                    end
                    % plots
                    for j=1:numel(listSelections)
                        ind=find(treeSelections==listSelections(j),1,'first');
                        hLine=plot(hAxes(j),xdata(1:samp:end)*xfactor,data(1:samp:end,ind)*factor(j),'displayname',files(fn).name);
                        set(hLine,propN,propV)
                    end
                end
                try
                    set(hFigs,'visible','on')
                    if prf0.persistent.plotSave
                        if ~isdir([dirName '\figures']);
                            mkdir(dirName,'figures');
                        end
                        for j=1:numel(listSelections)
                            for k=1:100
                                if ~exist([dirName '\figures\' num2str(k) '.fig'],'file')
                                    break
                                end
                            end
                            saveas(hFigs(j),[dirName '\figures\' num2str(k) '.fig'])
                        end
                    end
                catch
                    showError('Save failed!')
                end
            catch
                showError('Something went wrong!')
            end
            refreshWaitBar;
        end
    end
%
%
%% onToolsEditConverters
    function onToolsEditConverters(hObject,eventData)
        try
            showEditDialog('converters');
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onToolsEditRules
    function onToolsEditRules(hObject,eventData)
        try
            showEditDialog('rules');
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onToolsEditPlotProps
    function onToolsEditPlotProps(hObject,eventData)
        try
            showEditDialog('plot properties');
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onToolsSavePrf
    function onToolsSavePrf(hObject,eventData)
        try
            [file,path]=uiputfile([prf.pwd '\plotlabPrf.mat'],'Save preferences');
            drawnow; pause(0.01);
            if ischar(file) && ischar(path)
                save([path file],'prf')
            end
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onToolsLoadPrf
    function onToolsLoadPrf(hObject,eventData)
        [file,path]=uigetfile([prf.pwd '\plotlabPrf.mat'],'Load preferences');
        drawnow; pause(0.01);
        if ischar(file) && ischar(path)
            try
                tempPrf=importdata([path file]);
                if  ~isstruct(tempPrf) ...
                        || ~isfield(tempPrf,'treeExpandPaths') || ~iscell(tempPrf.treeExpandPaths) ...
                        || ~(size(tempPrf.treeExpandPaths,1)==1 || size(tempPrf.treeExpandPaths,1)==0)...
                        || ~isfield(tempPrf,'treeSelections') || ~iscell(tempPrf.treeSelections) ...
                        || ~(size(tempPrf.treeSelections,1)==1 || size(tempPrf.treeSelections,1)==0)
                    showError('Invalid preferences file!')
                else
                    for i=1:numel(prf.unprotectedFields)
                        try
                            prf.(prf.unprotectedFields{i})=tempPrf.(prf.unprotectedFields{i});
                        end
                    end
                    % refresh menus
                    refreshMenuFigure;
                    refreshMenuTools;
                    refreshMenuModes;
                    % rules are updated, refresh interface if either sim or xpc mode is active
                    switch prf.mode
                        case 'struct'
                            % no need
                        otherwise %force to "case 'sim' or 'xpc"
                            try
                                assignin('base',prf.simLogBaseName,logData);
                                refreshInterface(prf.simLogBaseName); %force to use the same log
                            end
                    end
                    % save (do not wait closing!)
                    setPrf;
                end
            catch
                showError('Something went wrong!')
            end
        end
    end
%
%
%% onToolsShowLog
    function onToolsShowLog(hObject,eventData)
        try
            if strcmp(get(hObject,'checked'),'off')
                prf.menuShowLog='on';
            else
                prf.menuShowLog='off';
            end
            refreshMenuTools;
            if ~isempty(prf.listInd)
                refreshList;
            end
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onToolsShowOrder
    function onToolsShowOrder(hObject,eventData)
        try
            if strcmp(get(hObject,'checked'),'off')
                prf.menuShowOrder='on';
            else
                prf.menuShowOrder='off';
            end
            refreshMenuTools;
            if ~isempty(prf.listInd)
                refreshList;
            end
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onToolsModifyBusSelector
    function onToolsModifyBusSelector(hObject,eventData)
        try
            busSelectorSelected=0;
            try
                if strcmp(get_param(gcb,'BlockType'),'BusSelector')
                    signalNames=get_param(gcb,'OutputSignals');
                    signals=strtrim(regexp([', ' signalNames ' ,'],'(?<=\,)[^\,]+(?=\,)','match'));
                    busSelectorSelected=1;
                end
                %
                try
                    signalsBackup=signals;
                    inputCell=get_param(gcb,'InputSignals');
                    inputSignals=cell(numel(inputCell),2);
                    for i=1:size(inputCell)
                        if iscell(inputCell{i})
                            inputSignals{i,1}=inputCell{i}{1};
                            inputSignals{i,2}=inputCell{i}{2};
                        else
                            inputSignals{i,1}=inputCell{i};
                            inputSignals{i,2}=[];
                        end
                    end
                    %
                    i=1;
                    while true
                        if ~isempty(inputSignals{i,2})
                            base=inputSignals{i,1};
                            n=numel(inputSignals{i,2});
                            newSignals=cell(n,2);
                            for j=1:n
                                sub=inputSignals{i,2}{j};
                                if iscell(sub)
                                    newSignals{j,1}=[base '.' sub{1}];
                                    newSignals{j,2}=sub{2};
                                else
                                    newSignals{j,1}=[base '.' sub];
                                    newSignals{j,2}=[];
                                end
                            end
                            inputSignals=[inputSignals(1:i-1,:); newSignals; inputSignals(i+1:end,:)];
                        else
                            i=i+1;
                        end
                        if i>size(inputSignals,1)
                            break
                        end
                    end
                    inputSignals(:,2)=[];
                    %
                    sortArray=zeros(size(signals));
                    for i=1:numel(signals)
                        j=strcmpi(signals{i},inputSignals);
                        if sum(j)==0 % check if selected signal is bus and has only one signal
                            j=strncmpi([signals{i} '.'],inputSignals,numel(signals{i})+1);
                        end
                        if sum(j)==0
                            disp(['"' signals{i} '" is not found on bus?'])
                        else
                            j=find(j);
                            sortArray(i)=j(1);
                            if numel(j)>1
                                for n=2:numel(j)
                                    sortArray(end+1)=j(n);
                                end
                            end
                        end
                    end
                    if any(sortArray==0)
                        disp(' ')
                        disp('bus selections are not supported!')
                        return
                    end
                    sortArray=sort(sortArray);
                    signals=inputSignals(sortArray);
                catch
                    signals=signalsBackup;
                end
            end
            %
            if ~busSelectorSelected
                input=gui.optionPane.showOptionDialog(gui.jFrame,...
                    ['Bus selector block is not selected.' sprintf('\n') 'Continue from PlotLab log list?']...
                    ,'',0,3,[],{'Yes','No'},{'Yes'});
                drawnow; pause(0.01);
                if input~=0
                    return
                else
                    if numel(gui.tree.getSelectionRows)~=1
                        showError('Select bus signal from signal browser!')
                        return
                    elseif isempty(getSelectedListIndices(false))
                        showError('Select signals from list!')
                        return
                    else
                        try
                            treeSelections=getSelectedTreeIndices(false);
                            listSelections=getSelectedListIndices(false);
                            for i=1:1000
                                busSignals=logInfo(treeSelections,1);
                                if numel(unique(cellfun(@(x) (x(i)),busSignals,'UniformOutput',false)))>1
                                    break
                                end
                            end
                            dotInd=strfind(busSignals{i}(1:i-1),'.');
                            dotInd=dotInd(end);
                            signals=cell(numel(listSelections),1);
                            for i=1:numel(listSelections)
                                signals{i}=logInfo{listSelections(i),1}(dotInd+1:end);
                            end
                            [x,p]=unique(signals,'first');
                            signals=signals(sort(p));
                        catch
                            showError('Something went wrong!')
                            return
                        end
                        %
                        % try
                        %     signalsBackup=signals;
                        %     j=1;
                        %     i=numel(signals);
                        %     while true
                        %         if j<numel(signals{i})
                        %             k=find(strcmpi(signals{i}(1:j),cellfun(@(x) x(1:min(j,numel(x))),signals(1:i-1),'UniformOutput',0))==1,1,'last');
                        %         else
                        %             k=[];
                        %         end
                        %         if isempty(k) || (i-1)==k
                        %             i=i-1;
                        %         else
                        %             signals=signals([1:k,i,k+1:i-1,i+1:end]);
                        %         end
                        %         if i==2
                        %             i=numel(signals);
                        %             j=j+1;
                        %         end
                        %         if all(j>cellfun(@(x) numel(x),signals))
                        %             break
                        %         end
                        %     end
                        % catch
                        %     signals=signalsBackup;
                        % end
                        %
                    end
                end
            end
            %
            %load block
            %
            try
                refreshWaitBar('Loading model...')
                %
                load_simulink
                load_system('simulink'); load_system('xpclib'); load_system('xpcutilitieslib')
                root='tempBusMdl';
                bdclose(root)
                new_system(root); open_system(root)
                %
                try
                    add_block('built-in/SubSystem',[root '/bus'],'Position',[30 15 30+50 15+30],'UserData',0);
                    add_block('Simulink/Sources/In1',[root '/bus/ '],'Position',[15 23 45 37]);
                    add_block('Simulink/Sinks/Out1',[root '/bus/  '],'Position',[360 23 390 37]);
                catch
                    error('open simulink library browser and try again')
                end
                for i=1:numel(signals)
                    labels=strtrim(regexp(['. ' signals{i} ' .'],'(?<=\.)[^\.]+(?=\.)','match'));
                    for j=1:numel(labels)
                        base=[root '/bus'];
                        for k=1:j-1
                            base=[base '/' labels{k}];
                        end
                        hb=find_system(base,'SearchDepth',1,'BlockType','SubSystem','Name',labels{j});
                        if isempty(hb) || (numel(hb)==1 && strcmp(hb{1},base))
                            no=get_param(base,'UserData');
                            add_block('built-in/SubSystem',[base '/' labels{j}],'Position',[100 50*no+15 100+50 50*no+15+30],'ShowName','off');
                            add_block('Simulink/Sources/In1',[base '/' labels{j} '/ '],'Position',[15 23 45 37]);
                            add_block('Simulink/Sinks/Out1',[base '/' labels{j} '/  '],'Position',[360 23 390 37]);
                            if j==numel(labels)
                                add_block('Simulink/Signal Routing/Bus Selector',[base '/' labels{j} '/selector'],'Position',[80 15 80+5 15+30],'OutputSignals',signals{i},'ShowName','off');
                                add_line([base '/' labels{j}],' /1','selector/1','autorouting','on');
                                add_block('Simulink/Math Operations/Reshape',[base '/' labels{j} '/reshape'],'Position',[240 20 240+30 40],'ShowName','off');
                                add_line([base '/' labels{j}],'selector/1','reshape/1','autorouting','on');
                                add_block('Simulink/Signal Attributes/Data Type Conversion',[base '/' labels{j} '/conversion'],'Position',[300 20 300+30 40],'ShowName','off','OutDataTypeStr','double');
                                add_line([base '/' labels{j}],'reshape/1','conversion/1','autorouting','on');
                                add_line([base '/' labels{j}],'conversion/1','  /1','autorouting','on');
                            end
                            add_line(base,' /1',[labels{j} '/1'],'autorouting','on');
                            if no==0
                                add_block('Simulink/Signal Routing/Bus Creator',[base '/buscreator'],'Position',[300 15 300+5 15+30],'Inputs','1');
                                hl=add_line(base,[labels{j} '/1'],'buscreator/1','autorouting','on');
                                set_param(hl,'Name',labels{j})
                                add_line(base,'buscreator/1','  /1','autorouting','on');
                            else
                                set_param([base '/buscreator'],'Position',[300 20 300+5 20+15*(no+1)],'Inputs',num2str(no+1))
                                hl=add_line(base,[labels{j} '/1'],['buscreator/' num2str(no+1)],'autorouting','on');
                                set_param(hl,'Name',labels{j})
                            end
                            set_param(base,'UserData',no+1)
                            set_param([base '/' labels{j}],'UserData',0)
                        end
                    end
                end
                base=[root '/bus'];
                no=get_param(base,'UserData');
                signalNames='';
                for i=1:numel(signals)
                    signalNames=[signalNames signals{i} ','];
                end
                try
                    signalNames(end)=[];
                end
                add_block('Simulink/Signal Routing/Bus Selector',[base '/selector'],'Position',[100 50*no+15 100+5 50*no+15+30],'OutputSignals',signalNames,'ShowName','off','OutputAsBus','on');
                add_block('Simulink/Sinks/Terminator',[base '/terminator'],'Position',[150 50*no+15+5 150+20 50*no+15+30-5],'ShowName','off');
                add_line(base,' /1','selector/1','autorouting','on');
                add_line(base,'selector/1','terminator/1','autorouting','on');
            catch
                showError('Something went wrong!')
            end
            refreshWaitBar;
        end
    end
%
%
%% onToolsRearrangeBlocks
    function onToolsRearrangeBlocks(hObject,eventData)
        try
            refreshWaitBar('Checking current model...');
            try
                if ~strcmp(get(get_param(bdroot,'handle'),'Shown'),'on')
                    refreshWaitBar;
                    showError('Unable to find model!')
                    return
                end
                %
                hl=find_system(bdroot,'FindAll','on','Type','Line','Connected','off');
                if ~isempty(hl)
                    disp(' ')
                    disp('unconnected lines in:')
                    disp(get(hl,'parent'))
                    disp(' ')
                end
                hp=find_system(bdroot,'FindAll','on','Type','port','Line',-1);
                if ~isempty(hp)
                    disp(' ')
                    disp('unconnected ports in:')
                    disp(get(hp,'parent'))
                    disp(' ')
                end
                %
                %
                namemissmatch=0;
                blocks=find_system(bdroot,'FindAll','on','BlockType','SubSystem');
                for i=1:numel(blocks)
                    subsystem=blocks(i);
                    inports=find_system(subsystem,'SearchDepth',1,'FindAll','on','BlockType','Inport');
                    inports=get(inports,'name');
                    if ischar(inports)
                        inports={inports};
                    end
                    signals=get(subsystem,'InputSignalNames');
                    signals=regexprep(signals,'^<','');
                    signals=regexprep(signals,'>$','');
                    for j=1:numel(inports)
                        if ~isempty(signals{j})
                            if ~isempty(strtrim(inports{j})) && ~strcmp(signals{j},strtrim(inports{j}))
                                disp(['name mismatch: ' get(subsystem,'path') '/' get(subsystem,'name') '  >>  .' signals{j} '.  .' inports{j} '.'])
                                namemissmatch=1;
                            end
                        end
                    end
                    %
                    outports=find_system(subsystem,'SearchDepth',1,'FindAll','on','BlockType','Outport');
                    outports=get(outports,'name');
                    if ischar(outports)
                        outports={outports};
                    end
                    signals=get(subsystem,'OutputSignalNames');
                    for j=1:numel(outports)
                        if ~isempty(signals{j})
                            if ~isempty(strtrim(outports{j})) && ~strcmp(signals{j},strtrim(outports{j}))
                                disp(['name mismatch: ' get(subsystem,'path') '/' get(subsystem,'name') '  >>  .' signals{j} '.  .' outports{j} '.'])
                                namemissmatch=1;
                            end
                        end
                    end
                end
            catch
                refreshWaitBar;
                showError('Unable to find model!')
                return
            end
            %
            %
            refreshWaitBar('Saving new model...');
            %
            %
            try
                model=save_system(bdroot,regexprep(which(bdroot),'\.mdl$','_temp\.mdl'),'ErrorIfShadowed',1);
                close_system(model);
                load_system(model);
            catch
                refreshWaitBar;
                showError(['Unable to make a copy.\nTry to delete "' bdroot '_temp.mdl".'])
                return
            end
            %
            %
            refreshWaitBar('Rearranging blocks...');
            %
            %
            blocks=find_system(bdroot,'FindAll','on','BlockType','SubSystem');
            blocks=[get_param(bdroot,'handle'); reshape(blocks,[],1)];
            block_check=blocks*0;
            block_names=cell(size(block_check));
            for i=1:numel(block_check)
                block_names{i}=[get(blocks(i),'path') '/' strrep(get(blocks(i),'name'),'/','//')];
            end
            %
            for i=1:numel(blocks)
                try
                    hl=find_system(blocks(i),'SearchDepth',1,'FindAll','on','Type','Line','Connected','off');
                    hp=find_system(blocks(i),'SearchDepth',1,'FindAll','on','Type','port','Line',-1);
                    if not(isempty(hl) && isempty(hp))
                        disp(['unconnected line in: ' get(blocks(i),'path') '/' get(blocks(i),'name')])
                        continue
                    end
                    subblocks=get(blocks(i),'blocks');
                    lines=find_system(blocks(i),'SearchDepth',1,'FindAll','on','Type','Line','LineChildren',[]);
                    checkCell={'InportBusSelector','InportTerminator','BusSelectorSubSystem','SubSystemBusCreator','BusCreatorOutport','InportSubSystem','BusCreatorSubSystem','SubSystemOutport','BusSelectorBusCreator','InportBusCreator'};
                    checkArray=zeros(size(checkCell));
                    for j=1:numel(lines)
                        SrcBlock=get(lines(j),'SrcBlockHandle');
                        DstBlock=get(lines(j),'DstBlockHandle');
                        line_route=[get(SrcBlock,'blocktype') get(DstBlock,'blocktype')];
                        checkArray=checkArray+strcmp(checkCell,line_route);
                    end
                    %
                    inport=find_system(blocks(i),'SearchDepth',1,'FindAll','on','BlockType','Inport');
                    outport=find_system(blocks(i),'SearchDepth',1,'FindAll','on','BlockType','Outport');
                    subsystem=find_system(blocks(i),'SearchDepth',1,'FindAll','on','BlockType','SubSystem');
                    try
                        subsystem(1)=[];
                        subsystem_lines=get(subsystem(1),'LineHandles');
                    catch
                        subsystem_lines=[];
                    end
                    try
                        busselector_enable=get(subsystem_lines.Enable,'SrcBlockHandle');
                    catch
                        busselector_enable=[];
                    end
                    try
                        busselector_inport=get(subsystem_lines.Inport(1),'SrcBlockHandle');
                    catch
                        busselector_inport=[];
                    end
                    terminator=find_system(blocks(i),'SearchDepth',1,'FindAll','on','BlockType','Terminator');
                    buscreator=find_system(blocks(i),'SearchDepth',1,'FindAll','on','BlockType','BusCreator');
                    %
                    if checkArray(5)==1 && checkArray(4)>0 && numel(buscreator)==1 && numel(inport)==1 && numel(outport)==1 && numel(subsystem)==1 && checkArray(9)==0 ...
                            && ((checkArray(1)==2 && checkArray(2)==0 && checkArray(3)>1 && numel(busselector_enable)==1 && numel(busselector_inport)==1 && numel(subblocks)==6) ... %with enable
                            || (checkArray(1)==1 && checkArray(2)==0 && checkArray(3)>0 && isempty(busselector_enable) && numel(busselector_inport)==1 && numel(subblocks)==5) ... %without enable
                            || (checkArray(1)==1 && checkArray(2)==1 && checkArray(3)==1 && isempty(busselector_inport) && numel(busselector_enable)==1 && numel(subblocks)==6) ... %enable with no input
                            || (checkArray(1)==0 && checkArray(2)==1 && checkArray(3)==0 && isempty(busselector_inport) && isempty(busselector_enable) && numel(subblocks)==5)) %no input
                        block_check(strncmpi(block_names,block_names{i},numel(block_names{i})))=-1;
                        block_check(i)=2;                        
                        subsystem_inports=find_system(subsystem,'SearchDepth',1,'FindAll','on','BlockType','Inport');
                        subsystem_outports=find_system(subsystem,'SearchDepth',1,'FindAll','on','BlockType','Outport');
                        delete_line(lines);
                        n=max(1,max(numel(subsystem_inports),numel(subsystem_outports))-1);
                        w=150; h=20; b0=20;
                        if ~isempty(busselector_enable)
                            set(busselector_enable,'Position',[90 20 95 50],'ShowName','off');
                            b0=60;
                        end
                        set(subsystem,'Position',[95+w b0 95+w*2.5 b0+n*h+30],'ShowName','off');
                        set(buscreator,'Position',[95+w*3.5 b0 100+w*3.5 b0+n*h+30],'ShowName','off');
                        p=get(buscreator,'Position'); p=ceil(p(2)+(p(4)-p(2))/2);
                        set(outport,'Position',[140+w*3.5 p-7 140+w*3.5+30 p+7],'ShowName','on');
                        if ~isempty(busselector_inport)
                            set(busselector_inport,'Position',[90 b0 95 b0+n*h+30],'ShowName','off');
                            p=get(busselector_inport,'Position'); p=ceil(p(2)+(p(4)-p(2))/2);
                            set(inport,'Position',[20 p-7 50 p+7],'ShowName','on');
                        end
                        if ~isempty(terminator)
                            set(terminator,'Position',[90 b0+n*h/2+15-10 110 b0+n*h/2+15+10],'ShowName','off');
                            set(inport,'Position',[20 b0+n*h/2+15-7 50 b0+n*h/2+15+7],'ShowName','on');
                        end
                        blankName(inport,1);
                        blankName(outport,2);
                        blankName(subsystem,3);
                        for j=1:numel(subsystem_outports)
                            hl=add_line(get(inport,'path'),[strrep(get(subsystem,'name'),'/','//') '/' num2str(j)],[strrep(get(buscreator,'name'),'/','//') '/'  num2str(j)],'autorouting','off');
                            set(hl,'Tag','buscreator');
                        end
                        add_line(get(inport,'path'),[strrep(get(buscreator,'name'),'/','//') '/1'],[strrep(get(outport,'name'),'/','//') '/1'],'autorouting','off');
                        if isempty(terminator)
                            for j=1:numel(subsystem_inports)
                                add_line(get(inport,'path'),[strrep(get(busselector_inport,'name'),'/','//') '/' num2str(j)],[strrep(get(subsystem,'name'),'/','//') '/'  num2str(j)],'autorouting','off');
                            end
                            hl=add_line(get(inport,'path'),[strrep(get(inport,'name'),'/','//') '/1'],[strrep(get(busselector_inport,'name'),'/','//') '/1'],'autorouting','off');
                        else
                            hl=add_line(get(inport,'path'),[strrep(get(inport,'name'),'/','//') '/1'],[strrep(get(terminator,'name'),'/','//') '/1'],'autorouting','off');
                        end
                        for j=1:4
                            l=get(blocks(i),'lines');
                            if sum(unique(cellfun('length',{l.Points})))==2
                                break
                            end
                            [m,mind]=max(cellfun('length',{l.Points}));
                            p=l(mind).Points; p=p(end,2)-p(1,2);
                            SrcBlock=l(mind).SrcBlock;
                            DstBlock=l(mind).DstBlock;
                            if strcmp(get(SrcBlock,'blocktype'),'SubSystem') || strcmp(get(DstBlock,'blocktype'),'Outport')
                                p0=get(DstBlock,'position');
                                set(DstBlock,'position',p0+[0 -p 0 -p])
                            else
                                p0=get(SrcBlock,'position');
                                set(SrcBlock,'position',p0+[0 p 0 p])
                            end
                            if j==4
                                disp(['broken line  >>  ' get(blocks(i),'path') '/' get(blocks(i),'name')])
                            end
                        end
                        %
                        if ~isempty(busselector_enable)
                            p=get(hl,'points');
                            p=[65 p(1,2); 65 35; 90 35];
                            add_line(get(inport,'path'),p);
                            add_line(get(inport,'path'),[strrep(get(busselector_enable,'name'),'/','//') '/1'],[strrep(get(subsystem,'name'),'/','//') '/Enable'],'autorouting','on');
                        end
                        %checkCell={'InportBusSelector','InportTerminator','BusSelectorSubSystem','SubSystemBusCreator','BusCreatorOutport','InportSubSystem','BusCreatorSubSystem','SubSystemOutport','BusSelectorBusCreator','InportBusCreator'};
                    elseif checkArray(5)==1 && checkArray(4)>0 && checkArray(6)==checkArray(4) && numel(buscreator)==1 && numel(inport)==1 && numel(outport)==1 && (checkArray(4)+3)==numel(subblocks)
                        block_check(i)=1;
                        pVec=[];
                        for j=1:numel(subsystem)
                            p=get(subsystem(j),'position');
                            pVec(j)=p(2);
                        end
                        [p,pInd]=sort(pVec);
                        subsystem=subsystem(pInd);
                        %
                        delete_line(lines);
                        set(inport,'Position',[20 33 50 47],'ShowName','on');
                        set(outport,'Position',[360+(numel(subsystem)-1)*20 40+(numel(subsystem)-1)*20/2-7 390+(numel(subsystem)-1)*20 40+(numel(subsystem)-1)*20/2+7],'ShowName','on');
                        blankName(inport,1);
                        blankName(outport,2);
                        if numel(subsystem)==1
                            set(buscreator,'Position',[325 20 330 60],'ShowName','off');
                        else
                            set(buscreator,'Position',[325+(numel(subsystem)-1)*20 40-20/2 330+(numel(subsystem)-1)*20 40+20/2+(numel(subsystem)-1)*20],'ShowName','off');
                        end
                        for j=1:numel(subsystem)
                            set(subsystem(j),'Position',[90 20+(j-1)*70 230 60+(j-1)*70],'ShowName','on');
                        end
                        add_line(get(inport,'path'),[strrep(get(buscreator,'name'),'/','//') '/1'],[strrep(get(outport,'name'),'/','//') '/1'],'autorouting','off');
                        for j=1:numel(subsystem)
                            if j==1
                                hl1=add_line(get(inport,'path'),[strrep(get(inport,'name'),'/','//') '/1'],[strrep(get(subsystem(j),'name'),'/','//') '/1'],'autorouting','on');
                                hl2=add_line(get(inport,'path'),[strrep(get(subsystem(j),'name'),'/','//') '/1'],[strrep(get(buscreator,'name'),'/','//') '/' num2str(j)],'autorouting','on');
                            else
                                hl1=add_line(get(inport,'path'),[65 40+(j-2)*70; 65 40+(j-1)*70; 85 40+(j-1)*70]);
                                hl2=add_line(get(inport,'path'),[235 40+(j-1)*70; 230+(j-1)*20 40+(j-1)*70; 230+(j-1)*20 20+20*j; 320+(numel(subsystem)-1)*20 20+20*j]);
                            end
                            set(hl2,'Tag','buscreator');
                            if ~strcmp([get(hl1,'Connected'),get(hl2,'Connected')],'onon')
                                refreshWaitBar;
                                showError(['Line connection error in:\n' get(blocks(i),'path') '/' get(blocks(i),'name')])
                                return
                            end
                        end
                    elseif i==1 && checkArray(4)>0 && (checkArray(7)-1)==checkArray(4) && checkArray(8)==1 && numel(buscreator)==1 && numel(outport)==1 && numel(inport)==0 && (checkArray(4)+3)==numel(subblocks)
                        block_check(i)=1;
                        buscreator_lines=get(buscreator,'LineHandles');
                        hl0_name=get(buscreator_lines.Outport,'name');
                        set(buscreator_lines.Outport,'name','');
                        try
                            subsystem=cell2mat(get(buscreator_lines.Inport,'SrcBlockHandle'));
                        catch
                            subsystem=get(buscreator_lines.Inport,'SrcBlockHandle');
                        end
                        outport_lines=get(outport,'LineHandles');
                        subsystem_out=get(outport_lines.Inport,'SrcBlockHandle');
                        %
                        pVec=[];
                        for j=1:numel(subsystem)
                            p=get(subsystem(j),'position');
                            pVec(j)=p(2);
                        end
                        [p,pInd]=sort(pVec);
                        subsystem=subsystem(pInd);
                        %
                        delete_line(lines);
                        set(subsystem_out,'Position',[330-40+(numel(subsystem)-1)*20+40 40+(numel(subsystem)-1)*20/2-15 330-40+(numel(subsystem)-1)*20+40+30 40+(numel(subsystem)-1)*20/2+15],'ShowName','off');
                        name=[get(subsystem_out,'path') '/' strrep(get(subsystem_out,'name'),'/','//')];
                        block_check(strncmpi(block_names,name,numel(name)))=-1;
                        try
                            set(find_system(subsystem_out,'SearchDepth',1,'FindAll','on','BlockType','Inport'),'name','   ');
                            set(find_system(subsystem_out,'SearchDepth',1,'FindAll','on','BlockType','Outport'),'name','  ');
                        end
                        set(outport,'Position',[330-40+(numel(subsystem)-1)*20+40+30+30 40+(numel(subsystem)-1)*20/2-7 330-40+(numel(subsystem)-1)*20+40+30+30+30 40+(numel(subsystem)-1)*20/2+7],'ShowName','off');
                        if numel(subsystem)==1
                            set(buscreator,'Position',[325-40 20 330-40 60],'ShowName','off');
                        else
                            set(buscreator,'Position',[325-40+(numel(subsystem)-1)*20 40-20/2 330-40+(numel(subsystem)-1)*20 40+20/2+(numel(subsystem)-1)*20],'ShowName','off');
                        end
                        for j=1:numel(subsystem)
                            set(subsystem(j),'Position',[90-40 20+(j-1)*70 230-40 60+(j-1)*70],'ShowName','on');
                        end
                        hl0=add_line(get(outport,'path'),[strrep(get(buscreator,'name'),'/','//') '/1'],[strrep(get(subsystem_out,'name'),'/','//') '/1'],'autorouting','off');
                        add_line(get(outport,'path'),[strrep(get(subsystem_out,'name'),'/','//') '/1'],[strrep(get(outport,'name'),'/','//') '/1'],'autorouting','off');
                        for j=1:numel(subsystem)
                            if j==1
                                hl1=add_line(get(outport,'path'),[330-40+(numel(subsystem)-1)*20+15 40+(numel(subsystem)-1)*20/2; 330-40+(numel(subsystem)-1)*20+15 20+numel(subsystem)*70; ...
                                    (90-40-25) 20+numel(subsystem)*70; (90-40-25) 40+(j-1)*70; 90-40 40+(j-1)*70]);
                                hl2=add_line(get(outport,'path'),[strrep(get(subsystem(j),'name'),'/','//') '/1'],[strrep(get(buscreator,'name'),'/','//') '/' num2str(j)],'autorouting','on');
                            else
                                hl1=add_line(get(outport,'path'),[(90-40-25) 40+(j-1)*70; 90-40 40+(j-1)*70]);
                                hl2=add_line(get(outport,'path'),[235-40 40+(j-1)*70; 230-40+(j-1)*20 40+(j-1)*70; 230-40+(j-1)*20 20+20*j; 325-40+(numel(subsystem)-1)*20 20+20*j]);
                            end
                            set(hl2,'Tag','buscreator');
                            if ~strcmp([get(hl1,'Connected'),get(hl2,'Connected')],'onon')
                                refreshWaitBar;
                                showError(['Line connection error in:\n' get(blocks(i),'path') '/' get(blocks(i),'name')])
                                return
                            end
                        end
                        buscreator_lines=get(buscreator,'LineHandles');
                        set(buscreator_lines.Outport,'name',hl0_name,'tag','buscreator');
                        %checkCell={'InportBusSelector','InportTerminator','BusSelectorSubSystem','SubSystemBusCreator','BusCreatorOutport','InportSubSystem','BusCreatorSubSystem','SubSystemOutport','BusSelectorBusCreator','InportBusCreator'};
                    elseif checkArray(4)>0 && checkArray(7)==checkArray(4) && checkArray(5)==1 && numel(buscreator)==1 && numel(outport)==1 && numel(inport)==1 ...
                            && checkArray(10)==1 && (checkArray(4)+3)==numel(subblocks) && checkArray(4)==numel(subsystem)
                        block_check(i)=12;
                        buscreator_lines=get(buscreator,'LineHandles');
                        hl0_name=get(buscreator_lines.Outport,'name');
                        set(buscreator_lines.Outport,'name','');
                        %
                        pVec=[];
                        for j=1:numel(subsystem)
                            p=get(subsystem(j),'position');
                            pVec(j)=p(2);
                        end
                        [p,pInd]=sort(pVec);
                        subsystem=subsystem(pInd);
                        %
                        delete_line(lines);
                        set(inport,'Position',[210 23 240 37],'ShowName','on');
                        set(outport,'Position',[330-40+(numel(subsystem)-1)*20+40+30+30 50-20/2+(numel(subsystem)-1)*20/2-7 330-40+(numel(subsystem)-1)*20+40+30+30+30 50-20/2+(numel(subsystem)-1)*20/2+7],'ShowName','on');
                        blankName(inport,1);
                        blankName(outport,2);
                        set(buscreator,'Position',[325-40+(numel(subsystem)-1)*20+30+30 50-20/2-20 330-40+(numel(subsystem)-1)*20+30+30 50+20/2+(numel(subsystem)-1)*20],'ShowName','off');
                        hl0=add_line(get(outport,'path'),[strrep(get(buscreator,'name'),'/','//') '/1'],[strrep(get(outport,'name'),'/','//') '/1'],'autorouting','off');
                        for j=1:numel(subsystem)
                            set(subsystem(j),'Position',[90-40 30+(j-1)*70 230-40 70+(j-1)*70],'ShowName','on');
                        end
                        add_line(get(outport,'path'),[strrep(get(inport,'name'),'/','//') '/1'],[strrep(get(buscreator,'name'),'/','//') '/1'],'autorouting','on');
                        for j=1:numel(subsystem)
                            if j==1
                                hl1=add_line(get(outport,'path'),[330-40+(numel(subsystem)-1)*20+30+30+15 50-20/2+(numel(subsystem)-1)*20/2; ...
                                    330-40+(numel(subsystem)-1)*20+30+30+15 30+numel(subsystem)*70; (90-40-25) 30+numel(subsystem)*70; (90-40-25) 50+(j-1)*70; 90-40 50+(j-1)*70]);
                                hl2=add_line(get(outport,'path'),[strrep(get(subsystem(j),'name'),'/','//') '/1'],[strrep(get(buscreator,'name'),'/','//') '/' num2str(j+1)],'autorouting','on');
                            else
                                hl1=add_line(get(outport,'path'),[(90-40-25) 50+(j-1)*70; 90-40 50+(j-1)*70]);
                                hl2=add_line(get(outport,'path'),[235-40 50+(j-1)*70; 230-40+(j-1)*20 50+(j-1)*70; 230-40+(j-1)*20 50+20*(j-1); 325-40+(numel(subsystem)-1)*20+30+30 50+20*(j-1)]);
                            end
                            if ~strcmp([get(hl1,'Connected'),get(hl2,'Connected')],'onon')
                                refreshWaitBar;
                                showError(['Line connection error in:\n' get(blocks(i),'path') '/' get(blocks(i),'name')])
                                return
                            end
                        end
                        buscreator_lines=get(buscreator,'LineHandles');
                        set(buscreator_lines.Outport,'name',hl0_name,'tag','buscreator');
                        set(buscreator_lines.Inport,'tag','buscreator');
                    end
                catch
                    refreshWaitBar;
                    try
                        showError(['Unknown error in:\n' get(blocks(i),'path') '/' get(blocks(i),'name')])
                    catch
                        showError('Unknown error during block manipulation.')
                    end
                    return
                end
            end
            %
            if sum(block_check==0)>0
                disp(' ')
                for i=1:numel(block_check)
                    if block_check(i)==0
                        disp(['unidentified subsytem: ' block_names{i}])
                        block_check(strncmpi(block_names,block_names{i},numel(block_names{i})))=-1;
                    end
                end
                disp(' ')
            end
            %
            save_system(bdroot,model);
            close_system(bdroot);
            %
            %
            refreshWaitBar('Fixing label positions...');
            %
            % fix label positions
            modelfile=fileread(model);
            lines=regexp(modelfile,'Line {[^}]+}','match');
            for i=1:numel(lines)
                s0=lines{i};
                if ~isempty(regexp(s0,'Tag\s+"buscreator"','once'))
                    s1=regexprep(s0,'(?<=Labels\s+)\[[^\]]+\]','[-1, 1]');
                    modelfile=strrep(modelfile,s0,s1);
                end
            end
            %
            fid=fopen(model,'w');
            fwrite(fid,modelfile,'char');
            fclose(fid);
            %
            %
            refreshWaitBar('Opening new model...');
            %
            % make new model visible
            open_system(model);
            %
            refreshWaitBar;
        catch
            refreshWaitBar;
            showError('Something went wrong!')
        end
        %
        %
        function blankName(handle,n0,n)
            if nargin<3
                n=10;
            end
            if nargin<2
                n0=1;
            end
            try
                blank='';
                for ii=1:n
                    blank=[blank ' '];
                    if ii>=n0
                        try
                            set(handle,'name',blank)
                            break
                        end
                    end
                end
            end
        end
    end
%
%
%% onToolsStructFilter
    function onToolsStructFilter(hObject,eventData)
        if isempty(logData)
            return
        end
        label=get(hObject,'Label');
        if strcmp(get(hObject,'Checked'),'off')
            hFig=get(0,'CurrentFigure');
            initiateFilterMode(hFig,label);
        else
            terminateFilterMode;
            drawnow;
        end
    end
%
%
%% onToolsStructFilterMark
    function onToolsStructFilterMark(hObject,eventData)
        try
            hFig=findobj('type','Figure','tag','filterFigure');
            hAxes=findobj(hFig,'type','axes','tag','');
            hLine1=findobj(hAxes,'type','line','displayname','data');
            hLine2=findobj(hAxes,'type','line','displayname','spikes');
            if isempty(hLine1) || isempty(hLine2) || numel(hLine1)~=numel(hLine2)
                showError('Plot new data and try again!');
                terminateFilterMode;
                return
            end
            xVals1=get(hLine1,'xdata'); yVals1=get(hLine1,'ydata');
            if ~iscell(xVals1)
                xVals1={xVals1};
                yVals1={yVals1};
            end
            markOk=0;
            xLims=get(hAxes,'XLim');
            yLims=get(hAxes,'YLim');
            for i=1:numel(xVals1)
                switch get(hObject,'label')
                    case 'Increasing values'
                        ind=zeros(size(yVals1{i}));
                        ind(2:end)=diff(yVals1{i})>0;
                    case 'Decreasing values'
                        ind=zeros(size(yVals1{i}));
                        ind(2:end)=diff(yVals1{i})<0;
                    case 'Consecutive same values'
                        ind=zeros(size(yVals1{i}));
                        ind(2:end)=diff(yVals1{i})==0;
                    case 'All visible points'
                        ind=(xVals1{i}>=xLims(1) & xVals1{i}<=xLims(2) & yVals1{i}>=yLims(1) & yVals1{i}<=yLims(2));
                    case 'All invisible points'
                        ind=not(xVals1{i}>=xLims(1) & xVals1{i}<=xLims(2) & yVals1{i}>=yLims(1) & yVals1{i}<=yLims(2));
                    case 'Jumps'
                        data=round(diff(yVals1{i})*1e3)/1e3;
                        dataUnique=unique(data,'first');
                        dataUniqueMany=histc(data,dataUnique);
                        [maxMany,maxManyInd]=max(dataUniqueMany);
                        ind=zeros(size(yVals1{i}));
                        ind(2:end)=(data~=dataUnique(maxManyInd));
                end
                set(hLine2(i),'xdata',xVals1{i}(logical(ind)),'ydata',yVals1{i}(logical(ind)));
                if any(ind)
                    markOk=1;
                end
            end
            if markOk
                figure(hFig);
                state=uisuspend(hFig); uirestore(state);
                for i=1:2
                    pause(0.1); set(hLine2,'marker','.','MarkerEdgeColor','b'); drawnow;
                    pause(0.1); set(hLine2,'marker','o','MarkerEdgeColor','r'); drawnow;
                end
            end
            %             hFig=findobj('type','Figure','tag','filterFigure');
            %             hAxes=findobj(hFig,'type','Axes','tag','');
            %             hLine=findobj(hAxes,'type','line','displayname','data');
            %             hLine2=findobj(hAxes,'type','line','displayname','spikes');
            %             if isempty(hLine) || isempty(hLine2) || numel(hFig)>1
            %                 showError('Plot new data and try again!');
            %                 terminateFilterMode;
            %                 return
            %             elseif numel(hLine)~=1  || numel(hLine2)~=1
            %                 showError('Mark actions are available for single plots only.');
            %                 return
            %             end
            %             xVals=get(hLine,'xdata');
            %             yVals=get(hLine,'ydata');
            %             [xVals,sortInd]=sort(xVals);
            %             yVals=yVals(sortInd);
            %             switch get(hObject,'label')
            %                 case 'Increasing values'
            %                     ind=zeros(size(yVals));
            %                     ind(2:end)=diff(yVals)>0;
            %                 case 'Decreasing values'
            %                     ind=zeros(size(yVals));
            %                     ind(2:end)=diff(yVals)<0;
            %                 case 'Consecutive same values'
            %                     ind=zeros(size(yVals));
            %                     ind(2:end)=diff(yVals)==0;
            %                 case 'All visible points'
            %                     xLims=get(hAxes,'XLim');
            %                     yLims=get(hAxes,'YLim');
            %                     ind=(xVals>=xLims(1) & xVals<=xLims(2) & yVals>=yLims(1) & yVals<=yLims(2));
            %                 case 'All invisible points'
            %                     xLims=get(hAxes,'XLim');
            %                     yLims=get(hAxes,'YLim');
            %                     ind=not(xVals>=xLims(1) & xVals<=xLims(2) & yVals>=yLims(1) & yVals<=yLims(2));
            %             end
            %             set(hLine2,'xdata',xVals(logical(ind)),'ydata',yVals(logical(ind)));
            %             if any(ind)
            %                 figure(hFig);
            %                 state=uisuspend(hFig); uirestore(state);
            %                 for i=1:2
            %                     pause(0.1); set(hLine2,'marker','.','MarkerEdgeColor','b'); drawnow;
            %                     pause(0.1); set(hLine2,'marker','o','MarkerEdgeColor','r'); drawnow;
            %                 end
            %             end
        catch
            showError('Something went wrong!\nPlot new data and try again.')
        end
    end
%
%
%% onToolsStructLoadData
    function onToolsStructLoadData(hObject,eventData)
        persistent path
        try
            if isempty(path) || ~ischar(path)
                path=[pwd '\'];
            end
            [file,pathSelected]=uigetfile([path '\*.mat'],'Load data');
            drawnow; pause(0.01);
            if ischar(file) && ischar(path)
                path=pathSelected;
                refreshWaitBar('Loading...');
                try
                    matFile=load([path file]);
                    fn=fieldnames(matFile);
                    button='';
                    fnProper={};
                    for i=1:numel(fn)
                        wname=fn{i};
                        check=isStructLogOk(matFile.(wname));
                        if check
                            try
                                temp=evalin('base',wname);
                                if strcmp(button,'Yes to all')
                                    assignin('base',wname,matFile.(wname));
                                    fnProper{end+1}=wname;
                                else
                                    button=questdlg(['"' wname '" will be replaced in workspace. Continue?'],'Warning','Yes','Yes to all','No','No');
                                    drawnow; pause(0.01);
                                    if strncmp(button,'Yes',3)
                                        assignin('base',wname,matFile.(wname));
                                        fnProper{end+1}=wname;
                                    end
                                end
                            catch
                                assignin('base',wname,matFile.(wname));
                                fnProper{end+1}=wname;
                            end
                        end
                    end
                catch
                    fnProper={};
                end
                refreshWaitBar;
                if isempty(fnProper)
                    showError('Invalid file!')
                elseif numel(fnProper)==1
                    refreshInterface(fnProper{1});
                else
                    [ind,ok]=listdlg('PromptString','Select data','SelectionMode','single','ListSize',[150,100],'liststring',fnProper);
                    drawnow; pause(0.01);
                    if ok && numel(ind)==1
                        refreshInterface(fnProper{ind});
                    else
                        return
                    end
                end
            end
        catch
            refreshWaitBar;
            showError('Something went wrong!');
        end
    end
%
%
%% onToolsStructSaveData
    function onToolsStructSaveData(hObject,eventData)
        persistent path
        try
            if isempty(path) || ~ischar(path)
                path=[pwd '\'];
            end
            if isempty(logData)
                return
            end
            [file,pathSelected]=uiputfile([path '\' prf.structLogBaseName '.mat'],'Save mat file');
            drawnow; pause(0.01);
            if ischar(file) && ischar(path)
                path=pathSelected;
                refreshWaitBar('Saving...')
                temp.(prf.structLogBaseName)=logData; %#ok<STRNU>
                save([path file],'-struct','temp');
                refreshWaitBar;
            end
        catch
            refreshWaitBar;
            showError('Something went wrong!');
        end
    end
%
%
%% onToolsStructImportData
    function onToolsStructImportData(hObject,eventData)
        refreshInterface;
    end
%
%
%% onToolsStructExportData
    function onToolsStructExportData(hObject,eventData)
        if isempty(logData)
            return
        end
        try
            answer=inputdlg('Variable name','',1,{prf.structLogBaseName});
            drawnow; pause(0.01);
            if numel(answer)==1
                assignin('base',answer{1},logData)
            end
        catch
            showError('Something went wrong!');
        end
    end
%
%
%% onToolsStructEditRules
    function onToolsStructEditRules(hObject,eventData)
        if isempty(logData)
            return
        end
        try
            showEditDialog('rules struct');
        catch
            showError('Something went wrong!')
        end
    end
%
%
%% onToolsStructExtractByte
    function onToolsStructExtractByte(hObject,eventData)
        try
            files=dir('plotlabExtractRules.xls');
            if numel(files)==1
                file='plotlabExtractRules.xls';
                path=[pwd '\'];
            else
                [file,path]=uigetfile({'*.xls;*.xlsx;','*.xls, *.xlsx'},'Select rules file','plotlabExtractRules.xls');
                drawnow; pause(0.01);
            end
            if ischar(file) && ischar(path)
                %
                % get rules
                %
                refreshWaitBar('Reading excel...')
                [num,txt,rules]=xlsread([path file]);
                rules=cellfun(@correctRaw,rules,'UniformOutput',false);
                ruleNames=rules(1,:);
                rules(1,:)=[];
                for i=1:numel(ruleNames)
                    if sum(strcmp(ruleNames,ruleNames{i}))>1 && ~isempty(strtrim(ruleNames{i}))
                        showError([ruleNames{i} ' column is not unique!'])
                        refreshWaitBar;
                        return
                    end
                end
                %
                % check rules
                %
                % variable
                matchInd=strcmp(ruleNames,'variable');
                if sum(matchInd)~=1
                    showError('"variable" column is missing!')
                    refreshWaitBar;
                    return
                else
                    variable=rules(:,matchInd);
                end
                for i=1:numel(variable)
                    if isempty(variable{i}) || ~isvarname(variable{i})
                        showError(['"variable" entry in row ' num2str(i+1) ' is invalid!'])
                        refreshWaitBar;
                        return
                    end
                end
                % counterName & counterInd & counterNo
                matchInd=strcmp(ruleNames,'counter name / counter no');
                if sum(matchInd)~=1
                    counterInfo=cell(size(rules,1),1);
                else
                    counterInfo=rules(:,matchInd);
                end
                counterName=cell(size(counterInfo));
                counterInd=zeros(size(counterInfo));
                counterNo=zeros(size(counterInfo));
                for i=1:numel(counterInfo)
                    if ~isempty(counterInfo{i})
                        info=strtrim(regexp(['/ ' counterInfo{i} ' / '],'(?<=[\\\/])[^\\\/]*?*?(?=[\\\/])','match'));
                        if iscell(info) && numel(info)==2 && ...
                                sum(strcmp(info{1},variable))==1 && ~isnan(str2double(info{2})) && str2double(info{2})>0
                            counterName{i}=info{1};
                            counterInd(i)=find(strcmp(info{1},variable),1);
                            counterNo(i)=str2double(info{2});
                        else
                            showError(['"counter" entry in row ' num2str(i+1) ' is invalid!'])
                            refreshWaitBar;
                            return
                        end
                    end
                end
                % frame offset & type
                matchInd=strcmp(ruleNames,'frame offset');
                if sum(matchInd)~=1
                    showError('"frame offset" column is missing!')
                    refreshWaitBar;
                    return
                else
                    offset=rules(:,matchInd);
                end
                matchInd=strcmp(ruleNames,'type');
                if sum(matchInd)~=1
                    showError('"type" column is missing!')
                    refreshWaitBar;
                    return
                else
                    type=rules(:,matchInd);
                end
                allTypes={'uint8',1;'int8',1;'uint16',2;'int16',2;'uint32',4;'int32',4;...
                    'uint64',8;'int64',8;'single',4;'double',8};
                minorFrameLeng0=0;
                for i=1:numel(offset)
                    typeInd=find(strcmp(type{i},allTypes(:,1))==1,1);
                    if isempty(typeInd)
                        showError(['"type" entry in row ' num2str(i+1) ' is invalid!'])
                        refreshWaitBar;
                        return
                    end
                    variableOffset=str2num(offset{i});
                    if numel(variableOffset)~=1 || variableOffset<0
                        showError(['"offset" entry in row ' num2str(i+1) ' is invalid!'])
                        refreshWaitBar;
                        return
                    else
                        offset{i}=variableOffset;
                    end
                    if variableOffset>=minorFrameLeng0
                        minorFrameLeng0=variableOffset+allTypes{typeInd,2};
                    end
                end
                % rootField & variableField
                matchInd=strcmp(ruleNames,'field');
                if sum(matchInd)~=1
                    rootField=cell(size(rules,1),1);
                else
                    rootField=rules(:,matchInd);
                end
                variableField=cell(size(rootField));
                mergedStructure=struct;
                for i=1:numel(rootField)
                    if ~isempty(rootField{i})
                        try
                            eval(['mergedStructure.' rootField{i} '=[];'])
                            variableField{i}=[rootField{i} '.' variable{i}];
                        catch
                            showError(['"field" entry in row ' num2str(i+1) ' is invalid!'])
                            refreshWaitBar;
                            return
                        end
                    else
                        variableField{i}=variable{i};
                    end
                end
                if numel(unique(variableField))~=numel(variable)
                    for i=1:numel(variable)
                        if sum(strcmp(variableField,variableField{i}))>1
                            showError([variableField{i} ' is not unique! \nAssign different fields to variables with same name.'])
                            refreshWaitBar;
                            return
                        end
                    end
                end
                variableNum=numel(variableField);
                % label & factor & unit
                plotlabRulez=struct;
                matchInd=strcmp(ruleNames,'label');
                if sum(matchInd)~=1
                    labelCell=cell(size(rules,1),1);
                else
                    labelCell=rules(:,matchInd);
                end
                matchInd=strcmp(ruleNames,'factor');
                if sum(matchInd)~=1
                    factorCell=cell(size(rules,1),1);
                else
                    factorCell=rules(:,matchInd);
                end
                matchInd=strcmp(ruleNames,'unit');
                if sum(matchInd)~=1
                    unitCell=cell(size(rules,1),1);
                else
                    unitCell=rules(:,matchInd);
                end
                for i=1:numel(labelCell)
                    if ~isempty(labelCell{i}) && ~isempty(strfind(labelCell{i},';'))
                        if any(strcmp({'uint32','uint16','uint8'},type{i}))
                            factorCell{i}=[];
                            unitCell{i}=[];
                        else
                            showError(['"label" entry does not match with "type" entry in row ' num2str(i+1) '!'])
                            refreshWaitBar;
                            return
                        end
                    end
                end
                ind=any(~cellfun('isempty',[labelCell factorCell unitCell].')).';
                if any(ind)
                    plotlabRulez.variableField=variableField(ind);
                    plotlabRulez.label=labelCell(ind);
                    plotlabRulez.factor=factorCell(ind);
                    plotlabRulez.unit=unitCell(ind);
                end
                % byteFile & varName & swapFlag
                matchInd=strcmp(ruleNames,'byte file');
                if sum(matchInd)~=1
                    showError('"byte file" column is missing!')
                    refreshWaitBar;
                    return
                else
                    byteFile0=rules(:,matchInd);
                end
                matchInd=strcmp(ruleNames,'structure');
                if sum(matchInd)~=1
                    showError('"structure" column is missing!')
                    refreshWaitBar;
                    return
                else
                    varName0=rules(:,matchInd);
                end
                matchInd=strcmp(ruleNames,'swap bytes');
                if sum(matchInd)~=1
                    swapFlag0=cell(size(rules,1),1);
                else
                    swapFlag0=rules(:,matchInd);
                end
                byteFile={};
                varName={};
                swapFlag=[];
                for i=1:numel(byteFile0)
                    if ~isempty(byteFile0{i})
                        if exist(byteFile0{i},'file')
                            byteFile{end+1}=byteFile0{i};
                        elseif exist([path byteFile0{i}],'file')
                            byteFile{end+1}=[path byteFile0{i}];
                        else
                            showError(['"byte file" entry in row ' num2str(i+1) ' doesn''t exist!'])
                            refreshWaitBar;
                            return
                        end
                        if ~isempty(varName0{i}) && isvarname(varName0{i})
                            varName{end+1}=varName0{i};
                        else
                            showError(['"structure" entry in row ' num2str(i+1) ' is invalid!'])
                            refreshWaitBar;
                            return
                        end
                        if isempty(swapFlag0{i})
                            swapFlag(end+1)=0;
                        else
                            swapEntry=str2double(swapFlag0{i});
                            if swapEntry==1 || swapEntry==0
                                swapFlag(end+1)=swapEntry;
                            else
                                showError(['"swap bytes" entry in row ' num2str(i+1) ' is invalid!'])
                                refreshWaitBar;
                                return
                            end
                        end
                        if typecast(uint8([2^0 2^3]),'uint16')==(2^11+2^0) %system is little-endian
                            swapFlag(end)=~swapFlag(end);
                        end
                    else
                        break
                    end
                end
                if isempty(byteFile)
                    showError('"byte file" entry is not identified!')
                    refreshWaitBar;
                    return
                end
                % syncWord
                matchInd=strcmp(ruleNames,'sync word');
                if sum(matchInd)~=1
                    syncWord='';
                else
                    syncWord=rules{1,matchInd};
                end
                % minorFrameNum
                matchInd=strcmp(ruleNames,'minor frame number');
                if sum(matchInd)~=1
                    minorFrameNum=1;
                else
                    minorFrameNum=str2num(rules{1,matchInd});
                end
                if isempty(minorFrameNum)
                    minorFrameNum=1;
                else
                    if isempty(minorFrameNum) || numel(minorFrameNum)~=1 || minorFrameNum<1
                        showError('"minor frame number" entry is invalid!')
                        refreshWaitBar;
                        return
                    end
                end
                % minorFrameLeng
                matchInd=strcmp(ruleNames,'minor frame length');
                if sum(matchInd)~=1
                    minorFrameLeng=[];
                else
                    minorFrameLeng=str2num(rules{1,matchInd});
                end
                if isempty(minorFrameLeng) && minorFrameNum==1
                    minorFrameLeng=minorFrameLeng0;
                elseif isempty(minorFrameLeng) || minorFrameLeng<2
                    showError('"minor frame length" entry is invalid!')
                    refreshWaitBar;
                    return
                end
                % timeVar
                matchInd=strcmp(ruleNames,'time variable');
                if sum(matchInd)~=1
                    timeVar='';
                else
                    timeVar=rules{1,matchInd};
                end
                timeVarNo=find(strcmp(variable,timeVar)==1);
                if ~(numel(timeVarNo)==1 || isempty(timeVar))
                    showError('"time variable" entry is invalid!')
                    refreshWaitBar;
                    return
                end
                %
                % extract files
                %
                refreshWaitBar('Extracting...')
                structure=struct;
                for fileNo=1:numel(byteFile)
                    % get rawdata
                    try
                        if ~isempty(regexp(byteFile{fileNo},'((\.acq)|(\.cnv)|(\.csv)|(\.bin)|(\.hex))$','once'))
                            if ~isempty(regexp(byteFile{fileNo},'(\.csv)$','once'))
                                rawData=importdata(byteFile{fileNo});
                                rawData=uint8(reshape(rawData.data.',[],1));
                            elseif ~isempty(regexp(byteFile{fileNo},'(\.hex)$','once'))
                                rawData=fileread(byteFile{fileNo});
                                rawData=regexp(rawData,'[0-9a-f][0-9a-f]','match');
                                rawData=uint8(hex2dec(cell2mat(rawData'))');
                            else
                                fid=fopen(byteFile{fileNo},'r');
                                rawData=fread(fid,'uint8');
                                rawData=uint8(reshape(rawData,[],1));
                                fclose(fid);
                                if ~isempty(regexp(byteFile{fileNo},'(\.bin)$','once'))
                                    rawData(2:2:end)=[];
                                end
                            end
                            % find sync words
                            try
                                hex2dec(syncWord(2:end)); %length must be at least 2
                            catch
                                showError('"sync word" is not a valid hex number!')
                                refreshWaitBar;
                                return
                            end
                            syncInd=true(size(rawData(1:end-10)));
                            for i=1:2:(numel(syncWord)-1)
                                syncInd=syncInd & rawData(1+(i-1)/2:end-10+(i-1)/2)==hex2dec(syncWord(i:i+1));
                            end
                            syncInd=find(syncInd==1);
                            if numel(syncInd)<1
                                showError(['No matching sync word in "' byteFile{fileNo} '"'])
                                refreshWaitBar;
                                return
                            end
                            % find minor frames
                            syncIndNum=numel(syncInd);
                            rawDataNum=numel(rawData);
                            minorFrameInd=zeros(syncIndNum*minorFrameNum,1);
                            maxOffset=max(minorFrameLeng,minorFrameLeng0);
                            m=1;
                            for i=1:numel(syncInd)
                                for j=1:minorFrameNum
                                    try
                                        temp=syncInd(i)+numel(syncWord)/2+minorFrameLeng*(j-1);
                                        if temp+maxOffset<rawDataNum
                                            minorFrameInd(m)=temp;
                                            m=m+1;
                                        end
                                    end
                                end
                            end
                            try
                                minorFrameInd(m:end)=[];
                            end
                        elseif ~isempty(regexp(byteFile{fileNo},'(\.txt)$','once'))
                            rawData=uint8(importdata(byteFile{fileNo}));
                            if size(rawData,2)==1 || size(rawData,2)<minorFrameLeng0
                                showError('Invalid data file!')
                                refreshWaitBar;
                                return
                            end
                            minorFrameInd=(0:(size(rawData,1))-1).'*size(rawData,2)+1;
                            rawData=reshape(rawData.',[],1);
                        else
                            showError('Invalid data file!')
                            refreshWaitBar;
                            return
                        end
                    catch
                        showError('Invalid data file!')
                        refreshWaitBar;
                        return
                    end
                    %
                    % extract
                    counterStructure=struct; %get unique counter data first
                    uniqueCounterInd=unique(counterInd(counterInd>0));
                    for i=1:numel(uniqueCounterInd)
                        try
                            typeInd=find(strcmp(type{uniqueCounterInd(i)},allTypes(:,1))==1,1);
                            byteNum=allTypes{typeInd,2};
                            if byteNum==1
                                counterData=reshape(rawData(minorFrameInd+offset{uniqueCounterInd(i)}),[],1);
                            else
                                byteData=uint8(zeros(size(minorFrameInd,1),byteNum));
                                if swapFlag(fileNo) %swapbytes!
                                    for j=1:byteNum
                                        byteData(:,byteNum-j+1)=rawData(minorFrameInd+offset{uniqueCounterInd(i)}+j-1);
                                    end
                                else
                                    for j=1:byteNum
                                        byteData(:,j)=rawData(minorFrameInd+offset{uniqueCounterInd(i)}+j-1);
                                    end
                                end
                                byteData=reshape(byteData.',[],1);
                                counterData=typecast(byteData,type{uniqueCounterInd(i)});
                            end
                            counterArray=1:max(counterNo(counterInd==uniqueCounterInd(i)));
                            counterOkInd=true(numel(counterData)-numel(counterArray),1);
                            for j=1:numel(counterArray)
                                counterOkInd=counterOkInd & (counterData(j:end-numel(counterArray)+j-1)==counterArray(j));
                            end
                            counterOkInd=[counterOkInd; false(numel(counterArray),1)];
                            counterStructure.(['counter' num2str(uniqueCounterInd(i))])=counterData;
                            counterStructure.(['counter' num2str(uniqueCounterInd(i)) 'OkInd'])=counterOkInd;
                        end
                    end
                    for i=1:numel(variable)
                        %get bytes of data
                        allTypes={'uint8',1;'int8',1;'uint16',2;'int16',2;'uint32',4;'int32',4;...
                            'uint64',8;'int64',8;'single',4;'double',8};
                        typeInd=find(strcmp(type{i},allTypes(:,1))==1,1);
                        byteNum=allTypes{typeInd,2};
                        byteData=uint8(zeros(size(minorFrameInd,1),byteNum));
                        if swapFlag(fileNo) %swapbytes!
                            for j=1:byteNum
                                byteData(:,byteNum-j+1)=rawData(minorFrameInd+offset{i}+j-1);
                            end
                        else
                            for j=1:byteNum
                                byteData(:,j)=rawData(minorFrameInd+offset{i}+j-1);
                            end
                        end
                        % convert from byte
                        byteData=reshape(byteData.',[],1);
                        data=typecast(byteData,type{i}); %might be NaN
                        if any(isnan(data))
                            data(isnan(data))=0;
                        end
                        % set according to value of counter assigned
                        if counterInd(i)>0
                            if ~isa(data,'single')
                                data=double(data);
                            end
                            try
                                counterData=counterStructure.(['counter' num2str(counterInd(i))]);
                                counterOkInd=counterStructure.(['counter' num2str(counterInd(i)) 'OkInd']);
                                ind=find(counterData==counterNo(i));
                                ind(ind<counterNo(i))=[];
                                ind=ind(counterOkInd(ind-counterNo(i)+1));
                                meantData=data(ind);
                                data(:)=NaN;
                                data(ind-counterNo(i)+1)=meantData;
                            catch
                                data(:)=NaN;
                            end
                        end
                        % set field
                        eval(['structure(fileNo).' variableField{i} '=data;'])
                    end
                    % % check crc
                    % crcOffset=281;
                    % byteData=uint8(zeros(size(minorFrameInd,1),2));
                    % if swapFlag(fileNo)
                    %     byteData(:,2)=rawData(minorFrameInd+crcOffset);
                    %     byteData(:,1)=rawData(minorFrameInd+crcOffset+1);
                    % else
                    %     byteData(:,1)=rawData(minorFrameInd+crcOffset);
                    %     byteData(:,2)=rawData(minorFrameInd+crcOffset+1);
                    % end
                    % byteData=reshape(byteData.',[],1);
                    % crc0=typecast(byteData,'uint16');
                    % crcCheck=false(size(crc0));
                    % for i=1000:numel(minorFrameInd)
                    %     crcCheckData=rawData(minorFrameInd(i):minorFrameInd(i)+crcOffset-1);
                    %     crc=uint16(0);
                    %     for j=1:numel(crcCheckData)
                    %         data=bitshift(uint16(crcCheckData(j)),8);
                    %         for k=1:8
                    %             if bitand(bitxor(data,crc),2^15)
                    %                 crc=bitxor(bitshift(crc,1),uint16(4129));
                    %             else
                    %                 crc=bitshift(crc,1);
                    %             end
                    %             data=bitshift(data,1);
                    %         end
                    %     end
                    %     if isequal(crc0(i),crc) || isequal(swapbytes(crc0(i)),crc)
                    %         crcCheck(i)=true;
                    %         i
                    %     end
                    % end
                end
                % export to workspace
                toBeSavedLater=struct;
                for fileNo=1:numel(byteFile)
                    structureProper=structure(fileNo);
                    structureProper.plotlabRulez=plotlabRulez;
                    assignin('base',varName{fileNo},structureProper);
                    toBeSavedLater.(varName{fileNo})=structureProper;
                end
                %
                % merge
                %
                try
                    if ~isempty(timeVar) && numel(byteFile)>1
                        refreshWaitBar('Merging...')
                        % create a reference merged structure
                        mergedStructure=struct;
                        dataField=cell(variableNum,1);
                        for fileNo=1:numel(byteFile)
                            for i=1:variableNum
                                field=['data' num2str(i)];
                                dataField{i}=field;
                                try
                                    data0=mergedStructure.(field);
                                catch
                                    data0=[];
                                end
                                data=[];
                                eval(['data=structure(fileNo).' variableField{i} ';'])
                                data0=[data0; data];
                                mergedStructure.(field)=data0;
                            end
                        end
                        % get time variable and sort whole data
                        timeMerged=mergedStructure.(dataField{timeVarNo});
                        [timeMerged,sortInd]=sort(timeMerged);
                        nanInd=isnan(timeMerged);
                        timeMerged=timeMerged(~nanInd);
                        sortInd=sortInd(~nanInd);
                        mergedStructure=structfun(@(x)(x(sortInd)),mergedStructure,'uniformoutput',0);
                        % create a reference matrix (much faster to work with)
                        mergedMatrix=zeros(numel(timeMerged),variableNum);
                        for i=1:variableNum
                            mergedMatrix(:,i)=double(mergedStructure.(dataField{i}));
                        end
                        % find combinations of 2, will use later
                        combosCell=cell(10,1);
                        for j=2:10
                            combosCell{j}=flipud(combntns(1:j,2)); %flip to check latest points first!
                        end
                        % look for at least 2 exactly same frames
                        [timeMergedUnique,timeMergedUniqueInd,timeMergedInd]=unique(timeMerged,'first');
                        timeMergedUniqueMany=histc(timeMerged,timeMergedUnique);
                        timeMergedUniqueNum=numel(timeMergedUniqueInd);
                        reliableInd=false(size(timeMerged));
                        mergedInd=true(size(timeMerged));
                        for i=1:timeMergedUniqueNum
                            j=timeMergedUniqueInd(i);
                            n=timeMergedUniqueMany(i);
                            if n>1
                                checkMatrix=mergedMatrix(j:j+n-1,:);
                                try
                                    combos=combosCell{n};
                                catch
                                    combos=combosCell{10};
                                end
                                for k=1:size(combos,1)
                                    if isequalwithequalnans(checkMatrix(combos(k,1),:),checkMatrix(combos(k,2),:))
                                        reliableInd(j+combos(k,1)-1)=true;
                                        mergedInd(j:j+n-1)=false;
                                        mergedInd(j+combos(k,1)-1)=true;
                                        break
                                    end
                                end
                            end
                        end
                        % create reliable structure
                        reliableStructure=struct;
                        for v=1:variableNum
                            field=dataField{v};
                            data=mergedStructure.(field);
                            reliableStructure.(field)=data(reliableInd);
                        end
                        % remove unnecessary indices from merged structure
                        for v=1:variableNum
                            field=dataField{v};
                            data=mergedStructure.(field);
                            mergedStructure.(field)=data(mergedInd);
                        end
                        % export to workspace with proper fields
                        reliableStructureProper=struct;
                        mergedStructureProper=struct;
                        for i=1:variableNum
                            eval(['reliableStructureProper.' variableField{i} '=reliableStructure.' dataField{i} ';']);
                            eval(['mergedStructureProper.' variableField{i} '=mergedStructure.' dataField{i} ';']);
                        end
                        reliableStructureProper.plotlabRulez=plotlabRulez;
                        mergedStructureProper.plotlabRulez=plotlabRulez;
                        assignin('base','reliable',reliableStructureProper);
                        assignin('base','merged',mergedStructureProper);
                        toBeSavedLater.reliable=reliableStructureProper;
                        toBeSavedLater.merged=mergedStructureProper;
                    end
                end
                refreshWaitBar;
                %
                % save to file
                %
                [file,path]=uiputfile('testdata.mat','Save to mat file');
                drawnow; pause(0.01);
                if ischar(file) && ischar(path)
                    refreshWaitBar('Saving...')
                    try
                        save([path file],'-struct','toBeSavedLater');
                    catch
                        showError('Save failed!');
                    end
                    refreshWaitBar;
                end
            end
        catch
            refreshWaitBar;
            showError('Something went wrong!');
        end
        %
        %
        function out=correctRaw(in)
            out='';
            try
                if ~isempty(in) && ischar(in) && ~isempty(strtrim(in))
                    out=strtrim(in);
                elseif ~isempty(in) && ~ischar(in) && ~isnan(in)
                    try
                        in=num2str(in);
                        if ~strncmpi(in,'NaN',3)
                            out=in;
                        end
                    end
                end
            end
        end
    end
%
%
%% onToolsStructCreateExtractRule
    function onToolsStructCreateExtractRule(hObject,eventData)
        try
            template={'variable','counter name / counter no','frame offset','type','field','label','factor','unit','','',...
                'byte file','structure','swap bytes','','','sync word','minor frame number','minor frame length','time variable';
                %
                'counter','','0','uint8','','','','','','','acra.acq','raw_acra','','','','A1B2C3D4','','','timeMCSW';...
                'p','','1','single','imu','wx','180/pi','d','','','jda.acq','raw_jda','','','','','','','';...
                'variable','counter / 1','5','int16','','','','','','','','','','','','','','','';...
                'flagA','counter / 2','5','uint16','flags','a;b;c;d;e,8;f;g,2;h','','','','','','','','','','','','','';...
                };
            [file,path]=uiputfile('plotlabExtractRules.xls','Save template');
            drawnow; pause(0.01);
            if ischar(file) && ischar(path)
                try
                    xlswrite([path file],template);
                catch
                    showError('File is not written!');
                    return
                end
            end
        catch
            showError('Something went wrong!');
        end
    end
%
%
%% refreshInterface
    function refreshInterface(logBaseName)
        try
            if nargin<1
                logBaseName=[];
            end
            % waitbar
            refreshWaitBar('Loading...');
            % clear frame
            try
                delete(gui.framePaneComp)
                drawnow; pause(0.001);
            end
            % clear variables
            terminateFilterMode; %filtermode
            prf.xAxis=[]; refreshMenuRightClick; %x-axis
            xpcData.data=[]; xpcData.time=[]; % clear xpc variables
            % get log
            try
                errorList={};
                switch prf.mode
                    case 'struct'
                        % get data
                        if isempty(logBaseName)
                            prf.structLogBaseName=[];
                            vars=evalin('base','whos');
                            structNames={};
                            for k=1:length(vars)
                                if strcmp(vars(k).class,'struct')
                                    logData0=evalin('base',vars(k).name);
                                    check=isStructLogOk(logData0);
                                    if check
                                        structNames{end+1}=vars(k).name;
                                    end
                                end
                            end
                            if numel(structNames)==1
                                prf.structLogBaseName=structNames{1};
                            elseif ~isempty(structNames)
                                [ind,ok]=listdlg('PromptString','Select data','SelectionMode','single','ListSize',[150,100],'liststring',structNames);
                                drawnow; pause(0.01);
                                if ok && numel(ind)==1
                                    prf.structLogBaseName=structNames{ind};
                                else
                                    prf.structLogBaseName=[];
                                end
                            else
                                prf.structLogBaseName=[];
                            end
                        else
                            prf.structLogBaseName=logBaseName;
                        end
                        logData=evalin('base',prf.structLogBaseName);
                        % create info
                        rulesFound=0;
                        try
                            if isequal(size(logData.plotlabRulez.variableField),...
                                    size(logData.plotlabRulez.label),...
                                    size(logData.plotlabRulez.unit),...
                                    size(logData.plotlabRulez.factor))
                                rulesFound=1;
                            end
                        end
                        logs={'logData',{},''};
                        logInfo={};
                        for counter=1:1000;
                            newLogs={};
                            for i=1:size(logs,1)
                                subLogs=fieldnames(eval(logs{i,1}));
                                for j=1:numel(subLogs)
                                    logName=[logs{i,1} '.' subLogs{j}];
                                    properSubName=subLogs{j};
                                    log=eval(logName);
                                    % identify the log
                                    if isstruct(log) && strcmpi(subLogs{j},'plotlabRulez')
                                        % skip
                                    elseif isstruct(log) && numel(log)==1
                                        logorder=num2str(j*1e-3+1e-5);
                                        newLogs{end+1,1}=logName;
                                        newLogs{end,2}=[logs{i,2} {properSubName}];
                                        newLogs{end,3}=[logs{i,3} logorder(3:5) '-'];
                                    elseif isnumeric(log)
                                        logorder=num2str(j*1e-3+1e-5);
                                        [data,time,dimOk]=extractLogData(log);
                                        if dimOk
                                            eval([logName '=data;'])%force!
                                            size1=size(data,1); %#ok<NASGU>
                                            size2=size(data,2);
                                            try
                                                ruleInd=find(strcmp(regexprep(logName,'^logData\.',''),logData.plotlabRulez.variableField),1);
                                                %                                     try
                                                %                                         ruleInd=find(strcmp(regexprep(logInfo{i,1},'^logData\.',''),logData.plotlabRulez.variableField),1);
                                                %                                         logInfo{i,4}=logData.plotlabRulez.label{ruleInd};
                                                %                                         logInfo{i,5}=logData.plotlabRulez.unit{ruleInd};
                                                %                                         logInfo{i,6}=logData.plotlabRulez.factor{ruleInd};
                                                %                                     end
                                            catch
                                                ruleInd=[];
                                            end
                                            if size2<2
                                                if isempty(ruleInd)
                                                    logInfo{end+1,1}=logName;
                                                    logInfo{end,2}=1;
                                                    logInfo{end,3}=[logs{i,2} {properSubName}];
                                                    logInfo{end,4}='';
                                                    logInfo{end,5}='';
                                                    logInfo{end,6}='';
                                                    logInfo{end,7}=[logs{i,3} logorder(3:5)];
                                                else
                                                    if ~isempty(strfind(logData.plotlabRulez.label{ruleInd},';'))
                                                        labels=strtrim(regexp(['; ' logData.plotlabRulez.label{ruleInd} ' ;'],'(?<=\;)[^\;]+(?=\;)','match'));
                                                        bitNo=0;
                                                        for k=1:numel(labels)
                                                            bitName=strtrim(regexp([', ' labels{k} ' ,'],'(?<=,)[^,]+(?=,)','match'));
                                                            if numel(bitName)==2 && numel(str2num(bitName{2}))==1 && str2num(bitName{2})>0
                                                                bitNo=bitNo(end)+(1:str2num(bitName{2}));
                                                            else
                                                                bitNo=bitNo(end)+1;
                                                            end
                                                            bitName=bitName{1};
                                                            if isempty(bitName)
                                                                bitName=['(' strrep(num2str(bitNo),'  ',' ') ')'];
                                                            else
                                                                bitName=[bitName ' (' strrep(num2str(bitNo),'  ',' ') ')'];
                                                            end
                                                            indOrder=num2str(k*1e-3+1e-5);
                                                            logInfo{end+1,1}=logName;
                                                            logInfo{end,2}=-bitNo; %minus for bit, plus for column index
                                                            logInfo{end,3}=[logs{i,2} {properSubName,bitName}];
                                                            logInfo{end,4}='';
                                                            logInfo{end,5}='';
                                                            logInfo{end,6}='';
                                                            logInfo{end,7}=[logs{i,3} logorder(3:5) '-' indOrder(3:5)];
                                                        end
                                                    else
                                                        logInfo{end+1,1}=logName;
                                                        logInfo{end,2}=1;
                                                        logInfo{end,3}=[logs{i,2} {properSubName}];
                                                        labels=strtrim(regexp(['| ' logData.plotlabRulez.label{ruleInd} ' |'],'(?<=\|)[^\|]+(?=\|)','match'));
                                                        if numel(labels)~=size2
                                                            logInfo{end,4}='';
                                                        else
                                                            logInfo{end,4}=labels{1};
                                                        end
                                                        logInfo{end,5}=logData.plotlabRulez.unit{ruleInd};
                                                        logInfo{end,6}=logData.plotlabRulez.factor{ruleInd};
                                                        logInfo{end,7}=[logs{i,3} logorder(3:5)];
                                                    end
                                                end
                                            else
                                                newData=struct;
                                                for k=1:size2
                                                    if isempty(ruleInd) || ~isempty(strfind(logData.plotlabRulez.label{ruleInd},';')) %neglect bit rule if size2>1
                                                        indOrder=num2str(k*1e-3+1e-5);
                                                        logInfo{end+1,1}=logName;
                                                        logInfo{end,2}=k;
                                                        logInfo{end,3}=[logs{i,2} {properSubName,num2str(k)}];
                                                        logInfo{end,4}='';
                                                        logInfo{end,5}='';
                                                        logInfo{end,6}='';
                                                        logInfo{end,7}=[logs{i,3} logorder(3:5) '-' indOrder(3:5)];
                                                    else
                                                        indOrder=num2str(k*1e-3+1e-5);
                                                        logInfo{end+1,1}=logName;
                                                        logInfo{end,2}=k;
                                                        labels=strtrim(regexp(['| ' logData.plotlabRulez.label{ruleInd} ' |'],'(?<=\|)[^\|]+(?=\|)','match'));
                                                        if numel(labels)~=size2
                                                            logInfo{end,3}=[logs{i,2} {properSubName,num2str(k)}];
                                                            logInfo{end,4}='';
                                                        else
                                                            % logInfo{end,3}=[logs{i,2} {properSubName,labels{k}}];
                                                            logInfo{end,3}=[logs{i,2} {properSubName,num2str(k)}];
                                                            logInfo{end,4}=labels{k};
                                                        end
                                                        logInfo{end,5}=logData.plotlabRulez.unit{ruleInd};
                                                        logInfo{end,6}=logData.plotlabRulez.factor{ruleInd};
                                                        logInfo{end,7}=[logs{i,3} logorder(3:5) '-' indOrder(3:5)];
                                                    end
                                                end
                                            end
                                        else
                                            errorList{end+1}=['Invalid dimension in field "' regexprep(logName,'^logData',regexptranslate('escape',prf.structLogBaseName)) '"'];
                                        end
                                    else
                                        errorList{end+1}=['Invalid field "' regexprep(logName,'^logData',regexptranslate('escape',prf.structLogBaseName)) '"'];
                                    end
                                end
                            end
                            logs=newLogs; % breaks if "logs" is empty
                            if isempty(logs)
                                break
                            end
                        end
                        % sort logs
                        [sorted,ind]=sort(logInfo(:,7));
                        logInfo=logInfo(ind,1:6);
                    otherwise %simulation
                        % get data
                        if isempty(logBaseName)
                            logVarInd=[];
                            vars=evalin('base','whos');
                            for i=1:length(vars)
                                if strcmp(vars(i).class,'Simulink.ModelDataLogs')
                                    logVarInd=[logVarInd i];
                                end
                            end
                            if numel(logVarInd)>1
                                varList={};
                                for i=1:numel(logVarInd)
                                    varList{end+1}=vars(logVarInd(i)).name;
                                end
                                [sel,ok]=listdlg('PromptString','Select Log data','SelectionMode','single','ListSize',[150,100],'ListString',varList);
                                drawnow; pause(0.01);
                                if ok
                                    logVarInd=logVarInd(sel);
                                else
                                    logVarInd=[];
                                end
                            end
                            prf.simLogBaseName=vars(logVarInd).name;
                        else
                            prf.simLogBaseName=logBaseName;
                        end
                        logData=evalin('base',prf.simLogBaseName);
                        % create info
                        logs={'logData',{},''};
                        logInfo={};
                        for counter=1:100;
                            newLogs={};
                            for i=1:size(logs,1)
                                try
                                    mainLogs=eval(logs{i,1});
                                    subLogs=mainLogs.whos;
                                    for j=1:numel(subLogs)
                                        try
                                            logName=[logs{i,1} '.' subLogs(j).name];
                                            orgSubName=subLogs(j).name;
                                            properSubName=orgSubName;
                                            if sum(strcmpi(arrayfun(@(x)(x.name),subLogs,'UniformOutput',0),orgSubName))==1 ... %check for same signals
                                                    && any(regexp(orgSubName,'\n'))==0 %check for newline char
                                                % correct subname
                                                try
                                                    if strcmp(properSubName(1:2),'(''') && strcmp(properSubName(end-1:end),''')')
                                                        properSubName=properSubName(3:end-2);
                                                    end
                                                end
                                                try
                                                    if strcmp(properSubName(1),'<') && strcmp(properSubName(end),'>')
                                                        properSubName=properSubName(2:end-1);
                                                    end
                                                end
                                                try
                                                    if isempty(strtrim(properSubName))
                                                        properSubName='x';
                                                    end
                                                end
                                                % identify the log
                                                if ~isempty(strfind(subLogs(j).simulinkClass,'Timeseries'))
                                                    logorder=num2str(j*1e-3+1e-5);
                                                    try
                                                        log=mainLogs.(orgSubName);
                                                    catch
                                                        log=mainLogs.(eval(orgSubName));
                                                    end
                                                    [data,time,dimOk]=extractLogData(log);
                                                    if dimOk
                                                        size1=size(data,1); %#ok<NASGU>
                                                        size2=size(data,2);
                                                        try
                                                            ruleInd=find(strcmp(prf.rules(:,1),regexprep(logName,'^logData\.',''))==1,1);
                                                            if isempty(ruleInd)
                                                                ruleInd=find(strcmp(prf.rules(:,1),properSubName)==1,1);
                                                            end
                                                        catch
                                                            ruleInd=[];
                                                        end
                                                        if size2<2 %may also be constant or empty
                                                            if isempty(ruleInd)
                                                                logInfo{end+1,1}=logName;
                                                                logInfo{end,2}=1;
                                                                logInfo{end,3}=[logs{i,2} {properSubName}];
                                                                logInfo{end,4}=''; %label
                                                                logInfo{end,5}=''; %unit
                                                                logInfo{end,6}=''; %factor
                                                                logInfo{end,7}=[logs{i,3} logorder(3:5)];
                                                            else
                                                                if ~isempty(strfind(prf.rules{ruleInd,2},';'))
                                                                    labels=strtrim(regexp(['; ' prf.rules{ruleInd,2} ' ;'],'(?<=\;)[^\;]+(?=\;)','match'));
                                                                    bitNo=0;
                                                                    for k=1:numel(labels)
                                                                        bitName=strtrim(regexp([', ' labels{k} ' ,'],'(?<=,)[^,]+(?=,)','match'));
                                                                        if numel(bitName)==2 && numel(str2num(bitName{2}))==1 && str2num(bitName{2})>0
                                                                            bitNo=bitNo(end)+(1:str2num(bitName{2}));
                                                                        else
                                                                            bitNo=bitNo(end)+1;
                                                                        end
                                                                        bitName=bitName{1};
                                                                        if isempty(bitName)
                                                                            bitName=['(' strrep(num2str(bitNo),'  ',' ') ')'];
                                                                        else
                                                                            bitName=[bitName ' (' strrep(num2str(bitNo),'  ',' ') ')'];
                                                                        end
                                                                        indOrder=num2str(k*1e-3+1e-5);
                                                                        logInfo{end+1,1}=logName;
                                                                        logInfo{end,2}=-bitNo; %minus for bit, plus for column index
                                                                        logInfo{end,3}=[logs{i,2} {properSubName,bitName}];
                                                                        logInfo{end,4}='';
                                                                        logInfo{end,5}='';
                                                                        logInfo{end,6}='';
                                                                        logInfo{end,7}=[logs{i,3} logorder(3:5) '-' indOrder(3:5)];
                                                                    end
                                                                else
                                                                    logInfo{end+1,1}=logName;
                                                                    logInfo{end,2}=1;
                                                                    logInfo{end,3}=[logs{i,2} {properSubName}];
                                                                    labels=strtrim(regexp(['| ' prf.rules{ruleInd,2} ' |'],'(?<=\|)[^\|]+(?=\|)','match'));
                                                                    if numel(labels)~=size2
                                                                        logInfo{end,4}='';
                                                                    else
                                                                        logInfo{end,4}=labels{1};
                                                                    end
                                                                    logInfo{end,5}=prf.rules{ruleInd,3};
                                                                    logInfo{end,6}=prf.rules{ruleInd,4};
                                                                    logInfo{end,7}=[logs{i,3} logorder(3:5)];
                                                                end
                                                            end
                                                        else
                                                            for k=1:size2
                                                                if isempty(ruleInd) || ~isempty(strfind(prf.rules{ruleInd,2},';')) %neglect bit rule if size2>1
                                                                    indOrder=num2str(k*1e-3+1e-5);
                                                                    logInfo{end+1,1}=logName;
                                                                    logInfo{end,2}=k;
                                                                    logInfo{end,3}=[logs{i,2} {properSubName,num2str(k)}];
                                                                    logInfo{end,4}='';
                                                                    logInfo{end,5}='';
                                                                    logInfo{end,6}='';
                                                                    logInfo{end,7}=[logs{i,3} logorder(3:5) '-' indOrder(3:5)];
                                                                else
                                                                    indOrder=num2str(k*1e-3+1e-5);
                                                                    logInfo{end+1,1}=logName;
                                                                    logInfo{end,2}=k;
                                                                    labels=strtrim(regexp(['| ' prf.rules{ruleInd,2} ' |'],'(?<=\|)[^\|]+(?=\|)','match'));
                                                                    if numel(labels)~=size2
                                                                        logInfo{end,3}=[logs{i,2} {properSubName,num2str(k)}];
                                                                        logInfo{end,4}='';
                                                                    else
                                                                        % logInfo{end,3}=[logs{i,2} {properSubName,labels{k}}];
                                                                        logInfo{end,3}=[logs{i,2} {properSubName,num2str(k)}];
                                                                        logInfo{end,4}=labels{k};
                                                                    end
                                                                    logInfo{end,5}=prf.rules{ruleInd,3}; %unit
                                                                    logInfo{end,6}=prf.rules{ruleInd,4}; %factor
                                                                    logInfo{end,7}=[logs{i,3} logorder(3:5) '-' indOrder(3:5)];
                                                                end
                                                            end
                                                        end
                                                    else
                                                        errorList{end+1}=['Invalid dimension in "' regexprep(logName,'^logData',regexptranslate('escape',prf.simLogBaseName)) '"'];
                                                    end
                                                else
                                                    logorder=num2str(j*1e-3+1e-5);
                                                    newLogs{end+1,1}=logName;
                                                    newLogs{end,2}=logs{i,2};
                                                    newLogs{end,3}=[logs{i,3} logorder(3:5) '-'];
                                                    % determine whether add the sub name to tree node or not!
                                                    if isempty(strfind(subLogs(j).simulinkClass,'SubsysDataLogs'))
                                                        newLogs{end,2}=[newLogs{end,2} {properSubName}];
                                                    else
                                                        try
                                                            tempLogs=eval([logName '.whos']);
                                                            if numel(tempLogs)>1 || ~isempty(strfind(tempLogs(1).simulinkClass,'Timeseries'))
                                                                newLogs{end,2}=[newLogs{end,2} {properSubName}];
                                                            end
                                                        end
                                                    end
                                                end
                                            else
                                                errorList{end+1}=['Invalid signal name in "' regexprep(logName,'^logData',regexptranslate('escape',prf.simLogBaseName)) '"'];
                                            end
                                        catch
                                            errorList{end+1}=['Something went wrong in "' regexprep(logName,'^logData',regexptranslate('escape',prf.simLogBaseName)) '"'];
                                        end
                                    end
                                catch
                                    errorList{end+1}=['Something went wrong in "' regexprep(logs{i,1},'^logData',regexptranslate('escape',prf.simLogBaseName)) '"'];
                                end
                            end
                            logs=newLogs; % breaks if "logs" is empty
                            if isempty(logs)
                                break
                            end
                        end
                        % sort logs
                        ind=cellfun('isempty',logInfo(:,7));
                        logInfo=logInfo(~ind,:);
                        [sorted,ind]=sort(logInfo(:,7));
                        logInfo=logInfo(ind,1:6);
                        % check same paths
                        fields=cellfun(@extractFields,logInfo(:,3),'uniformoutput',0);
                        [b,m]=unique(fields,'first');
                        ind=sort(setdiff(1:numel(fields),m),'descend');
                        for i=1:numel(ind)
                            errorList{end+1}=['Duplicate log name for "' regexprep(logInfo{ind(i),1},'^logData',regexptranslate('escape',prf.simLogBaseName)) '"'];
                            logInfo(ind(i),:)=[];
                        end
                        % check if first branch is unique
                        firstSub=cellfun(@(x)(x{1}),logInfo(:,3),'UniformOutput',0);
                        if numel(unique(firstSub))==1
                            for i=1:size(logInfo,1)
                                logInfo{i,3}(1)=[];
                            end
                        end
                end
            catch
                logData=[]; logInfo={};
                prf.structLogBaseName=[];
                prf.simLogBaseName=[];
            end
            % error message
            errorStr='';
            if numel(errorList)>10
                errorList(10:end)=[];
                errorList{end+1}='...';
            end
            for errorInd=1:numel(errorList)
                errorStr=[errorStr errorList{errorInd} '\n'];
            end
            errorStr=regexprep(errorStr,'\\n$','');
            if numel(errorList)>0
                showError(errorStr);
            end
            % check logData to continue
            if isempty(logData)
                gui.treeModel.setRoot(javax.swing.tree.DefaultMutableTreeNode);
                refreshWaitBar;
                return
            end
            % root
            switch prf.mode
                case 'struct'
                    root=prf.structLogBaseName;
                otherwise
                    root=logData.Name;
            end
            % create nodes
            rootNode=javax.swing.tree.DefaultMutableTreeNode(root);
            rootNode.removeAllChildren;
            nodePathInd=[];
            for i=1:size(logInfo,1)
                node=rootNode;
                try %!!!! need fix
                    nodeUserData=get(node,'userdata');
                    nodeUserData(end+1)=i;
                    set(node,'userdata',nodeUserData);
                end
                preNodePathInd=nodePathInd;
                nodePathInd=[];
                for j=1:numel(logInfo{i,3})
                    ind=[];
                    try
                        if ~isempty(preNodePathInd) && j<=numel(preNodePathInd)
                            childNode=node.getChildAt(preNodePathInd(j)-1).toString;
                            if strcmp(childNode,logInfo{i,3}{j})
                                ind=preNodePathInd(j);
                            end
                        end
                    end
                    if isempty(ind)
                        newNode=javax.swing.tree.DefaultMutableTreeNode(logInfo{i,3}{j});
                        node.add(newNode);
                        ind=node.getChildCount;
                        preNodePathInd=[];
                    end
                    node=node.getChildAt(ind-1);
                    try %!!!! need fix
                        nodeUserData=get(node,'userdata');
                        nodeUserData(end+1)=i;
                        set(node,'userdata',nodeUserData);
                    end
                    nodePathInd(j)=ind;
                end
            end
            % get previous tree prf if possible
            getTreeStates;
            % update tree
            gui.treeModel.setRoot(rootNode);
            % set tree states from prf
            setTreeStates;
            % update frame
            set(handle(gui.splitPane.getComponent(2),'CallbackProperties'),'ComponentMovedCallback','');
            switch prf.mode
                case 'struct'
                    gui.splitPane.setSize(java.awt.Dimension(prf.sPaneWidthStruct,0));
                    gui.splitPane.setDividerLocation(prf.sPaneLocStruct);
                otherwise
                    gui.splitPane.setSize(java.awt.Dimension(prf.sPaneWidth,0));
                    gui.splitPane.setDividerLocation(prf.sPaneLoc);
            end
            set(handle(gui.splitPane.getComponent(2),'CallbackProperties'),'ComponentMovedCallback',@onGetDividerLocation);
            [pane,gui.framePaneComp]=javacomponent(gui.splitPane,[],gui.frame);
            set(gui.framePaneComp,'units','norm','position',[0,0,1,1]);
            % fix UI
            gui.tree.revalidate;
            gui.tree.repaint;
            % waitbar
            refreshWaitBar;
        catch
            refreshWaitBar;
            showError('Something went wrong in interface!')
        end
        %
        % subfun
        function out=extractFields(in)
            out='';
            for ii=1:numel(in)
                out=[out in{ii}];
            end
        end
    end
%
%
%% refreshList
    function refreshList(mode)
        persistent preSelectedInd
        %
        % check to clear
        if nargin>0 && strcmp(mode,'clear')
            prf.listInd=[];
            gui.listModel.removeAllElements;
            gui.list.setModel(gui.listModel);
            return
        end
        % assignment
        try
            preSelectedInd=getSelectedListIndices;
        catch
            preSelectedInd=[];
        end
        prf.listInd=getSelectedTreeIndices(false);
        if isempty(prf.listInd)
            gui.listModel.removeAllElements;
            gui.list.setModel(gui.listModel);
            return
        end
        % create list data
        switch prf.mode
            case 'struct'
                listData=extractUniqueList(logInfo(prf.listInd,3));
            otherwise
                if strcmp(prf.menuShowLog,'off')
                    listData=extractUniqueList(logInfo(prf.listInd,3));
                else
                    listData=regexprep(logInfo(prf.listInd,1),'^logData',regexptranslate('escape',prf.simLogBaseName));
                end
                if strcmp(prf.menuShowOrder,'on')
                    orderCell=cell(numel(prf.listInd),1);
                    order=0;
                    signal='';
                    for i=1:numel(prf.listInd)
                        %orderCell{i}=' ';
                        if all(logInfo{prf.listInd(i),2}>0)
                            order=order+1;
                            orderCell{i}=num2str(order);
                            bitVar=0;
                        else
                            if ~strcmp(logInfo{prf.listInd(i),1},signal)
                                order=order+1;
                            end
                            orderCell{i}=[num2str(order) ',  bit ' num2str(-logInfo{prf.listInd(i),2})];
                        end
                        signal=logInfo{prf.listInd(i),1};
                    end
                    listData=cellfun(@getStringWithOrder,listData,orderCell,'UniformOutput',0);
                end
        end
        gui.list.setListData(listData)
        % fix UI
        gui.list.revalidate;
        gui.list.repaint;
        % keep selection
        if ~isempty(preSelectedInd)
            match=find(arrayfun(@(x)~isempty(find(preSelectedInd==x,1)),prf.listInd,'UniformOutput',1)==1);
            if ~isempty(match)
                gui.list.setSelectedIndices(match-1);
            end
        end
        % keep tracking the list selection!
        getSelectedListIndices;
        %
        % sub function for cellfun
        function outStr=getStringWithOrder(str1,str2)
            outStr=['<html>' str1 '&nbsp;&nbsp;&nbsp;<i>(' str2 ')</i></html>'];
        end
    end
%
%
%% refreshMenuFigure
    function refreshMenuFigure
        if ~isfield(gui,'menuFigure')
            gui.menuFigure=uimenu(gui.frame,'label','Figure');
        end
        delete(get(gui.menuFigure,'children'));
        for i=1:size(prf.converters,1)
            if isempty(prf.converters{i,1})
                uimenu(gui.menuFigure,'label',prf.converters{i,2},'tag','','callback',{@onFigureConvert,1})
            else
                hMenu=findobj(gui.menuFigure,'label',prf.converters{i,1},'tag','menu');
                if isempty(hMenu)
                    hMenu=uimenu(gui.menuFigure,'label',prf.converters{i,1},'tag','menu');
                end
                uimenu(hMenu,'label',prf.converters{i,2},'tag',prf.converters{i,1},'callback',{@onFigureConvert,1})
            end
        end
        uimenu(gui.menuFigure,'label','Custom convert','callback',{@onFigureConvert,0})
        uimenu(gui.menuFigure,'label','Binary / decimal','separator','on','callback',@onFigureBinDec)
        uimenu(gui.menuFigure,'label','Crop','callback',@onFigureCrop)
        uimenu(gui.menuFigure,'label','Different colors','callback',@onFigureDiffColors)
        uimenu(gui.menuFigure,'label','FFT','callback',@onFigureFFT)
        uimenu(gui.menuFigure,'label','Fit polynomial','callback',@onFigureFitPoly)
        uimenu(gui.menuFigure,'label','Line / marker','callback',@onFigureLineMark)
        uimenu(gui.menuFigure,'label','Mean and std','callback',@onFigureMeanAndStd)
        uimenu(gui.menuFigure,'label','Scale','callback',@onFigureScale)
    end
%
%
%% refreshMenuTools
    function refreshMenuTools
        if ~isfield(gui,'menuTools')
            gui.menuTools=uimenu(gui.frame,'label','Tools');
            uimenu(gui.menuTools,'label','Refresh log','callback',@onToolsRefreshLog)
            uimenu(gui.menuTools,'label','Lock log','callback',@onToolsLockLog)
            uimenu(gui.menuTools,'label','Refresh xPC data','callback',@onToolsRefreshXpc)
            uimenu(gui.menuTools,'label','Load data from file','separator','on','callback',@onToolsLoadData)
            uimenu(gui.menuTools,'label','Save data to file','callback',@onToolsSaveData)
            uimenu(gui.menuTools,'label','Import xPC data from workspace','callback',@onToolsImportXpc)
            uimenu(gui.menuTools,'label','Export xPC data to workspace','callback',@onToolsExportXpc)
            uimenu(gui.menuTools,'label','Plot folder','separator','on','callback',@onToolsPlotFolder)
            uimenu(gui.menuTools,'label','Edit converters','separator','on','callback',@onToolsEditConverters)
            uimenu(gui.menuTools,'label','Edit rules','callback',@onToolsEditRules)
            uimenu(gui.menuTools,'label','Edit plot properties','callback',@onToolsEditPlotProps)
            uimenu(gui.menuTools,'label','Load preferences from file','callback',@onToolsLoadPrf)
            uimenu(gui.menuTools,'label','Save preferences to file','callback',@onToolsSavePrf)
            uimenu(gui.menuTools,'label','Show log on list','separator','on','callback',@onToolsShowLog)
            uimenu(gui.menuTools,'label','Show order on list','callback',@onToolsShowOrder)
            uimenu(gui.menuTools,'label','Modify bus selector','separator','on','callback',@onToolsModifyBusSelector)
            uimenu(gui.menuTools,'label','Rearrange model','callback',@onToolsRearrangeBlocks)
        end
        if ~isfield(gui,'menuToolsStruct')
            gui.menuToolsStruct=uimenu(gui.frame,'label','Tools');
            uimenu(gui.menuToolsStruct,'label','Erase points','callback',@onToolsStructFilter)
            gui.menuToolsStructMark=uimenu(gui.menuToolsStruct,'label','Mark','enable','off');
            uimenu(gui.menuToolsStructMark,'label','Increasing values','callback',@onToolsStructFilterMark)
            uimenu(gui.menuToolsStructMark,'label','Decreasing values','callback',@onToolsStructFilterMark)
            uimenu(gui.menuToolsStructMark,'label','Consecutive same values','callback',@onToolsStructFilterMark)
            uimenu(gui.menuToolsStructMark,'label','All visible points','callback',@onToolsStructFilterMark)
            uimenu(gui.menuToolsStructMark,'label','All invisible points','callback',@onToolsStructFilterMark)
            uimenu(gui.menuToolsStructMark,'label','Jumps','callback',@onToolsStructFilterMark)
            uimenu(gui.menuToolsStruct,'label','Select first index','callback',@onToolsStructFilter)
            uimenu(gui.menuToolsStruct,'label','Select last index','callback',@onToolsStructFilter)
            uimenu(gui.menuToolsStruct,'separator','on','label','Load data from file','callback',@onToolsStructLoadData)
            uimenu(gui.menuToolsStruct,'label','Save data to file','callback',@onToolsStructSaveData)
            uimenu(gui.menuToolsStruct,'label','Import data from workspace','callback',@onToolsStructImportData)
            uimenu(gui.menuToolsStruct,'label','Export data to workspace','callback',@onToolsStructExportData)
            uimenu(gui.menuToolsStruct,'separator','on','label','Edit converters','callback',@onToolsEditConverters)
            uimenu(gui.menuToolsStruct,'label','Edit rules','callback',@onToolsStructEditRules)
            uimenu(gui.menuToolsStruct,'label','Edit plot properties','callback',@onToolsEditPlotProps)
            uimenu(gui.menuToolsStruct,'label','Load preferences from file','callback',@onToolsLoadPrf)
            uimenu(gui.menuToolsStruct,'label','Save preferences to file','callback',@onToolsSavePrf)
            uimenu(gui.menuToolsStruct,'separator','on','label','Extract from byte data','callback',@onToolsStructExtractByte)
            uimenu(gui.menuToolsStruct,'label','Create rule template','callback',@onToolsStructCreateExtractRule)
        end
        switch prf.mode
            case 'struct'
                set(gui.menuTools,'visible','off');
                set(gui.menuToolsStruct,'visible','on');
                set(get(gui.menuToolsStruct,'children'),'enable','on','checked','off');
                checkErase='off';
                checkFirst='off';
                checkLast='off';
                enableErase='on';
                enableFirst='on';
                enableLast='on';
                switch prf.filterMode
                    case 'erase'
                        checkErase='on';
                        enableFirst='off';
                        enableLast='off';
                    case 'first'
                        checkFirst='on';
                        enableErase='off';
                        enableLast='off';
                    case 'last'
                        checkLast='on';
                        enableErase='off';
                        enableFirst='off';
                end
                set(findobj(gui.menuToolsStruct,'label','Erase points'),'enable',enableErase);
                set(findobj(gui.menuToolsStruct,'label','Erase points'),'checked',checkErase);
                set(findobj(gui.menuToolsStruct,'label','Select first index'),'enable',enableFirst);
                set(findobj(gui.menuToolsStruct,'label','Select first index'),'checked',checkFirst);
                set(findobj(gui.menuToolsStruct,'label','Select last index'),'enable',enableLast);
                set(findobj(gui.menuToolsStruct,'label','Select last index'),'checked',checkLast);
                set(gui.menuToolsStructMark,'enable',checkErase);
            case 'xpc'
                set(gui.menuToolsStruct,'visible','off');
                set(gui.menuTools,'visible','on');
                set(findobj(gui.menuTools,'label','Lock log'),'visible','off');
                set(findobj(gui.menuTools,'label','Refresh xPC data'),'visible','on');
                set(findobj(gui.menuTools,'label','Import xPC data from workspace'),'visible','on');
                set(findobj(gui.menuTools,'label','Export xPC data to workspace'),'visible','on');
                set(findobj(gui.menuTools,'label','Show log on list'),'checked',prf.menuShowLog);
                set(findobj(gui.menuTools,'label','Show order on list'),'checked',prf.menuShowOrder);
            otherwise
                set(gui.menuToolsStruct,'visible','off');
                set(gui.menuTools,'visible','on');
                set(findobj(gui.menuTools,'label','Lock log'),'visible','on','checked',prf.menuLockLog);
                set(findobj(gui.menuTools,'label','Refresh xPC data'),'visible','off');
                set(findobj(gui.menuTools,'label','Import xPC data from workspace'),'visible','off');
                set(findobj(gui.menuTools,'label','Export xPC data to workspace'),'visible','off');
                set(findobj(gui.menuTools,'label','Show log on list'),'checked',prf.menuShowLog);
                set(findobj(gui.menuTools,'label','Show order on list'),'checked',prf.menuShowOrder);
        end
        drawnow; pause(0.001);
    end
%
%
%% refreshMenuModes
    function refreshMenuModes
        if ~isfield(gui,'menuMode')
            gui.menuMode=uimenu(gui.frame,'label','Mode');
            uimenu(gui.menuMode,'label','Simulation','callback',@onModeChange)
            uimenu(gui.menuMode,'label','xPC','callback',@onModeChange)
            uimenu(gui.menuMode,'label','Structure','callback',@onModeChange)
        end
        %
        checkSim='off';
        checkXpc='off';
        checkStruct='off';
        switch prf.mode
            case 'xpc'
                checkXpc='on';
            case 'struct'
                checkStruct='on';
            otherwise %force to "case 'sim'"
                checkSim='on';
        end
        set(findobj(gui.menuMode,'label','Simulation'),'checked',checkSim);
        set(findobj(gui.menuMode,'label','xPC'),'checked',checkXpc);
        set(findobj(gui.menuMode,'label','Structure'),'checked',checkStruct);
    end
%
%
%% refreshMenuRightClick
    function refreshMenuRightClick
        if ~isfield(gui,'treeMenu') || ~isfield(gui,'listMenu')
            components={'tree','list'};
            for i=1:numel(components)
                gui.([components{i} 'Menu'])=javax.swing.JPopupMenu;
                menuItem=javax.swing.JMenuItem('Plot');
                set(handle(menuItem,'CallbackProperties'),'ActionPerformedCallback',{@onRightClickPlot,components{i},1});
                gui.([components{i} 'Menu']).add(menuItem);
                menuItem=javax.swing.JMenuItem('Plot on current');
                set(handle(menuItem,'CallbackProperties'),'ActionPerformedCallback',{@onRightClickPlot,components{i},2});
                gui.([components{i} 'Menu']).add(menuItem);
                menuItem=javax.swing.JMenuItem('Plot separately');
                set(handle(menuItem,'CallbackProperties'),'ActionPerformedCallback',{@onRightClickPlot,components{i},3});
                gui.([components{i} 'Menu']).add(menuItem);
                gui.([components{i} 'Menu']).addSeparator;
                menuItem=javax.swing.JMenuItem('Assign as x-axis');
                set(handle(menuItem,'CallbackProperties'),'ActionPerformedCallback',{@onRightClickAssignX,components{i}});
                gui.([components{i} 'Menu']).add(menuItem);
                menuItem=javax.swing.JMenuItem('Clear assignment');
                set(handle(menuItem,'CallbackProperties'),'ActionPerformedCallback',@onRightClickClearX);
                gui.([components{i} 'Menu']).add(menuItem);
                gui.([components{i} 'Menu']).addSeparator;
                menuItem=javax.swing.JMenuItem('Copy log');
                set(handle(menuItem,'CallbackProperties'),'ActionPerformedCallback',{@onRightClickCopyLog,components{i}});
                gui.([components{i} 'Menu']).add(menuItem);
                menuItem=javax.swing.JMenuItem('Define rule');
                set(handle(menuItem,'CallbackProperties'),'ActionPerformedCallback',{@onRightClickDefineRule,components{i}});
                gui.([components{i} 'Menu']).add(menuItem);
            end
        end
        if isempty(prf.xAxis)
            enableRightClickItem('Clear assignment',false);
        else
            enableRightClickItem('Clear assignment',true);
        end
        %
        % subfun
        function enableRightClickItem(menuItem,enableFlag)
            for ii=1:gui.treeMenu.getComponentCount;
                try %to escape from menu seperators
                    comp=gui.treeMenu.getComponent(ii-1);
                    if strcmpi(comp.getLabel,menuItem)
                        comp.setEnabled(enableFlag);
                    end
                end
            end
            for ii=1:gui.listMenu.getComponentCount;
                try %to escape from menu seperators
                    comp=gui.listMenu.getComponent(ii-1);
                    if strcmpi(comp.getLabel,menuItem)
                        comp.setEnabled(enableFlag);
                    end
                end
            end
        end
    end
%
%
%% refreshWaitBar
    function refreshWaitBar(text)
        if isempty(gui.jFrame)
            return
        end
        %
        if ~isfield(gui,'waitDialog')
            gui.waitDialog=javax.swing.JDialog(gui.jFrame,false);
            waitBar=javax.swing.JProgressBar;
            waitBar.setIndeterminate(true);
            gui.waitDialog.add(waitBar);
            gui.waitDialog.pack; %gui.waitDialog.setSize(java.awt.Dimension(80,gui.waitDialog.getHeight));
            gui.waitDialog.setResizable(false);
            gui.waitDialog.setDefaultCloseOperation(0);
            set(handle(gui.waitDialog,'CallbackProperties'),'KeyPressedCallback',@onKeyPress);
        end
        if nargin<1
            gui.waitDialog.setTitle('');
            gui.jFrame.enable;
            gui.waitDialog.dispose;
        else
            gui.waitDialog.setTitle(text);
            if ~gui.waitDialog.isVisible
                gui.waitDialog.setLocationRelativeTo(gui.jFrame);
                try
                    gui.jFrame.disable;
                end
                gui.waitDialog.show;
            end
        end
        %
        function onKeyPress(hObject,eventData)
            if (strcmp(eventData.getKeyChar,'c') && eventData.getModifiers==8) ...
                    || (eventData.getKeyCode==27)
                gui.waitDialog.setTitle('');
                try
                    gui.jFrame.enable;
                end
                gui.waitDialog.dispose;
            end
        end
    end
%
%
%% setPrf
    function setPrf
        try
            % frame position
            prf.framePos=get(gui.frame,'position');
            % tree states
            getTreeStates;
            % save
            if exist([prf.pwd '\plotlabPrf.mat'],'file')==2
                save([prf.pwd '\plotlabPrf.mat'],'prf');
            end
            saved=0;
            allPrf=getpref('plotlab');
            curFolder=regexp(prf.pwd,'(?<=.*\\)([^\\]*)$','match');
            for i=1:9
                if isfield(allPrf,['prf' num2str(i)])
                    try
                        folder=regexp(allPrf.(['prf' num2str(i)]).pwd,'(?<=.*\\)([^\\]*)$','match');
                        if ~saved && isequal(folder,curFolder)
                            setpref('plotlab',['prf' num2str(i)],prf);
                            saved=1;
                            break
                        end
                    catch
                        rmpref('plotlab',['prf' num2str(i)]);
                    end
                end
            end
            if ~saved
                times=[];
                for i=1:9
                    try
                        if ispref('plotlab',['prf' num2str(i)])
                            tempPrf=getpref('plotlab',['prf' num2str(i)]);
                            folder=regexp(tempPrf.pwd,'(?<=.*\\)([^\\]*)$','match');
                            if strcmp(folder,'MATLAB')
                                times(i)=now;
                            else
                                times(i)=tempPrf.time;
                            end
                        else
                            setpref('plotlab',['prf' num2str(i)],prf);
                            saved=1;
                            break
                        end
                    catch
                        times(i)=0;
                    end
                end
            end
            if ~saved
                i=find(times==min(times),1);
                setpref('plotlab',['prf' num2str(i)],prf);
            end
        end
    end
%
%
%% setTreeStates
    function setTreeStates
        try
            switch prf.mode
                case 'struct'
                    treeExpandPaths=prf.treeExpandPathsStruct;
                    treeSelections=prf.treeSelectionsStruct;
                case {'sim','xpc'}
                    treeExpandPaths=prf.treeExpandPaths;
                    treeSelections=prf.treeSelections;
            end
            i=0; path=gui.tree.getPathForRow(i);
            while ~isempty(path)
                if ~isempty(find(strcmp(treeExpandPaths,path.toString)==1,1));
                    gui.tree.expandPath(path);
                end
                if ~isempty(find(strcmp(treeSelections,path.toString)==1,1));
                    gui.tree.setSelectionRows([gui.tree.getSelectionRows;gui.tree.getRowForPath(path)]);
                end
                i=i+1; path=gui.tree.getPathForRow(i);
            end
            gui.tree.revalidate;
            gui.tree.repaint;
        end
    end
%
%
%% setUserData
    function setUserData(hObject,field,value)
        try
            userData=get(hObject,'userdata');
        catch
            userData=struct;
        end
        if ~isstruct(userData)
            userData=struct;
        end
        userData.(field)=value;
        set(hObject,'userdata',userData);
    end
%
%
%% showEditDialog
    function showEditDialog(mode,newEntry)
        if nargin<2
            newEntry={};
        end
        % create interface
        if ~isfield(gui,'dialog')
            gui.dialog.tableModel=javax.swing.table.DefaultTableModel;
            gui.dialog.table=javax.swing.JTable(gui.dialog.tableModel);
            gui.dialog.table.setAutoResizeMode(1);
            gui.dialog.tablePane=javax.swing.JScrollPane(gui.dialog.table);
            gui.dialog.frame=javax.swing.JDialog(gui.jFrame,false);
            gui.dialog.frame.setDefaultCloseOperation(0);
            set(handle(gui.dialog.frame,'CallbackProperties'),'WindowClosingCallback',@onDialogClose)
            set(handle(gui.dialog.table,'CallbackProperties'),'MousePressedCallback',{@onDialogKey,gui.dialog.table});
            set(handle(gui.dialog.tablePane,'CallbackProperties'),'MousePressedCallback',{@onDialogKey,gui.dialog.tablePane});
            gui.dialog.frame.add(gui.dialog.tablePane,'Center');
            menuItems={'Add','Remove','','Up','Down'};
            gui.dialog.menu=javax.swing.JPopupMenu;
            for i=1:numel(menuItems)
                if isempty(menuItems{i})
                    gui.dialog.menu.addSeparator;
                else
                    menuItem=javax.swing.JMenuItem(menuItems{i});
                    set(handle(menuItem,'CallbackProperties'),'ActionPerformedCallback',@onDialogMenu);
                    gui.dialog.menu.add(menuItem);
                end
            end
        end
        % show frame
        switch mode
            case 'converters'
                gui.dialog.frame.setTitle('Converters')
                gui.dialog.tableModel.setDataVector(prf.converters,{'Menu','Label','Factor / Equation'});
                gui.dialog.frame.setSize(400,250);
            case 'rules'
                gui.dialog.frame.setTitle('Rules')
                data=prf.rules;
                if ~isempty(newEntry)
                    data=[newEntry; data];
                end
                gui.dialog.tableModel.setDataVector(data,{'Timeseries / Log','Label(s)','Unit','Factor'});
                gui.dialog.frame.setSize(500,400);
            case 'rules struct'
                gui.dialog.frame.setTitle('Rules Struct')
                try
                    data=[logData.plotlabRulez.variableField,logData.plotlabRulez.label ...
                        ,logData.plotlabRulez.unit,logData.plotlabRulez.factor];
                catch
                    data={};
                end
                if ~isempty(newEntry)
                    data=[newEntry; data];
                end
                gui.dialog.tableModel.setDataVector(data,{'Field','Label','Unit','Factor'});
                gui.dialog.frame.setSize(500,500);
            case 'plot properties'
                gui.dialog.frame.setTitle('Plot properties')
                switch prf.mode
                    case {'sim','xpc'}
                        plotProperties=prf.plotProperties;
                    case 'struct'
                        plotProperties=prf.plotPropertiesStruct;
                    otherwise
                        return
                end
                for i=1:size(plotProperties,1)
                    if ~ischar(plotProperties{i,2})
                        try
                            plotProperties{i,2}=num2str(plotProperties{i,2});
                            if isempty(plotProperties{i,2})
                                plotProperties{i,2}='';
                            end
                        catch
                            plotProperties{i,2}='';
                        end
                    end
                end
                gui.dialog.tableModel.setDataVector(plotProperties,{'Property','Value'});
                gui.dialog.frame.setSize(300,150);
            otherwise
                return
        end
        gui.dialog.frame.setLocationRelativeTo(gui.jFrame);
        gui.dialog.frame.show;
        try
            gui.jFrame.disable;
        end
        %
        function onDialogClose(hObject,eventData)
            drawnow; pause(0.01);
            try
                switch lower(char(gui.dialog.frame.getTitle))
                    case 'converters'
                        newData={};
                        for ii=1:gui.dialog.tableModel.getRowCount
                            menulabel=strtrim(char(gui.dialog.tableModel.getValueAt(ii-1,0)));
                            label=strtrim(char(gui.dialog.tableModel.getValueAt(ii-1,1)));
                            factor=strtrim(char(gui.dialog.tableModel.getValueAt(ii-1,2)));
                            if ~isempty(label) && ~isempty(factor)
                                newData(end+1,1:3)={menulabel,label,factor};
                            end
                        end
                        if ~isequal(prf.converters,newData)
                            input=gui.optionPane.showOptionDialog(hObject,'Save changes?','',...
                                0,3,[],{'Yes','No'},{'Yes'});
                            drawnow; pause(0.01);
                            if input==0
                                prf.converters=newData;
                                refreshMenuFigure;
                            end
                        end
                    case 'rules'
                        newData={};
                        for ii=1:gui.dialog.tableModel.getRowCount
                            timeseries=strtrim(char(gui.dialog.tableModel.getValueAt(ii-1,0)));
                            labels=strtrim(char(gui.dialog.tableModel.getValueAt(ii-1,1)));
                            unit=strtrim(char(gui.dialog.tableModel.getValueAt(ii-1,2)));
                            factor=strtrim(char(gui.dialog.tableModel.getValueAt(ii-1,3)));
                            if ~isempty(timeseries)
                                newData(end+1,1:4)={timeseries,labels,unit,factor};
                            end
                        end
                        if ~isequal(prf.rules,newData)
                            input=gui.optionPane.showOptionDialog(hObject,'Save changes?','',...
                                0,3,[],{'Yes','No'},{'Yes'});
                            drawnow; pause(0.01);
                            if input==0
                                prf.rules=newData;
                                try
                                    gui.jFrame.enable;
                                end
                                try
                                    gui.dialog.frame.dispose;
                                end
                                assignin('base',prf.simLogBaseName,logData);
                                refreshInterface(prf.simLogBaseName); %force to use the same log
                            end
                        end
                    case 'rules struct'
                        newData={};
                        for ii=1:gui.dialog.tableModel.getRowCount
                            field=strtrim(char(gui.dialog.tableModel.getValueAt(ii-1,0)));
                            label=strtrim(char(gui.dialog.tableModel.getValueAt(ii-1,1)));
                            unit=strtrim(char(gui.dialog.tableModel.getValueAt(ii-1,2)));
                            factor=strtrim(char(gui.dialog.tableModel.getValueAt(ii-1,3)));
                            if ~isempty(field)
                                newData(end+1,1:4)={field,label,unit,factor};
                            end
                        end
                        try
                            oldData=[logData.plotlabRulez.variableField,logData.plotlabRulez.label ...
                                ,logData.plotlabRulez.unit,logData.plotlabRulez.factor];
                        catch
                            oldData={};
                        end
                        if ~isequal(oldData,newData)
                            input=gui.optionPane.showOptionDialog(hObject,'Save changes?','',...
                                0,3,[],{'Yes','No'},{'Yes'});
                            drawnow; pause(0.01);
                            if input==0
                                if isempty(newData)
                                    newData=cell(0,4);
                                end
                                logData.plotlabRulez.variableField=newData(:,1);
                                logData.plotlabRulez.label=newData(:,2);
                                logData.plotlabRulez.unit=newData(:,3);
                                logData.plotlabRulez.factor=newData(:,4);
                                % try
                                %     for ii=1:size(logInfo,1)
                                %         try
                                %             ruleInd=find(strcmp(regexprep(logInfo{ii,1},'^logData\.',''),logData.plotlabRulez.variableField),1);
                                %             if isempty(ruleInd)
                                %                 logInfo{ii,4}='';
                                %                 logInfo{ii,5}='';
                                %                 logInfo{ii,6}='';
                                %             else
                                %                 logInfo{ii,4}=logData.plotlabRulez.label{ruleInd};
                                %                 logInfo{ii,5}=logData.plotlabRulez.unit{ruleInd};
                                %                 logInfo{ii,6}=logData.plotlabRulez.factor{ruleInd};
                                %             end
                                %         end
                                %     end
                                % end
                                try
                                    gui.jFrame.enable;
                                end
                                try
                                    gui.dialog.frame.dispose;
                                end
                                assignin('base',prf.structLogBaseName,logData);
                                refreshInterface(prf.structLogBaseName); %force to use the same log
                            end
                        end
                    case 'plot properties'
                        newData={};
                        for ii=1:gui.dialog.tableModel.getRowCount
                            prop=strtrim(char(gui.dialog.tableModel.getValueAt(ii-1,0)));
                            val=strtrim(char(gui.dialog.tableModel.getValueAt(ii-1,1)));
                            newData(end+1,1:2)={prop,val};
                        end
                        newData{2,2}=str2num(newData{2,2});
                        newData{4,2}=str2num(newData{4,2});
                        switch prf.mode
                            case {'sim','xpc'}
                                plotProperties=prf.plotProperties;
                            case 'struct'
                                plotProperties=prf.plotPropertiesStruct;
                        end
                        if ~isequal(plotProperties,newData) && ...
                                isequal(newData(:,1).',{'LineStyle','LineWidth','Marker','MarkerSize'})
                            input=gui.optionPane.showOptionDialog(hObject,'Save changes?','',...
                                0,3,[],{'Yes','No'},{'Yes'});
                            drawnow; pause(0.01);
                            if input==0
                                switch prf.mode
                                    case {'sim','xpc'}
                                        prf.plotProperties=newData;
                                    case 'struct'
                                        prf.plotPropertiesStruct=newData;
                                end
                            end
                        end
                end
            end
            try
                gui.jFrame.enable;
            end
            try
                gui.dialog.frame.dispose;
            end
        end
        %
        function onDialogKey(hObject,eventData,parent)
            switch lower(char(gui.dialog.frame.getTitle))
                case {'converters','rules','rules struct'}
                    if eventData.isMetaDown
                        gui.dialog.menu.show(parent,eventData.getX,eventData.getY);
                        gui.dialog.menu.revalidate;
                        gui.dialog.menu.repaint;
                    end
            end
        end
        %
        function onDialogMenu(hObject,eventData)
            switch lower(char(hObject.getLabel.toString))
                case 'add'
                    gui.dialog.tableModel.addRow({'',''});
                case 'remove'
                    selection=sort(gui.dialog.table.getSelectedRows);
                    if ~isempty(selection)
                        for ii=numel(selection):-1:1
                            gui.dialog.tableModel.removeRow(selection(ii));
                        end
                    end
                case 'up'
                    selection=sort(gui.dialog.table.getSelectedRows);
                    if ~isempty(selection)
                        preNewPos=-1;
                        for ii=1:numel(selection)
                            exPos=selection(ii);
                            newPos=selection(ii)-1;
                            newPos=max(min(newPos,gui.dialog.tableModel.getRowCount-1),preNewPos+1);
                            gui.dialog.tableModel.moveRow(exPos,exPos,newPos);
                            gui.dialog.table.removeRowSelectionInterval(exPos,exPos);
                            gui.dialog.table.addRowSelectionInterval(newPos,newPos);
                            preNewPos=newPos;
                        end
                    end
                case 'down'
                    selection=sort(gui.dialog.table.getSelectedRows);
                    if ~isempty(selection)
                        preNewPos=gui.dialog.tableModel.getRowCount;
                        for ii=numel(selection):-1:1
                            exPos=selection(ii);
                            newPos=selection(ii)+1;
                            newPos=max(min(newPos,preNewPos-1),0);
                            gui.dialog.tableModel.moveRow(exPos,exPos,newPos);
                            gui.dialog.table.removeRowSelectionInterval(exPos,exPos);
                            gui.dialog.table.addRowSelectionInterval(newPos,newPos);
                            preNewPos=newPos;
                        end
                    end
            end
            gui.dialog.table.revalidate;
            gui.dialog.table.repaint;
        end
    end
%
%
%% showError
    function showError(msg,mode,errorFlag)
        if nargin<2 || ~strcmp(mode,'list')
            mode='dialog';
        end
        switch mode
            case 'list'
                if nargin>2 && errorFlag
                    msg=['<html><font color="#FF2222"><i>' msg '</i></font></html>'];
                else
                    msg=['<html><i>' msg '</i></html>'];
                end
                gui.listModel.addElement(msg);
                gui.list.revalidate;
                gui.list.repaint;
                gui.list.clearSelection;
                %gui.list.ensureIndexIsVisible(gui.listModel.getSize-1);
                drawnow; pause(0.001);
            case 'dialog'
                if ~isempty(regexp(msg,'\\n','once'))
                    msg=regexprep(msg,'\\n','\n');
                end
                if ~isempty(gui.jFrame) %buggy!
                    try
                        gui.optionPane.showMessageDialog(gui.jFrame,msg,'Error',0);
                        drawnow; pause(0.01);
                    catch
                        errDlg=errordlg(msg,'Error','replace');
                        set(errDlg,'WindowStyle','modal','closerequestfcn','delete(gcbf);')
                        uiwait(errDlg);
                        drawnow; pause(0.01);
                    end
                else
                    errDlg=errordlg(msg,'Error','replace');
                    set(errDlg,'WindowStyle','modal','closerequestfcn','delete(gcbf);')
                    uiwait(errDlg);
                    drawnow; pause(0.01);
                end
        end
    end
%
%
%% terminateFilterMode
    function terminateFilterMode
        try
            prf.filterMode='off';
            refreshMenuTools;
            hFig=findobj('type','figure','tag','filterFigure');
            if ~isempty(hFig)
                for i=1:numel(hFig)
                    state=uisuspend(hFig(i)); uirestore(state);
                end
                drawnow; pause(0.001);
                set(hFig,'tag','','pointer','arrow','closerequestfcn','closereq',...
                    'windowbuttondownfcn','','keypressfcn','');
                hLine1=findobj(hFig,'type','line','displayname','data');
                for i=1:numel(hLine1)
                    props={'displayname','linestyle','marker','markeredgecolor','markerfacecolor','color'};
                    for j=1:numel(props)
                        try
                            value=getUserData(hLine1(i),props{j});
                            set(hLine1(i),props{j},value)
                        end
                    end
                end
                hLine2=findobj(hFig,'type','line','displayname','spikes');
                delete(hLine2);
            end
        end
    end
%
%
%% updateFrameIcon
    function updateFrameIcon
        try
            if 1 || exist([prefdir '\plotterIcon.png'],'file')~=2
                a1=uint8([
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 1 1 1 1 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 1 1 1 1 1 1 1 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 1 1 1 1 1 1 1 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 1 1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 1 1 1 1 1 1 1 1 0 0 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    1 1 1 1 1 1 1 1 0 0 0 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    1 1 1 1 1 1 1 1 0 0 0 0 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    1 1 1 1 1 1 1 0 0 0 0 0 0 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    ]);
                b=uint8([
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 65 214 232 128 1
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 30 240 255 255 255 107
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 153 255 255 255 255 210
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 28 248 255 255 255 255 241
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 145 255 255 255 255 255 216
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 22 245 255 255 255 255 255 135
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 136 255 255 255 255 255 247 26
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 18 242 255 255 255 255 255 147 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 128 255 255 255 255 255 250 31 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 12 235 255 255 255 255 255 156 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 120 255 255 255 255 255 252 38 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 8 230 255 255 255 255 255 164 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 111 255 255 255 255 255 254 44 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5 225 255 255 255 255 255 173 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 103 255 255 255 255 255 255 52 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3 219 255 255 255 255 255 182 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 94 255 255 255 255 255 255 60 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 212 255 255 255 255 255 190 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 86 255 255 255 255 255 255 67 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3 88 124 44 0 0 0 0 0 0 0 0 0 1 207 255 255 255 255 255 199 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 163 255 255 248 66 0 0 0 0 0 0 0 0 76 255 255 255 255 255 255 76 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 65 255 255 255 255 224 10 0 0 0 0 0 0 0 199 255 255 255 255 255 207 1 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 187 255 255 255 255 255 131 0 0 0 0 0 0 68 255 255 255 255 255 255 84 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 49 254 255 255 255 255 255 249 38 0 0 0 0 0 191 255 255 255 255 255 215 2 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 173 255 255 255 255 255 255 255 185 0 0 0 0 57 255 255 255 255 255 255 93 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 39 253 255 255 255 255 255 255 255 255 79 0 0 0 183 255 255 255 255 255 221 4 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 158 255 255 255 255 255 255 255 255 255 225 11 0 49 254 255 255 255 255 255 102 0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 0 9 110 143 55 0 0 0 0 0 29 249 255 255 255 255 255 255 255 255 255 255 131 0 174 255 255 255 255 255 227 7 0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 1 185 255 255 251 71 0 0 0 0 144 255 255 255 255 255 255 255 255 255 255 255 247 80 254 255 255 255 255 255 110 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 83 255 255 255 255 224 10 0 0 20 244 255 255 255 255 255 204 255 255 255 255 255 255 251 255 255 255 255 255 233 10 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 0 204 255 255 255 255 255 128 0 0 130 255 255 255 255 255 247 25 190 255 255 255 255 255 255 255 255 255 255 255 119 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 73 255 255 255 255 255 255 246 32 11 236 255 255 255 255 255 147 0 43 250 255 255 255 255 255 255 255 255 255 237 13 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 0 195 255 255 255 255 255 255 255 170 116 255 255 255 255 255 250 32 0 0 142 255 255 255 255 255 255 255 255 255 128 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 62 255 255 255 255 255 255 255 255 255 240 255 255 255 255 255 162 0 0 0 14 230 255 255 255 255 255 255 255 242 18 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 0 184 255 255 255 255 255 255 255 255 255 255 255 255 255 255 254 44 0 0 0 0 92 255 255 255 255 255 255 255 135 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 49 254 255 255 255 255 255 255 255 255 255 255 255 255 255 255 175 0 0 0 0 0 0 191 255 255 255 255 255 247 25 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 0 173 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 57 0 0 0 0 0 0 43 250 255 255 255 255 144 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 42 253 255 255 255 255 255 197 255 255 255 255 255 255 255 255 189 0 0 0 0 0 0 0 0 140 255 255 255 242 26 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 0 162 255 255 255 255 255 232 13 208 255 255 255 255 255 255 255 69 0 0 0 0 0 0 0 0 7 157 251 222 68 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 33 251 255 255 255 255 255 120 0 63 255 255 255 255 255 255 203 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    0 151 255 255 255 255 255 240 15 0 0 169 255 255 255 255 255 82 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    26 247 255 255 255 255 255 131 0 0 0 30 245 255 255 255 212 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    136 255 255 255 255 255 244 20 0 0 0 0 90 250 255 236 51 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    218 255 255 255 255 255 141 0 0 0 0 0 0 29 69 16 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    244 255 255 255 255 248 27 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    212 255 255 255 255 152 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    108 255 255 255 244 31 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    1 133 240 215 68 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]);
                a(:,:,1)=a1*0; a(:,:,2)=a1*0; a(:,:,3)=a1*255; a=uint8(a);
                imwrite(a,[prefdir '\plotterIcon.png'],'png','alpha',b);
            end
            drawnow; pause(0.001);
            icon=javax.swing.ImageIcon([prefdir '\plotterIcon.png']);
            try
                d=datevec(now);
                if d(2)==12 && exist('\\cezeri\KULLANICILAR\AAKSU\Temp\santa.png','file')==2
                    icon=javax.swing.ImageIcon('\\cezeri\KULLANICILAR\AAKSU\Temp\santa.png');
                end
            end
            try
                mde=com.mathworks.mde.desk.MLDesktop.getInstance;
                jFrame=mde.getClient(prf.frameName);
                jFrame.setClientIcon(icon);
            catch
                warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
                jFrame=get(gui.frame,'javaframe');
                jFrame.setFigureIcon(icon);
            end
        end
        try
            % fix figures icon bug!
            hFig=figure('numbertitle','off','name','Temporary plotlab figure','visible','off');
            mde=com.mathworks.mde.desk.MLDesktop.getInstance;
            icon=javax.swing.ImageIcon(mde.getMainFrame.getIconImage);
            try
                drawnow; pause(0.001);
                jFrame=mde.getClient('Temporary plotlab figure');
                jFrame.setClientIcon(icon);
            catch
                warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
                jFrame=get(hFig,'javaframe');
                jFrame.setFigureIcon(icon);
            end
        end
        delete(hFig);
    end
%
%
end
%
%
% subfuns
function protectedNum=protectedEval(protectedStr)
try
    protectedNum=eval(protectedStr);
catch
    protectedNum=[];
end
end
%
function protectedOutputData=protectedEvalXY(protectedStr,x,y)
protectedOutputData=[];
try
    protectedOutputData=eval(protectedStr);
catch
    try
        eval([protectedStr ';']);
        protectedOutputData=data;
    catch
        try
            eval(protectedStr);
            protectedOutputData=data;
        end
    end
end
end
%
%
%#ok<*INUSD>
%#ok<*INUSL>
%#ok<*TRYNC>
%#ok<*CTCH>
%#ok<*ST2NM>
%#ok<*ASGLU>
%#ok<*AGROW>
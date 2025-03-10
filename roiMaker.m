% ROIMAKER 
% 
% roiMaker is a simple gui and set of processes for making various ROIs in
% imaging data. 
%
% No Documentation (yet)
%
%
% V1.3
% 
% 03/01/2018
% Questions: cdeister@brown.edu
% Code: Chris Deister & Jakob Voigts (mfactor smoothing code! & speedy XCorr)
% Global XCorr Segmentation Idea: Stephan Junek et al., 2009 & Spencer Smith



% ************************************************
% ***************** Creator Functions ************
% ************************************************

function varargout = roiMaker(varargin)

    % Generic Matlab GUI Init Code
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @roiMaker_OpeningFcn, ...
                       'gui_OutputFcn',  @roiMaker_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
function roiMaker_OpeningFcn(hObject, eventdata, handles, varargin)

    
    handles.output = hObject;
    vars = evalin('base','who');
    set(handles.workspaceVarBox,'String',vars)
    try 
        set(handles.workspaceVarBox,'Value',1)
    catch
    end
    g=evalin('base','exist(''neuropilRoiCounter'')');
    if g
        set(handles.neuropilAlertString,'String','');
    else
        set(handles.neuropilAlertString,'ForegroundColor',[0 0 0]);
    end

    assignin('base','lastMax',-1);
    evalin('base','metaData.lastMax=lastMax;,clear lastMax');


    if strcmp(computer,'MACI64') || strcmp(computer,'GLNXA64') || strcmp(computer,'MACA64')
        macHeaderSize=12;
        macFontSize=11;
        macUIDecSize=10;

    elseif strcmp(computer,'PCWIN64') 
        macHeaderSize=8;
        macFontSize=7;
        macUIDecSize=6;
    else
    end

    uiElements={'somaButton','redSomaButton','dendriteButton','axonButton',...
    'boutonButton','vesselButton','loadMeanProjectionButton','deleteROIButton',...
    'roiSelector','somaticRoisDisplayToggle','redSomaticRoisDisplayToggle',...
    'dendriticRoisDisplayToggle','axonalRoisDisplayToggle','boutonRoisDisplayToggle',...
    'neuropilRoisDisplayToggle','vesselRoisDisplayToggle','lowCutSlider',...
    'highCutSlider','lowCutEntry','highCutEntry','makeNeuropilMasks',...
    'neuropilPixelSpreadEntry','workspaceVarBox','refreshVarListButton',...
    'meanProjectButton','stdevProjectionButton','maxProjectionButton',...
    'getGXcorButton','gXCorImageCountEntry','gXCorSmoothToggle','playStackMovButton',...
    'pasueMovieButton','localXCorButton','roiThresholdEntry','pcaButton',...
    'colormapTextEntry','frameSlider','frameTextEntry','addToSomasButton',...
    'addToDendritesButton','addToBoutonsButton','nnmfButton','featureCountEntry',...
    'medianFilterToggle','wienerFilterToggle','importerButton','extractorButton',...
    'cMaskToggle','curImageToMaskButton','segmentMaskBtn','autoMaskBtn','binarySensEntry',...
    'minRoiEntry','manROIBtn','roiTypeMenu','deleteWSVar','binaryThrValEntry','cutByBtn',...
    'imageCutEntry','deDupeRoisBtn','clusterMaskBtn','maxClusterEntry','manROIBtn_Generic',...
    'overlayIndRoiToggle','feedbackString','neuropilAlertString','saveImageBtn','normSelection',...
    'yCropEntry','xCropEntry'};

    for n=1:numel(uiElements)
        eval(['handles.' uiElements{n} '.FontSize=macFontSize;'])
    end
    
    decUIElements={'text14','text12','text13','text16','text17','text19',...
    'text10','text6','text7','text8','imageWindow','text21','text22',...
    'text25','text26'};
    for n=1:numel(decUIElements)
        eval(['handles.' decUIElements{n} '.FontSize=macUIDecSize;'])
    end
    
    titleUIElements={'uipanel3','uipanel2','uipanel6','uipanel8','uipanel4',...
    'uipanel9','uipanel10','uipanel3','NeuropilText','text23','uipanel11','uipanel5'};
    for n=1:numel(titleUIElements)
        eval(['handles.' titleUIElements{n} '.FontSize=macHeaderSize;'])
    end


    logSelection(hObject,eventdata,handles)
    guidata(hObject, handles);
function varargout = roiMaker_OutputFcn(hObject, eventdata, handles) 

    varargout{1} = handles.output;
    
% ************************************************
% ***************** General Functions ************
% ************************************************

function [returnTypeStrings,typeAllColor]=returnAllTypes(hObject,eventdata,handles)
    
    % set all known ROI types here
    returnTypeStrings={'somatic','redSomatic','dendritic','axonal',...
    'bouton','vessel','neuropil'};
    typeAllColor={[0,0.8,0.3],[1,0,0],[0,0,1],[1,0,1],[1,1,0],...
    [0.7,0.3,0],[0.4,0.4,0.4]};
function addROIsFromMask(hObject,eventdata,handles,mask)

    sL=get(handles.roiTypeMenu,'String');
    sV=get(handles.roiTypeMenu,'Value');
    roiTypeSelected=sL{sV};
    assignin('base','roiSelectString',roiTypeSelected)

    g=evalin('base',['exist(''' roiTypeSelected 'RoiCounter' ''');']);

    if g==1
        h=evalin('base',[roiTypeSelected 'RoiCounter']);
        r=evalin('base',[roiTypeSelected 'ROIs']);
        c=evalin('base',[roiTypeSelected 'ROICenters']);
        b=evalin('base',[roiTypeSelected 'ROIBoundaries']);
        pl=evalin('base',[roiTypeSelected 'ROI_PixelLists']);
        h=h+1;
        
        r{h}=mask;
        b{h}=bwboundaries(mask);
        c{h}=regionprops(mask,'Centroid');
        pl{h}=regionprops(mask,'PixelList');
        
        
        assignin('base',[roiTypeSelected 'ROIs'],r)
        assignin('base',[roiTypeSelected 'ROICenters'],c)
        assignin('base',[roiTypeSelected 'ROIBoundaries'],b)
        assignin('base',[roiTypeSelected 'RoiCounter'],h)
        assignin('base',[roiTypeSelected 'ROI_PixelLists'],pl)
        
    else
        h=1;
        assignin('base',[roiTypeSelected 'ROIs'],{mask})
        assignin('base',[roiTypeSelected 'ROICenters'],{regionprops(mask,'Centroid')})
        assignin('base',[roiTypeSelected 'ROI_PixelLists'],{regionprops(mask,'PixelList')})
        assignin('base',[roiTypeSelected 'ROIBoundaries'],{bwboundaries(mask)})
        assignin('base',[roiTypeSelected 'RoiCounter'],h)
    end
    roisDisplayToggle(hObject,eventdata,handles,1)
    refreshVarListButton_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);
function [wsObj wsClass wsSize]=getWSVar(hObject, eventdata, handles)
    
    selections = get(handles.workspaceVarBox,'String');
    selectionsIndex = get(handles.workspaceVarBox,'Value');
    wsObj=evalin('base',selections{selectionsIndex});
    wsSize=evalin('base',['size(' selections{selectionsIndex} ');']);
    wsClass=class(wsObj);
    assignin('base','lastVar',selections{selectionsIndex})
    % assignin('base','lastVarSize',size(wsObj))
    evalin('base','self.lastVar=lastVar;,clear lastVar')
    % evalin('base','self.lastVarSize=lastVarSize;,clear lastVarSize')

function [curFrame]=trackFrame(hObject, eventdata, handles)
    curFrame=fix(str2double(get(handles.frameTextEntry,'String')));        
    assignin('base','currentFrame',curFrame)
    evalin('base','metaData.currentFrame=currentFrame;,clear currentFrame');


function plotSomeROIs(hObject,eventdata,handles,plotRemainder,roisToPlot)
    
    if numel(roisToPlot)
        axes(handles.imageWindow)
        a=gcf;
        try
            cI=a.CurrentAxes.Children(end).CData;
            loadMeanProjectionButton_Callback(hObject,eventdata,handles,cI);
        catch
            loadMeanProjectionButton_Callback(hObject,eventdata,handles);
        end
        hold all
        if plotRemainder
            roisDisplayToggle(hObject,eventdata,handles,1)
            hold all
        else
        end
        
        for n=1:numel(roisToPlot)    
            stringSplit=strsplit(roisToPlot{n},'_');
            typeString=stringSplit{1};
            roiNumber=fix(str2double(stringSplit{2}));
            c{n}=evalin('base',[typeString 'ROICenters([' num2str(roiNumber) ']);']);
            b{n}=evalin('base',[typeString 'ROIBoundaries([' num2str(roiNumber) ']);']);
        end
        plotAnROI(hObject,eventdata,handles,c,b)
        hold off
        refreshVarListButton_Callback(hObject, eventdata, handles);
        guidata(hObject, handles);
    else
    end
function plotAnROI(hObject,eventdata,handles,roiCenters,roiBoundaries,boundaryColors)
    if nargin==5
        boundaryColors=repmat({[1 0 0]},1,numel(roiCenters));        
    else
    end
    if numel(roiCenters)>0
        for n=1:numel(roiCenters)
            c=roiCenters{n};
            b=roiBoundaries{n};
            for k=1:numel(c)
                plot(b{1,n}{k,1}(:,2),b{1,n}{k,1}(:,1),'Color',boundaryColors{n},'LineWidth',2.5)
            end
        end
    else
    end
function freehandROI(hObject,eventdata,handles,typeString)

    g=evalin('base',['exist(' '''' typeString ''  'RoiCounter'')']);
    if g==1
        h=evalin('base',[typeString 'RoiCounter']);
        r=evalin('base',[typeString 'ROIs']);
        c=evalin('base',[typeString 'ROICenters']);
        b=evalin('base',[typeString 'ROIBoundaries']);
        pl=evalin('base',[typeString 'ROI_PixelLists']);
        
        h=h+1;
        a=imfreehand;
        mask=a.createMask;
        
        
        r{h}=mask;
        b{h}=bwboundaries(mask);
        c{h}=regionprops(mask,'Centroid');
        pl{h}=regionprops(mask,'PixelList');
        
        
        assignin('base',[typeString 'ROIs'],r)
        assignin('base',[typeString 'ROICenters'],c)
        assignin('base',[typeString 'ROIBoundaries'],b)
        assignin('base',[typeString 'RoiCounter'],h)
        assignin('base',[typeString 'ROI_PixelLists'],pl)
        assignin('base','roiSelectString',typeString)
        
    else
        h=1;
        a=imfreehand;
        mask=a.createMask;
        
        assignin('base',[typeString 'ROIs'],{mask})
        assignin('base',[typeString 'ROICenters'],{regionprops(mask,'Centroid')})
        assignin('base',[typeString 'ROIBoundaries'],{bwboundaries(mask)})
        assignin('base',[typeString 'RoiCounter'],h)
        assignin('base',[typeString 'ROI_PixelLists'],{regionprops(mask,'PixelList')})
        assignin('base','roiSelectString',typeString)
       
    end
    roisDisplayToggle(hObject,eventdata,handles,1)
    refreshVarListButton_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);
function roisDisplayToggle(hObject,eventdata,handles,justUpdate,useTxtLabels)

    if nargin==3
        justUpdate=0;
        useTxtLabels=1;
    end

    if nargin == 4
        useTxtLabels=1;
    end
    % if justUpdate~=2
        % if you don't want to update clear all and start again
        % note no hold
        if justUpdate==0
            loadMeanProjectionButton_Callback(hObject, eventdata, handles)
        else
        end
    
        % this executes for all
        axes(handles.imageWindow)
        [allTypes,allColors]=returnAllTypes(hObject,eventdata,handles);
        % reset the box
        set(handles.roiSelector,'String','');
        guidata(hObject, handles);

        % for 'fancy' mask stuff
        axes(handles.imageWindow);
        g1=getframe;
        % ogImage=frame2im(g1);
        % assignin('base','g1',g1)
        % assignin('base','ogImage',ogImage)

        % see who is (still) on
        for n=1:numel(allTypes)
            whoIsOn(n)=eval(['get(handles.' allTypes{n} 'RoisDisplayToggle, ''Value'');']);
        end
        whoIsOn=find(whoIsOn==1);

        roiCounter=0;
        for rI=1:numel(whoIsOn)
            typeString=allTypes{whoIsOn(rI)};
            g=evalin('base',['exist(''' typeString 'ROICenters'');']);
            if g==1
                c=evalin('base',[typeString 'ROICenters']);
                b=evalin('base',[typeString 'ROIBoundaries']);
                if numel(c) ~= 0
                    plotRange=1:numel(c);
                    allCount=numel(c);

                    for n=1:allCount
                        roiCounter=roiCounter+1;
                        roisList{roiCounter}=[typeString '_' num2str(n)];
                    end

                    cVal=get(handles.roiSelector,'Value');
                    set(handles.roiSelector, 'String', '');
                    set(handles.roiSelector,'String',roisList);
                    if cVal~=1
                        set(handles.roiSelector,'Value',cVal)
                    else
                        set(handles.roiSelector,'Value',1)
                    end


                    % Plot
                    if strcmp(get(handles.colormapTextEntry,'String'),'jet')
                        outColor='k';
                        txtColor=[0 0 0];
                    else
                        outColor=allColors{whoIsOn(rI)};
                        txtColor=allColors{whoIsOn(rI)};
                    end
                    txtColor=[1 1 1];
                    hold all
                    for n=1:numel(plotRange)            
                        for k=1:numel(c{1,n})
                            plot(b{1,n}{k,1}(:,2),b{1,n}{k,1}(:,1),'Color',...
                                outColor,'LineWidth',2)
                            if useTxtLabels
                                text(c{1,n}(k).Centroid(1)-1, c{1,n}(k).Centroid(2),...
                                    num2str(plotRange(n)),'FontSize',14,'FontWeight','Bold','Color',txtColor);
                            else
                            end
                        end
                    end
                    hold off
                else
                end
            else
            end
        end
        % g2=getframe;
        % ovImage=frame2im(g2);
        % assignin('base','g2',g2)
        % assignin('base','ovImage',ovImage)
        
        refreshVarListButton_Callback(hObject, eventdata, handles);
        guidata(hObject, handles);
function roiSelection(hObject,eventdata,handles)

    cI=evalin('base','metaData.currentImage');
    axes(handles.imageWindow)
    loadMeanProjection(hObject,eventdata,handles,cI);
   
    [allTypes,allColors]=returnAllTypes(hObject,eventdata,handles);

    for n=1:numel(allTypes)
        whoIsOn(n)=eval(['get(handles.' allTypes{n} 'RoisDisplayToggle, ''Value'');']);
    end

    whoIsOn=find(whoIsOn==1);

    if numel(whoIsOn)==0
        set(handles.roiSelector,'String','');
    else
    end

    roiCounter=0;
    lastTypeNumber=0;
    for rI=1:numel(whoIsOn)
        typeString=allTypes{whoIsOn(rI)};
        g=evalin('base',['exist(''' typeString 'RoiCounter'');']);
        if g==1
            if numel(indRange)==0
                c=evalin('base',[typeString 'ROICenters']);
                b=evalin('base',[typeString 'ROIBoundaries']);
                plotRange=1:numel(c);
                allCount=numel(c);
            else
                plotRange=indRange;
                
            end

            c=evalin('base',[typeString 'ROICenters([' num2str(plotRange) '])']);
            b=evalin('base',[typeString 'ROIBoundaries([' num2str(plotRange) '])']);
            

            % Populate the box:
            if justUpdate==0
                for n=1:allCount                    
                    roisList{n}=[typeString '_' num2str(n)];
                end

                set(handles.roiSelector, 'String', '');
                set(handles.roiSelector,'String',roisList);
                set(handles.roiSelector,'Value',plotRange(end))
            else
            end

            % Plot
            if strcmp(get(handles.colormapTextEntry,'String'),'jet')
                outColor='k';
                txtColor=[0 0 0];
            else
                outColor=allColors{whoIsOn(rI)};
                txtColor=allColors{whoIsOn(rI)};
            end

            
        else
        end
    end

        
    refreshVarListButton_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);
    
% ************************************************
% **************** Callback Functions ************
% ************************************************


function somaButton_Callback(hObject, eventdata, handles)

    freehandROI(hObject,eventdata,handles,'somatic')
function redSomaButton_Callback(hObject, eventdata, handles)
    
    freehandROI(hObject,eventdata,handles,'redSomatic')
function dendriteButton_Callback(hObject, eventdata, handles)
    
    freehandROI(hObject,eventdata,handles,'dendritic')
function axonButton_Callback(hObject, eventdata, handles)

    freehandROI(hObject,eventdata,handles,'axonal')
function boutonButton_Callback(hObject, eventdata, handles)
    
    freehandROI(hObject,eventdata,handles,'bouton')
function vesselButton_Callback(hObject, eventdata, handles)

    freehandROI(hObject,eventdata,handles,'vessel')

function loadMeanProjectionButton_Callback(hObject,eventdata,handles,defImage)
    % a) update w/b sliders if image type changes substantially.
    % b) update image count slider to 1 if not a stack.
    % c) update image count slider for a stack only if stack changed.


    
    % assume we will update the pixel histogram, and that the image is new.
    % we test later
    updateHist=1;
    imTypeChange=1;


    % this will optionally take an argument of a specific image to plot.
    if nargin==3
        [imageP imClass imSize]=getWSVar(hObject, eventdata, handles);
        % lastVar=evalin('base','metaData.lastVar;');
    else
        imageP=defImage;
        imClass=class(defImage);
        imSize=size(imageP);
    end

    

    % (a) should we change the slider bounds?
    tMxVl=fix(max(max(imageP(:,:,1))));
    tMxVlSc=fix(0.2*tMxVl);
    maxVal=tMxVl+tMxVlSc;
    if maxVal<=0
        maxVal=1;
    else
    end
    maxVal=double(maxVal);

    try 
        lastMax=evalin('base','metaData.lastMax;');
        if lastMax==maxVal
            imTypeChange=0;
        else
        end
    catch
        assignin('base','lastMax',maxVal);
        evalin('base','metaData.lastMax=lastMax;,clear lastMax');
        imTypeChange=1;
    end

    assignin('base','lastMax',maxVal);
    evalin('base','metaData.lastMax=lastMax;,clear lastMax');

    if numel(imSize)==2
        stackInd=1;
        stackNum=1;
        frm_sliderMin = 0;
        frm_sliderMax = 1;
    elseif numel(imSize)==3
        stackNum=imSize(3);
        stackInd=fix(str2num(get(handles.frameTextEntry,'String')));
        if stackInd>stackNum
            stackInd=1;
        else
        end
        frm_sliderMin = 1;
        frm_sliderMax = fix(stackNum);
    else
    end

    set(handles.frameTextEntry,'String',num2str(stackInd));
    frm_sliderStep = [1, 1] / (frm_sliderMax - frm_sliderMin); % major and minor steps of 1
    set(handles.frameSlider, 'Min', frm_sliderMin);
    set(handles.frameSlider, 'Max', frm_sliderMax);
    set(handles.frameSlider, 'SliderStep', frm_sliderStep);
    set(handles.frameSlider, 'Value', stackInd); % set to beginning of sequence
    imageP=imageP(:,:,stackInd);

    % change w/b sliders?
    if imTypeChange==1

        set(handles.yCropEntry,'String',['1' ':' num2str(imSize(1))]);
        set(handles.xCropEntry,'String',['1' ':' num2str(imSize(2))]);
        
        stackInd=1;

        set(handles.highCutSlider,'Max',maxVal);
        set(handles.highCutSlider,'Min',0);
        set(handles.highCutSlider,'Value',maxVal);
        
        set(handles.lowCutSlider,'Max',maxVal);
        set(handles.lowCutSlider,'Min',0);
        set(handles.lowCutSlider,'Value',0);

        set(handles.highCutEntry,'String',num2str(maxVal));
        set(handles.lowCutEntry,'String','0');
        
        sliderStep=[1, 1] / (maxVal- 0);
        if sliderStep(1)==1
            sliderStep(1)=0.05;
            sliderStep(2)=0.05;
        else
        end
    else
    end
    
    a = str2double(get(handles.lowCutEntry,'String'));
    b = str2double(get(handles.highCutEntry,'String'));
    
    medFilter=get(handles.medianFilterToggle,'Value');
    if medFilter==1
        imageP=medfilt2(imageP);
    else
    end

    wienerFilter=get(handles.wienerFilterToggle,'Value');
    if wienerFilter==1
        imageP=wiener2(imageP);
    else
    end

    pMO=get(handles.overlayIndRoiToggle,'Value');
    % override if there is no mask
    mE=evalin('base','exist(''cMask'')');
    if mE==0
        pMO=0;
    else
    end

    if pMO
        cMask=evalin('base','cMask;');
        imageP=double(imageP).*cMask;
    else
    end





    sL=get(handles.colormapTextEntry,'String');
    sV=get(handles.colormapTextEntry,'Value');
    cMap=sL{sV};


    axes(handles.imageWindow);
    pImg=imshow(imageP,'DisplayRange',[a b]);
    colormap(gca,cMap)


    if updateHist
        if numel(find(double(imageP)>0))>2
            axes(handles.imageHistogram);
            nhist(nonzeros(double(imageP)),'box','maxbins',40);
            xlim([0 b])
            hold all
            plot([a a],[0 20000],'r-')
            plot([b b],[0 20000],'b-')
            hold off
        else
            axes(handles.imageHistogram);
            nhist(zeros(80,1),'box','maxbins',40);
            xlim([0 b])
            hold all
            plot([a a],[0 20000],'r-')
            plot([b b],[0 20000],'b-')
            hold off
        end
    else
    end
    
    roisDisplayToggle(hObject,eventdata,handles,1)
    refreshVarListButton_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);


function deleteROIButton_Callback(hObject, eventdata, handles)

    boxNum=get(handles.roiSelector,'Value');
    boxStrings=get(handles.roiSelector,'String');
    specifiedString=boxStrings{boxNum};

    stringSplit=strsplit(specifiedString,'_');


    typeString=stringSplit{1};
    roiNumber=fix(str2double(stringSplit{2}));
    deleteROI(roiNumber,{typeString});

    roisDisplayToggle(hObject, eventdata, handles,1)

    % alert the user their neuropil masks will be out of sync.
    g=evalin('base','exist(''neuropilRoiCounter'')');
    if g 
        set(handles.neuropilAlertString,'String','regenerate neuropil masks -->',...
            'ForegroundColor',[1 0 0]);
    else
        set(handles.neuropilAlertString,'ForegroundColor',[0 0 0]);
    end
    if boxNum>1
        set(handles.roiSelector,'Value',boxNum-1);
    else
        
        set(handles.roiSelector,'Value',1);
    end

    roisDisplayToggle(hObject,eventdata,handles)
    refreshVarListButton_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);
function roiSelector_Callback(hObject,eventdata,handles)

    boxNum=get(handles.roiSelector,'Value');
    boxStrings=get(handles.roiSelector,'String');

    if numel(boxNum)>0
        for n=1:numel(boxNum)
            specifiedStrings{n}=boxStrings{boxNum};
        end
        plotSomeROIs(hObject,eventdata,handles,1,specifiedStrings)
    else
    end 
    
    refreshVarListButton_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);

% *******> these all just call roiSelector
function somaticRoisDisplayToggle_Callback(hObject, eventdata, handles)

    % cState=get(handles.somaticRoisDisplayToggle,'Value');
    roisDisplayToggle(hObject, eventdata, handles)
function redSomaticRoisDisplayToggle_Callback(hObject, eventdata, handles)
    
    roisDisplayToggle(hObject, eventdata, handles)
function dendriticRoisDisplayToggle_Callback(hObject, eventdata, handles)
    
    roisDisplayToggle(hObject, eventdata, handles)
function axonalRoisDisplayToggle_Callback(hObject, eventdata, handles)
    
    roisDisplayToggle(hObject, eventdata, handles)
function boutonRoisDisplayToggle_Callback(hObject, eventdata, handles)
    
    roisDisplayToggle(hObject, eventdata, handles)
function neuropilRoisDisplayToggle_Callback(hObject, eventdata, handles)
    
    roisDisplayToggle(hObject, eventdata, handles)
function vesselRoisDisplayToggle_Callback(hObject, eventdata, handles)
    
    roisDisplayToggle(hObject, eventdata, handles)

function lowCutSlider_Callback(hObject, eventdata, handles)

    sliderValue = get(handles.lowCutSlider,'Value');
    highSet = get(handles.highCutSlider,'Value');
    if sliderValue>=highSet
        sliderValue=highSet-0.1;
    else
    end
    set(handles.lowCutEntry,'String', num2str(sliderValue));
    guidata(hObject, handles); 

    loadMeanProjectionButton_Callback(hObject,eventdata, handles);
function highCutSlider_Callback(hObject, eventdata, handles)

    sliderValue = get(handles.highCutSlider,'Value');
    lowSet = get(handles.lowCutSlider,'Value');
    if sliderValue<=lowSet
        sliderValue=lowSet+0.1;
    else
    end
    set(handles.highCutEntry,'String', num2str(sliderValue));
    guidata(hObject, handles);

    loadMeanProjectionButton_Callback(hObject,eventdata, handles);
function lowCutEntry_Callback(hObject, eventdata, handles)

    input = str2num(get(hObject,'String'));
    highSet = str2num(get(handles.highCutEntry,'String'));
    if input>=highSet
        input=highSet-0.1;
    else
    end

    %checks to see if input is empty. if so, default input1_editText to zero
    if (isempty(input))
         set(hObject,'String','0')
    end


    set(handles.lowCutSlider,'Value',input);
    guidata(hObject, handles);
    lowCutSlider_Callback(hObject, eventdata, handles)
function highCutEntry_Callback(hObject, eventdata, handles)

    input = str2num(get(hObject,'String'));
    lowSet = str2num(get(handles.lowCutEntry,'String'));
    if input<=lowSet
        input=lowSet+0.1;
    else
    end

    %checks to see if input is empty. if so, default input1_editText to zero
    if (isempty(input))
         set(hObject,'String','1')
    end

    set(handles.highCutSlider,'Value',input);
    guidata(hObject, handles);
    highCutSlider_Callback(hObject, eventdata, handles)

function makeNeuropilMasks_Callback(hObject, eventdata, handles)


    % Handle Neuropil ROIs

    % because our somas can be irregular we need to smooth the boundaries.

    % parameters
    tempImage=evalin('base','somaticROIs{1,1}');
    sR=evalin('base','somaticROIs');


    npSpredPx = str2double(get(handles.neuropilPixelSpreadEntry,'String'));
    somaClosePx=10;
    somaBoundaryPx=6; %todo: should be entered by user.


    % todo: a possible error case if an image has fewer than 30 pixels.

    smoothSomasMask=zeros(size(tempImage)); % this will be an all containing mask we use to exclude from neuropils.
    smoothNeuropilsMask=zeros(size(tempImage)); 

    neuropilRoiCounter=0;
    set(handles.feedbackString,'String','making neuropil masks ...')
    pause(0.000000001);
    guidata(hObject, handles);
    % First make an array of individual smoothed somatic rois and build on the all inclusive image.
    for n=1:numel(sR)
        neuropilROIs{1,n}=imdilate(imclose(sR{1,n},strel('disk',somaClosePx)),strel('disk',somaBoundaryPx));
        smoothSomasMask=smoothSomasMask+neuropilROIs{1,n};
        neuropilRoiCounter=neuropilRoiCounter+1;
    end

    % normalize because after dialting each cell there will be more overlap.
    smoothSomasMask=smoothSomasMask>0;
    assignin('base','flatMasks_smoothSomas',smoothSomasMask)


    for n=1:neuropilRoiCounter
        neuropilROIs{1,n}=imdilate(neuropilROIs{1,n},strel('disk',npSpredPx));
        % Find and Subtract Overlap Between a Particular Neuropil Mask and ROI mask
        neuropilROIs{1,n}=neuropilROIs{1,n}-smoothSomasMask;
        % this will give 0's where there is overlap, 1's were there is none and -1 where there was no difference
        neuropilROIs{1,n}=neuropilROIs{1,n}>0;
        smoothNeuropilsMask=smoothNeuropilsMask+neuropilROIs{1,n};
        neuropilROIBoundaries{1,n}=bwboundaries(neuropilROIs{1,n});
        neuropilROICenters{1,n}=regionprops(neuropilROIs{1,n},'Centroid');
        neuropilROI_PixelLists{1,n}=regionprops(neuropilROIs{1,n},'PixelList');
    %     neuropilROI_PixelLists{1,n}=neuropilROI_PixelLists{1,n}.PixelList;
    end

    smoothNeuropilsMask=smoothNeuropilsMask>0;
    assignin('base','flatMasks_neuropilRings',smoothNeuropilsMask)


    assignin('base','neuropilROIs',neuropilROIs)
    assignin('base','neuropilROI_PixelLists',neuropilROI_PixelLists)
    assignin('base','neuropilROIBoundaries',neuropilROIBoundaries)
    assignin('base','neuropilRoiCounter',neuropilRoiCounter)
    assignin('base','neuropilROICenters',neuropilROICenters)

    set(handles.neuropilAlertString,'String','finished making neuropil masks','ForegroundColor',[0 0 0]);
    set(handles.feedbackString,'String','finished neuropil masks')
    pause(0.000000001);
    guidata(hObject, handles);
function neuropilPixelSpreadEntry_Callback(hObject, eventdata, handles)

    guidata(hObject, handles);

function workspaceVarBox_Callback(hObject, eventdata, handles)
    
    logSelection(hObject,eventdata,handles)
    guidata(hObject, handles);
function logSelection(hObject,eventdata,handles)
    try
        pVal=get(handles.workspaceVarBox,'Value');
        pSel=get(handles.workspaceVarBox,'String');
        pVar=pSel{pVal};
        assignin('base','pVal',pVal)
        assignin('base','pSel',pSel)
        assignin('base','pVar',pVar)
        evalin('base','metaData.pVal=pVal;,clear pVal')
        evalin('base','metaData.pSel=pSel;,clear pSel')
        evalin('base','metaData.pVar=pVar;,clear pVar')
        guidata(hObject, handles);
    catch
    end
function refreshVarListButton_Callback(hObject, eventdata, handles)
    % this is kind of weird looking, but I want it to be foolproof.
    % i need to make sure if the user adds or deletes something
    % that what they selected in the browser is still selected

    % a) assume nothing is different, but get current selection
    % varChange=0;
    % % b) get the current selection
    % try
    %     cVal=get(handles.workspaceVarBox,'Value');
    %     cSel=get(handles.workspaceVarBox,'String');
    %     cVar=pSel{pVal};
    % catch
    %     cVar='';
    % end

    % c) get last known selection
    try
        pVal=evalin('base','metaData.pVal;');
        pSel=evalin('base','metaData.pSel;');
        pVar=evalin('base','metaData.pVar;');
    catch
        pVar='';
    end

    % % d) if cVar is different then user changed
    % if strcmp(pVar,cVar)==0
    %     varChange=1
    %     % i filter on pVar later, 
    %     % so let's make previous var 'state' the current var.
    %     % this simplifies cases later.
    %     pVar=cVar;
    % else
    % end

    % e) get what's in the workspace now
    %
    % the strings to populate the box are a cell
    % we want to see if our last selection is still there
    % if so, recenter on it. 
    % this helps search:
    ss=@(x) strcmp(x,pVar);
    %
    % f) get workspace vars
    vars = evalin('base','who');
    set(handles.workspaceVarBox,'String',vars);
    try
        set(handles.workspaceVarBox,'Value',find(ss(vars)==1));
    catch
    end
   
    logSelection(hObject,eventdata,handles)
    guidata(hObject, handles);

function meanProjectButton_Callback(hObject, eventdata, handles)

    selections = get(handles.workspaceVarBox,'String');
    selectionsIndex = get(handles.workspaceVarBox,'Value');
    for n=1:numel(selectionsIndex)
        s=evalin('base',selections{selectionsIndex(n)});
        mP=mean(s,3);
        if class(s)=='uint16'
            evalin('base',['mP=mean(' selections{selectionsIndex(n)} ',3);'])
            evalin('base',['meanProj_' selections{selectionsIndex(n)} '=im2uint16(mP,"Indexed");,clear mP']);
        else
            evalin('base',['meanProj_' selections{selectionsIndex(n)} '=mean(' selections{selectionsIndex(n)} ',3);']);
        end
    end
    refreshVarListButton_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);
function stdevProjectionButton_Callback(hObject, eventdata, handles)


    selections = get(handles.workspaceVarBox,'String');
    selectionsIndex = get(handles.workspaceVarBox,'Value');
    for n=1:numel(selectionsIndex)
        evalin('base',['stdevProj_' selections{selectionsIndex(n)} '=std(double(' selections{selectionsIndex(n)} '),1,3);']);
    end
    refreshVarListButton_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);
function maxProjectionButton_Callback(hObject, eventdata, handles)

    selections = get(handles.workspaceVarBox,'String');
    selectionsIndex = get(handles.workspaceVarBox,'Value');
    for n=1:numel(selectionsIndex)
        s=evalin('base',selections{selectionsIndex(n)});
        mP=max(s,[],3);
        assignin('base',['maxProj_' selections{selectionsIndex(n)}],mP);
    end
    refreshVarListButton_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);

function playStackMovButton_Callback(hObject, eventdata, handles)
    % first see what the play state is.
    % if we have not played before we create that.
    try 
        pS=evalin('base','metaData.iPS;');
        pS=1-pS;
        assignin('base','iPS',pS);
        evalin('base','metaData.iPS=iPS;,clear ''iPS''');
    catch
        pS=1;
        assignin('base','iPS',pS);
        evalin('base','metaData.iPS=iPS;,clear ''iPS''');
    end

    % now check what stack is selected.
    selections = get(handles.workspaceVarBox,'String');
    selectionsIndex = get(handles.workspaceVarBox,'Value');
    stackName=[selections{selectionsIndex}];
    stackSize=evalin('base',['size(' stackName ');']);
    
    try 
        if stackSize(3)>1
            % This helps you start from where you left off.
            startFrame=str2num(get(handles.frameTextEntry,'String'));
            if startFrame==stackSize(3)
                startFrame=1;
            else
            end
        else
        end

        sliderMin = 1;
        sliderMax = fix(stackSize(3)); % this is variable
        sliderStep = [1, 1] / (sliderMax - sliderMin); % major and minor steps of 1

        set(handles.frameSlider, 'Min', sliderMin);
        set(handles.frameSlider, 'Max', sliderMax);
        set(handles.frameSlider, 'SliderStep', sliderStep);
        set(handles.frameSlider, 'Value', startFrame); % set to beginning of sequence

        % check if they want to overlay a mask
        pMO=get(handles.overlayIndRoiToggle,'Value');
        % override if there is no mask
        mE=evalin('base','exist(''cMask'')');
        if mE==0
            pMO=0;
        else
        end

        if pMO
            cMask=evalin('base','cMask;');
        else
            cMask=1;
        end

        axes(handles.imageWindow);

        % colormap
        sL=get(handles.colormapTextEntry,'String');
        sV=get(handles.colormapTextEntry,'Value');
        cMap=sL{sV};

        % slider states
        a = get(handles.lowCutEntry,'String');
        b = get(handles.highCutEntry,'String');
        lowCut=str2double(a);
        highCut=str2double(b);


        % mfactor=.4;
        mfactor=1;
        ii=1;

        % change the play btn to pause
        set(handles.playStackMovButton,'String','Pause')
        pause(0.0000000000001)
        guidata(hObject, handles);

        % play loop
        i=startFrame;
        while pS==1
            xTmp=strsplit(get(handles.xCropEntry,'String'),':');
            yTmp=strsplit(get(handles.yCropEntry,'String'),':');



            cropX=str2num(xTmp{1}):str2num(xTmp{2});
            cropY=str2num(yTmp{1}):str2num(yTmp{2});

            % get current image
            curImage=double(evalin('base',[stackName '(:,:,' num2str(i) ');']));
            try
                cropTest=curImage(cropY,cropX);
            catch
                cropX=1:size(curImage,2);
                cropY=1:size(curImage,1);
            end

            
            % weight if need be.
            ii=(ii.*(1-mfactor))+curImage.*mfactor;
            % ii=ii.*cMask;
            
            medFilter=get(handles.medianFilterToggle,'Value');
            if medFilter==1
                ii=medfilt2(ii);
            else
            end

            wienerFilter=get(handles.wienerFilterToggle,'Value');
            if wienerFilter==1
                ii=wiener2(ii);
            else
            end
            
            set(handles.frameTextEntry,'String',num2str(fix(i)));
            set(handles.frameSlider, 'Value', i);
            h=imshow(ii(cropY,cropX),'DisplayRange',[lowCut highCut]);
            colormap(gca,cMap);
            daspect([1 1 1])
            if get(handles.overlayIndRoiToggle,'Value')==1
                tA=evalin('base','cMask;');
                set(h, 'AlphaData', tA(cropY,cropX))
            else
            end
            drawnow;
            pS=evalin('base','metaData.iPS;');
            guidata(hObject, handles);
            delete(h);
            i=i+1;
            if i>sliderMax
                i=1;
            else
            end
        end

        set(handles.frameTextEntry,'String',num2str(fix(i)));
        set(handles.frameSlider, 'Value', fix(i));
        guidata(hObject, handles);
        curImage=double(evalin('base',[stackName '(:,:,' num2str(i) ');']));
        ii=(ii.*(1-mfactor))+curImage.*mfactor;
        % ii=ii.*cMask;
        h=imshow(ii(cropY,cropX),'DisplayRange',[lowCut highCut]);
        if get(handles.overlayIndRoiToggle,'Value')==1
            tA=evalin('base','cMask;');
            set(h, 'AlphaData', tA(cropY,cropX))
        else
        end
        colormap(gca,cMap);
        daspect([1 1 1])


        axes(handles.imageWindow);
        assignin('base','currentImage',ii)
        evalin('base','metaData.currentImage=currentImage;,clear currentImage');

        assignin('base','iPS',0)
        evalin('base','metaData.iPS=iPS;,clear ''iPS''')

        set(handles.playStackMovButton,'String','Play')
        pause(0.0000000000000001)
        guidata(hObject, handles);
    catch
    end
function roiThresholdEntry_Callback(hObject, eventdata, handles)

    roiTh=str2num(get(handles.roiThresholdEntry,'String'));
    axes(handles.roiPreviewWindow);
    
   
    currentImage = evalin('base','metaData.currentImage');
    imagesc(im2bw(currentImage,roiTh),[0 2]),colormap jet
    assignin('base','candidateRoi',im2bw(currentImage,roiTh))
    assignin('base','cMask',im2bw(currentImage,roiTh))
    assignin('base','candidateRoi_rawVals',currentImage)
    evalin('base','metaData.currentMask=cMask;');
    evalin('base','metaData.candidateRoi=candidateRoi;')
    evalin('base','metaData.candidateRoi_rawVals=candidateRoi_rawVals;')


    % % Update handles structure
    % guidata(hObject, handles);
    roisDisplayToggle(hObject, eventdata, handles,1)
    refreshVarListButton_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);


    refreshVarListButton_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);

function gXCorImageCountEntry_Callback(hObject, eventdata, handles)
function gXCorSmoothToggle_Callback(hObject, eventdata, handles)

function getGXcorButton_Callback(hObject, eventdata, handles)
    set(handles.getGXcorButton,'Enable','off');
    try
    % Poll Params
    filterState=get(handles.gXCorSmoothToggle,'Value');
    imsToCor=str2num(get(handles.gXCorImageCountEntry,'String'));

    selections = get(handles.workspaceVarBox,'String');
    selectionsIndex = get(handles.workspaceVarBox,'Value');
    selectStack=selections{selectionsIndex};
    assignin('base','lastCorStack',selectStack);
    evalin('base','metaData.lastCorStack=lastCorStack;,clear lastCorStack');

    numImages=evalin('base',['size(' selectStack ',3)']);

    if filterState==1    
        corStack=[];
        c=0;
        ff=fspecial('gaussian',11,0.5);

        nstack=min(imsToCor,numImages);
        for n=1:nstack
            c=c+1;
            if (rem(n,50)==0)
                set(handles.getGXcorButton,'String',[num2str(n) ' of ' num2str(nstack)])
                pause(0.0000001);
                guidata(hObject, handles);
            end
            set(handles.getGXcorButton,'String','XCor')
            fnum=n;
            evalStr=['double(' selectStack '(:,:,' num2str(n) '))'];
            I=evalin('base',evalStr);
            I=conv2(double(I),ff,'same');
            corStack(:,:,n)=I;
            % assignin('base','corStack',corStack);
        end
    elseif filterState==0
        nstack=min(imsToCor,numImages);
        corStack=evalin('base',['double(' selectStack '(:,:,1:' num2str(nstack) '));']);
    else
    end

    

    % make local Xcorr and/or PCA
    % global xcor image code ----> adapted from http://labrigger.com/blog/2013/06/13/local-cross-corr-images/
    % local xcor region growing Jakob Voigts

    set(handles.feedbackString,'String','computing local xcorr')
    pause(0.000001);
    guidata(hObject, handles);

    w=1; % window size

    % Initialize and set up parameters
    ymax=size(corStack,1);
    xmax=size(corStack,2);
    numFrames=size(corStack,3);
    cimg=zeros(ymax,xmax);

    for y=1+w:ymax-w
        
        if (rem(y,20)==0)
            set(handles.feedbackString,'String',['finished line' num2str(y)...
                ' of ' num2str(ymax) ' | ' num2str(round(100*(y./ymax))) '% done'])
            pause(0.0000001);
            guidata(hObject, handles);
        end
        
        for x=1+w:xmax-w
            % Center pixel
            thing1 = reshape(corStack(y,x,:)-mean(corStack(y,x,:),3),[1 1 numFrames]); 
            % Extract center pixel's time course and subtract its mean
            ad_a   = sum(thing1.*thing1,3);    % Auto corr, for normalization laterdf
            
            % Neighborhood
            a = corStack(y-w:y+w,x-w:x+w,:);         % Extract the neighborhood
            b = mean(corStack(y-w:y+w,x-w:x+w,:),3); % Get its mean
            thing2 = bsxfun(@minus,a,b);       % Subtract its mean
            ad_b = sum(thing2.*thing2,3);      % Auto corr, for normalization later
            
            % Cross corr
            ccs = sum(bsxfun(@times,thing1,thing2),3)./sqrt(bsxfun(@times,ad_a,ad_b));
            % Cross corr with normalization
            ccs((numel(ccs)+1)/2) = [];        % Delete the middle point
            cimg(y,x) = mean(ccs(:));       % Get the mean cross corr of the local neighborhood
        end
    end

    m=mean(cimg(:));
    cimg(1,:)=m;
    cimg(end,:)=m;
    cimg(:,1)=m;
    cimg(:,end)=m;


    assignin('base',['cimg_' selectStack],cimg);
    assignin('base','cimg',cimg);
    set(handles.feedbackString,'String','! done with xcor')
    set(handles.getGXcorButton,'Enable','on');  
    pause(0.00001);
    refreshVarListButton_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);

    % ---- end xcor image code
    catch
    set(handles.getGXcorButton,'Enable','on'); 
    guidata(hObject, handles);
    end


   
function pcaButton_Callback(hObject, eventdata, handles)

    tic
    set(handles.feedbackString,'String','performing nnmf prediction')
    pause(0.0000000001);
    guidata(hObject, handles);

    selections = get(handles.workspaceVarBox,'String');
    selectionsIndex = get(handles.workspaceVarBox,'Value');



    imsToCor=str2num(get(handles.gXCorImageCountEntry,'String'));
    numImages=evalin('base',['size(' selections{selectionsIndex} ',3)']);
    imsToCor=min(imsToCor,numImages);


    set(handles.feedbackString,'String','computing PCA ROI estimate')
    pause(0.00001);
    guidata(hObject, handles);

    fNum=fix(str2double(get(handles.featureCountEntry,'String')));

    if fNum>=imsToCor
        fNum=imsToCor-1;
    else
    end
    stack=evalin('base',[selections{selectionsIndex} '(:,:,1:'  num2str(imsToCor) ')']);

    stack_v=zeros(imsToCor,size(stack,1)*size(stack,2));
    for i=1:imsToCor
        x=stack(:,:,i);
        stack_v(i,:)=x(:);
    end
    stack_v=stack_v-mean(stack_v(:));
    [coeff,score,~,~,vExplained] = pca(stack_v,'Economy','on','NumComponents',fNum);
    imcomponents=reshape(coeff',fNum,size(stack,1),size(stack,2));

    pcaimage=(squeeze(mean(abs(imcomponents(:,:,:)))));

    assignin('base','pcaImage',(pcaimage-min(min(pcaimage)))./max(max((pcaimage-min(min(pcaimage))))));
    assignin('base','pcaScores',score);
    assignin('base','pcaComponents',permute(imcomponents,[2 3 1]));
    assignin('base','pcaExplained',vExplained);
    clear stack
    set(handles.feedbackString,'String','done with PCA')
    pause(0.00001);
    refreshVarListButton_Callback(hObject, eventdata, handles)
    % Update handles structure
    guidata(hObject, handles);
function nnmfButton_Callback(hObject, eventdata, handles)
    % performs non-negative matrix factorization with defaults
    % this is a 'feature' based PCA that only allows non-negative values.
    % assuming you have a matrix of features with magnitudes of 0->something
    % this is then ideal for finding the most variance predicting features that
    % correspond more to intuitive features than PCA.
    % see Lee and Seung, 1999 Nature for the first and very lucid description
    % of the method. NM1 are the image sized feature filters (masks) and NM2 is
    % the frame varying weights. Think of NM2 as your PCA'd proportional
    % variance, but varying in time. This tells you the realtive weight of your
    % feature at any momment in time!

    tic
    set(handles.feedbackString,'String','performing nnmf prediction')
    pause(0.0000000001);
    guidata(hObject, handles);

    selections = get(handles.workspaceVarBox,'String');
    selectionsIndex = get(handles.workspaceVarBox,'Value');
    tStack=double(evalin('base',selections{selectionsIndex}));
    s1=size(tStack,1);
    s2=size(tStack,2);

    % sSize=size(tStack,3);
    sSize=fix(str2double(get(handles.gXCorImageCountEntry,'String')));
    if sSize<size(tStack,3)
        tStack=tStack(:,:,1:sSize);
    else
        sSize=size(tStack,3);
    end

    fNum=fix(str2double(get(handles.featureCountEntry,'String')));

    if fNum>=sSize
        fNum=sSize-1;
    else
    end

    tStack=reshape(tStack,size(tStack,1)*size(tStack,2),size(tStack,3));

    size(tStack,1)
    size(tStack,2)
    size(tStack,3)

    [nm1,nm2,nm3]=nmf(tStack,fNum,'MAX_ITER',100);
    nm1=nm1./max(max(max(nm1)));

    nm1=reshape(nm1,s1,s2,fNum);
    nm1Nrm=nm1./max(max(medfilt3(nm1)));
    clear tStack

    assignin('base','nm1',nm1);
    assignin('base','nm1Nrm',nm1Nrm);
    assignin('base','nm2',nm2);
    assignin('base','nm3',nm3);

    clear nm1 nm2 nm3

    nmTim=toc;
    set(handles.feedbackString,'String',['finished nnmf in ' num2str(nmTim) 'seconds'])
    pause(0.000000001);
    guidata(hObject, handles);
    refreshVarListButton_Callback(hObject, eventdata, handles)

function localXCorButton_Callback(hObject, eventdata, handles)
    
    imsToCor=str2num(get(handles.gXCorImageCountEntry,'String'));
    corStackName=evalin('base','metaData.lastCorStack;');
    numImages=evalin('base',['size(' corStackName ',3)']);
    nstack=min(imsToCor,numImages);

    cimg=double(evalin('base','cimg'));
    roiTh=str2num(get(handles.roiThresholdEntry,'String'));
    nstack=min(imsToCor,numImages);
    corStack=evalin('base',['double(' corStackName '(:,:,1:' num2str(nstack) '));']);

    [x,y]=csginput(1);
    %iterative region growing
    ref= (squeeze(corStack(ceil(y),ceil(x),:) ));

    xc=cimg.*0;
    xc(ceil(y),ceil(x))=0.9; % seed

    it=1;
        while it<50
            sig=find(xc>0.04);
            mask=cimg.*0; mask(sig)=1;
            mask=conv2(mask,ones(5),'same')>0;
            update=find((xc==0).*(mask==1));
            if numel(update)<1
                it=500;
            end
            for fillin=update'
                [a,b]=ind2sub(size(cimg),fillin);
                c=corrcoef(squeeze(corStack(a,b,:)),ref);
                xc(a,b)=c(2,1);
            end
            it=it+1;
        end

    localCorMaskPlot=(1-mask).*cimg./10+ ((xc*1));
    imagesc(localCorMaskPlot),axis off
    colormap jet
    currentImage=localCorMaskPlot;
    assignin('base','currentImage',double(localCorMaskPlot))
    evalin('base','metaData.currentImage=currentImage;');
    daspect([1 1 1]);

    axes(handles.cdfWindow);
    cdfplot(reshape(localCorMaskPlot,numel(cimg),1))

    roiTh=str2num(get(handles.roiThresholdEntry,'String'));
    axes(handles.roiPreviewWindow);
    imagesc(im2bw(currentImage,roiTh),[0 2]),colormap jet
    assignin('base','candidateRoi',im2bw(currentImage,roiTh))
    assignin('base','cMask',im2bw(currentImage,roiTh))
    assignin('base','candidateRoi_rawVals',currentImage)
    evalin('base','metaData.currentMask=cMask;');
    evalin('base','metaData.candidateRoi=candidateRoi;')
    
    evalin('base','metaData.candidateRoi_rawVals=candidateRoi_rawVals;')


    % % Update handles structure
    % guidata(hObject, handles);
    roisDisplayToggle(hObject, eventdata, handles,1)
    refreshVarListButton_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);

function colormapTextEntry_Callback(hObject, eventdata, handles)

    loadMeanProjectionButton_Callback(hObject, eventdata, handles)

function frameSlider_Callback(hObject, eventdata, handles)
    
    sliderValue = ceil(get(handles.frameSlider,'Value'));
    set(handles.frameTextEntry,'String', num2str(sliderValue));
    trackFrame(hObject, eventdata, handles);
    guidata(hObject, handles);
    loadMeanProjectionButton_Callback(hObject,eventdata, handles);
function frameTextEntry_Callback(hObject, eventdata, handles)

    trackFrame(hObject, eventdata, handles);
    loadMeanProjectionButton_Callback(hObject, eventdata, handles)
    guidata(hObject, handles);

function addToSomasButton_Callback(hObject, eventdata, handles)

    g=evalin('base','exist(''somaticRoiCounter'')');
    if g==1
        h=evalin('base','somaticRoiCounter');
        r=evalin('base','somaticROIs');
        c=evalin('base','somaticROICenters');
        b=evalin('base','somaticROIBoundaries');
        pl=evalin('base','somaticROI_PixelLists');
        
        h=h+1;
        mask=evalin('base','metaData.candidateRoi');
       
        
        
        r{h}=mask;
        b{h}=bwboundaries(mask);
        c{h}=regionprops(mask,'Centroid');
        pl{h}=regionprops(mask,'PixelList');
        
        
        assignin('base','somaticROIs',r)
        assignin('base','somaticROICenters',c)
        assignin('base','somaticROIBoundaries',b)
        assignin('base','somaticRoiCounter',h)
        assignin('base','somaticROI_PixelLists',pl)
        
    else
        h=1;
        mask=evalin('base','metaData.candidateRoi');
        assignin('base','somaticROIs',{mask})
        assignin('base','somaticROICenters',{regionprops(mask,'Centroid')})
        assignin('base','somaticROI_PixelLists',{regionprops(mask,'PixelList')})
        assignin('base','somaticROIBoundaries',{bwboundaries(mask)})
        assignin('base','somaticRoiCounter',h)
    end

    loadMeanProjectionButton_Callback(hObject, eventdata, handles)

    guidata(hObject, handles);
function addToDendritesButton_Callback(hObject, eventdata, handles)

    g=evalin('base','exist(''dendriticRoiCounter'')');
    if g==1
        h=evalin('base','dendriticRoiCounter');
        r=evalin('base','dendriticROIs');
        c=evalin('base','dendriticROICenters');
        b=evalin('base','dendriticROIBoundaries');
        pl=evalin('base','dendriticROI_PixelLists');
        
        h=h+1;
        mask=evalin('base','metaData.candidateRoi');
       
        
        
        r{h}=mask;
        b{h}=bwboundaries(mask);
        c{h}=regionprops(mask,'Centroid');
        pl{h}=regionprops(mask,'PixelList');
        
        
        assignin('base','dendriticROIs',r)
        assignin('base','dendriticROICenters',c)
        assignin('base','dendriticROIBoundaries',b)
        assignin('base','dendriticRoiCounter',h)
        assignin('base','dendriticROI_PixelLists',pl)
        
    else
        h=1;
        mask=evalin('base','metaData.candidateRoi');
        assignin('base','dendriticROIs',{mask})
        assignin('base','dendriticROICenters',{regionprops(mask,'Centroid')})
        assignin('base','dendriticROI_PixelLists',{regionprops(mask,'PixelList')})
        assignin('base','dendriticROIBoundaries',{bwboundaries(mask)})
        assignin('base','dendriticRoiCounter',h)
    end

    loadMeanProjectionButton_Callback(hObject, eventdata, handles)

    % Update handles structure
    guidata(hObject, handles);
function addToBoutonsButton_Callback(hObject, eventdata, handles)

    g=evalin('base','exist(''boutonRoiCounter'')');
    if g==1
        h=evalin('base','boutonRoiCounter');
        r=evalin('base','boutonROIs');
        c=evalin('base','boutonROICenters');
        b=evalin('base','boutonROIBoundaries');
        pl=evalin('base','boutonROI_PixelLists');
        
        h=h+1;
        mask=evalin('base','metaData.candidateRoi');
       
        
        
        r{h}=mask;
        b{h}=bwboundaries(mask);
        c{h}=regionprops(mask,'Centroid');
        pl{h}=regionprops(mask,'PixelList');
        
        
        assignin('base','boutonROIs',r)
        assignin('base','boutonROICenters',c)
        assignin('base','boutonROIBoundaries',b)
        assignin('base','boutonRoiCounter',h)
        assignin('base','boutonROI_PixelLists',pl)
        
    else
        h=1;
        mask=evalin('base','metaData.candidateRoi');
        assignin('base','boutonROIs',{mask})
        assignin('base','boutonROICenters',{regionprops(mask,'Centroid')})
        assignin('base','boutonROI_PixelLists',{regionprops(mask,'PixelList')})
        assignin('base','boutonROIBoundaries',{bwboundaries(mask)})
        assignin('base','boutonRoiCounter',h)
    end

    loadMeanProjectionButton_Callback(hObject, eventdata, handles)

    % Update handles structure
    guidata(hObject, handles);

function featureCountEntry_Callback(hObject, eventdata, handles)

% filters
function medianFilterToggle_Callback(hObject, eventdata, handles)

    loadMeanProjectionButton_Callback(hObject, eventdata, handles)
function wienerFilterToggle_Callback(hObject, eventdata, handles)

    loadMeanProjectionButton_Callback(hObject, eventdata, handles)
function overlayIndRoiToggle_Callback(hObject,eventdata,handles)

    loadMeanProjectionButton_Callback(hObject, eventdata, handles)    

% program nav
function importerButton_Callback(hObject, eventdata, handles)

    evalin('base','importer')
function extractorButton_Callback(hObject, eventdata, handles)


    evalin('base','extractor')

function cMaskToggle_Callback(hObject, eventdata, handles)
    
    selections = get(handles.workspaceVarBox,'String');
    selectionsIndex = get(handles.workspaceVarBox,'Value');
    selectedItem=selections{selectionsIndex};
    curFrame=get(handles.frameTextEntry,'String');
    
    try 
        currentFrame=evalin('base','metaData.currentFrame');
    catch
        currentFrame=trackFrame(hObject, eventdata, handles);
    end
    
    set(handles.frameTextEntry,'String',num2str(currentFrame))
    guidata(hObject, handles);

    loadMeanProjectionButton_Callback(hObject,eventdata,handles)
    binaryThreshold=str2double(get(handles.binaryThrValEntry,'String'));
    axes(handles.imageWindow);
    a=gcf;
    cImage=a.CurrentAxes.Children(end).CData;
    cMask=imbinarize(double(cImage),binaryThreshold);
    assignin('base','cMask',cMask);
    evalin('base','metaData.currentMask=cMask;')
    
    loadMeanProjectionButton_Callback(hObject,eventdata,handles,cMask)
    
    refreshVarListButton_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);
function curImageToMaskButton_Callback(hObject, eventdata, handles)


    axes(handles.roiPreviewWindow);
    tA=gca;
    cMask=tA.Children.CData;
    
    assignin('base','tcMask',cMask)
    evalin('base','metaData.currentMask=tcMask;');
    
    refreshVarListButton_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);
function segmentMaskBtn_Callback(hObject, eventdata, handles)

    sR=evalin('base','metaData.currentMask');
    if strcmp(class(sR),'logical')
        set(handles.feedbackString,'String','');
        guidata(hObject, handles);
        imSize=[size(sR,1) size(sR,2)];
        minROISize=fix(str2double(get(handles.minRoiEntry,'String')));
        linThr=1;
        pROIs=bwboundaries(sR,'holes');
        pROIsizes=fix(cellfun(@numel,pROIs)/2);
        stROIs=find(pROIsizes>=minROISize);
        usedNum=numel(stROIs);
        linearROIs=[];

        goodCount=0;
        for n=1:usedNum
            tSegMask=zeros(imSize(1),imSize(2),1);
            tROI=pROIs{stROIs(n)};

            c1Mean=mean(abs(diff(tROI(:,1))));
            c2Mean=mean(abs(diff(tROI(:,2))));

            if c1Mean==linThr || c2Mean==linThr
                linearROIs=[linearROIs; n];
            else
                goodCount=goodCount+1;
                tROIs(:,:,goodCount)=roipoly(imSize(1),imSize(2),tROI(:,2),tROI(:,1));
                addROIsFromMask(hObject, eventdata, handles,tROIs(:,:,goodCount))
            end
        end

        refreshVarListButton_Callback(hObject, eventdata, handles);
        set(handles.feedbackString,'String',['segmented ' num2str(goodCount) ' rois'])   
        loadMeanProjectionButton_Callback(hObject, eventdata,handles,sR)

        try 
            curIm=evalin('base','metaData.currentFrame');
        catch
            curIm=1;
        end
        try
            set(handles.frameTextEntry,'String',num2str(curIm+1))
        catch
            set(handles.frameTextEntry,'String',num2str(curIm))
        end
        loadMeanProjectionButton_Callback(hObject, eventdata,handles)
        trackFrame(hObject, eventdata, handles);
        guidata(hObject, handles);
    else
        set(handles.feedbackString,'String','image is not a mask');
        guidata(hObject, handles);
    end
function autoMaskBtn_Callback(hObject, eventdata, handles)

    
    try 
        currentFrame=evalin('base','metaData.currentFrame');
    
    catch
        
        currentFrame=trackFrame(hObject, eventdata, handles);
    end
    
    set(handles.frameTextEntry,'String',num2str(currentFrame))
    guidata(hObject, handles);

    loadMeanProjectionButton_Callback(hObject,eventdata,handles)
    binaryThreshold=str2double(get(handles.binarySensEntry,'String'));
    axes(handles.imageWindow);
    a=gcf;
    cImage=a.CurrentAxes.Children(end).CData;
    cMask=imbinarize(cImage,'adaptive','sensitivity',binaryThreshold);
    assignin('base','cMask',cMask);
    evalin('base','metaData.currentMask=cMask; ')
    
    
    
    loadMeanProjectionButton_Callback(hObject,eventdata,handles,cMask)
    
    refreshVarListButton_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);

function binaryThrValEntry_Callback(hObject, eventdata, handles)

    cMaskToggle_Callback(hObject, eventdata, handles)
function binarySensEntry_Callback(hObject, eventdata, handles)

    cMaskToggle_Callback(hObject, eventdata, handles)

function minRoiEntry_Callback(hObject, eventdata, handles)
function manROIBtn_Generic_Callback(hObject, eventdata, handles)
function roiTypeMenu_Callback(hObject, eventdata, handles)
function deleteWSVar_Callback(hObject, eventdata, handles)

    selections = get(handles.workspaceVarBox,'String');
    selectionsIndex = get(handles.workspaceVarBox,'Value');
    selectedItem=selections{selectionsIndex};
    evalin('base',['clear ' selectedItem]);
    refreshVarListButton_Callback(hObject, eventdata, handles)
    guidata(hObject, handles);
function cutByBtn_Callback(hObject, eventdata, handles)

    cImage=double(evalin('base','currentImage'));
    evalin('base','metaData.currentImage=currentImage;');
    eString=get(handles.imageCutEntry,'String');
    preMin=min(min(nonzeros(cImage)));
    preMax=max(max(nonzeros(cImage)));
    
    eval(['cImage(find(cImage ' eString '))=0']);
    newMin=min(min(nonzeros(cImage)))
    newMax=max(max(nonzeros(cImage)))
    cImage=remap(cImage,[preMin preMax],[newMin newMax]);
    assignin('base','currentImage',cImage);
    evalin('base','metaData.currentImage=currentImage;');
    loadMeanProjectionButton_Callback(hObject,eventdata,handles,cImage);
function imageCutEntry_Callback(hObject, eventdata, handles)

    cutByBtn_Callback(hObject, eventdata, handles)
function deDupeRoisBtn_Callback(hObject, eventdata, handles)

    % get pixel counts per roi
    % kill small ones

    sL=get(handles.roiTypeMenu,'String');
    sV=get(handles.roiTypeMenu,'Value');
    roiTypeSelected=sL{sV};
    assignin('base','roiSelectString',roiTypeSelected)

    r=evalin('base',[roiTypeSelected 'ROIs']);
    c=evalin('base',[roiTypeSelected 'ROICenters']);
    b=evalin('base',[roiTypeSelected 'ROIBoundaries']);
    pl=evalin('base',[roiTypeSelected 'ROI_PixelLists']);

    numIt=0;
    posNums=nchoosek(numel(r),2);
    pCount=cellfun(@numel,cellfun(@(x) find(x==1),r,'UniformOutput',0));
    set(handles.feedbackString,'String','deduping ...')
    for n=1:(numel(r)-1)
        for j=n+1:numel(r)
            numIt=numIt+1;
            ovPixels{1,numIt}=find((r{n}+r{j})==2);
            numOvPixels(numIt)=numel(ovPixels{1,numIt});
            totalPixelsInPair(numIt)=pCount(n)+pCount(j);
            pairIDs(:,numIt)=[n,j];
            pixSizePairs(:,numIt)=[pCount(n),pCount(j)];
        end
    end
    

    propOverlap=numOvPixels./totalPixelsInPair;
    thrOverlap=find(propOverlap>0.01);
    overlapingPairs=pairIDs(:,thrOverlap);
    overlapingPairsSizes=pixSizePairs(:,thrOverlap);
    [~,kl]=min(overlapingPairsSizes);

    try 
        for n=1:numel(kl)
            toKill=overlapingPairs(kl(n),:);
        end
        toKill=unique(toKill);
    catch
        toKill=[];
    end

    deleteROI(toKill,repmat({roiTypeSelected},1,numel(toKill)));
    roisDisplayToggle(hObject,eventdata,handles)
    set(handles.feedbackString,'String',['deleted ' num2str(numel(toKill)) ' potential dupes'])
    guidata(hObject, handles);
function clusterMaskBtn_Callback(hObject, eventdata, handles)
    cimg=evalin('base','cimg');
    stImg=cimg-mean2(cimg);
    stImgThr=0.1;
    %str2num(get(handles.binaryThrValEntry,'String'));

    imLn=size(stImg,1);
    imPx=size(stImg,2);

    thrMask=zeros(imLn,imPx);
    thrPX=find(stImg>stImgThr);

    for n=1:numel(thrPX)
        cline=ceil(thrPX(n)/imLn);
        cpixel=thrPX(n)-(imLn*(cline-1));
        thrMask(cpixel,cline)=1;
    end
    
    minROISize=7;
    pROIs=bwboundaries(thrMask,'holes');
    pROIsizes=fix(cellfun(@numel,pROIs)/2);
    
    szROIs=find(pROIsizes>=minROISize);
    usedNum=numel(szROIs);
    usedROIsizes=pROIsizes(szROIs);
    segMasks=zeros(imLn,imPx,usedNum);

    for n=1:usedNum
        tROI=pROIs{szROIs(n)};
        segMasks(:,:,n)=roipoly(imLn,imPx,tROI(:,2),tROI(:,1));
    end
    
    poolCounter=0;
    dataToClusterOn=cimg-mean2(cimg);
    
    for p=1:size(segMasks,3)
        mNum=p;
        ws=usedROIsizes(mNum);
        dataThrIDs=find(segMasks(:,:,mNum)==1);
        dataThrVals=dataToClusterOn(segMasks(:,:,mNum)==1);
        if numel(dataThrIDs)>1
            clear seg2Masks
            fMask=zeros(imLn,imPx);
            fMaskData=zeros(imLn,imPx);



            for n=1:numel(dataThrIDs)
                cline=ceil(dataThrIDs(n)/imLn);
                cpixel=dataThrIDs(n)-(imLn*(cline-1));
                fMaskData(cpixel,cline)=dataThrVals(n);
                fMask(cpixel,cline)=1;
            end



            mClust=ceil(ws/15);
            minROISize=5;

            clusData=clusterdata(fMaskData(fMask==1),'maxclust',mClust);
            clusPXs=find(fMask==1);

            cNum=numel(unique(clusData));
            clusMask=zeros(imLn,imPx);

            % kill small
            smallClusts=[];
            bigClusts=[];
            bigClustSize=[];
            smCnt=0;

            for n=1:cNum
                tC=find(clusData==n);
                if numel(tC)<minROISize
                    smCnt=smCnt+1;
                    smallClusts(smCnt)=n;
                else
                end
            end


            for n=1:numel(clusPXs)

                cline=ceil(clusPXs(n)/imLn);
                cpixel=clusPXs(n)-(imLn*(cline-1));
                if ismember(clusData(n),smallClusts)
                    clusMask(cpixel,cline)=0;
                else
                    clusMask(cpixel,cline)=1;
                end

            end


            minROISize2=5;
            pROIs=bwboundaries(clusMask,'holes','conn',8);
            pROIsizes=fix(cellfun(@numel,pROIs)/2);
            stROIs=find(pROIsizes>=minROISize2);
            usedNum=numel(stROIs);
        
            poolRois=zeros(imLn,imPx,usedNum);
            for n=1:usedNum
                tempROIMask=zeros(imLn,imPx);
                tROI=pROIs{stROIs(n)};
                for k=1:fix(numel(tROI)/2)
                    tempROIMask(tROI(k,1),tROI(k,2))=1; 
                end
                poolRois(:,:,n)=imfill(tempROIMask);
            end
        
            for k=1:size(poolRois,3)
                addROIsFromMask(hObject, eventdata, handles,poolRois(:,:,k));
            end
            clear poolRois
                
        else
        end
    end
function maxClusterEntry_Callback(hObject, eventdata, handles)

function saveImageBtn_Callback(hObject, eventdata, handles)
    axes(handles.imageWindow);
    g=getframe;
    saveData=frame2im(g);
    

    try
        sC=evalin('base','metaData.saveCounter');
        sC=sC+1;
    catch
        sC=1;
    end
    
    assignin('base',['savedImage_' num2str(sC)],saveData)
    evalin('base',['metaData.savedImage_' num2str(sC) '=savedImage_' num2str(sC) ';, clear savedImage_' num2str(sC)]);
    assignin('base','saveCounter',sC);
    evalin('base','metaData.saveCounter=saveCounter;,clear saveCounter')
    try
        savePath=evalin('base','metaData.importPath');
    catch
        savePath=[pwd filesep];
    end
    saveStrTIF=[savePath  'savedImages' filesep 'expImg_' num2str(sC) '.tif'];
    saveStrPNG=[savePath  'savedImages' filesep 'expImg_' num2str(sC) '.png'];

    warning('off','all');
    try
        mkdir([savePath 'savedImages'])
        imwrite(saveData,saveStrTIF,'tif')
        imwrite(saveData,saveStrPNG,'png')
    catch
        imwrite(saveData,saveStrTIF,'tif')
        imwrite(saveData,saveStrPNG,'png')
    end
    warning('on','all');

    
    refreshVarListButton_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);

function normSelection_Callback(hObject, eventdata, handles)
    
    selections = get(handles.workspaceVarBox,'String');
    selectionsIndex = get(handles.workspaceVarBox,'Value');
    selectedItem=selections{selectionsIndex};
    curSelection=get(handles.frameTextEntry,'String');
    
    evalin('base',[selectedItem '_nrm=(' ...
        selectedItem '-min(min(' selectedItem ...
        ')))./max(max((' selectedItem '-min(min(' selectedItem ')))));']);
    refreshVarListButton_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);

    
% **************************************************************
% **************** Junkyard ************************************
% **************************************************************

function maxClusterEntry_CreateFcn(hObject, eventdata, handles)


    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
function roiSelector_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
function somaButton_KeyPressFcn(hObject, eventdata, handles)
    if get(gcf,'currentcharacter') == 'h'
    
    else
    end
function imageCutEntry_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
function binaryThrValEntry_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
function roiTypeMenu_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
function minRoiEntry_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
function lowCutSlider_CreateFcn(hObject, eventdata, handles)

    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
function frameSlider_CreateFcn(hObject, eventdata, handles)

    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
function featureCountEntry_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
function frameTextEntry_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
function binarySensEntry_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
function highCutSlider_CreateFcn(hObject, eventdata, handles)

    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
function colormapTextEntry_CreateFcn(hObject, eventdata, handles)

    
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
function gXCorImageCountEntry_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
function roiThresholdEntry_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
function highCutEntry_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
function workspaceVarBox_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
function neuropilPixelSpreadEntry_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
function lowCutEntry_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


function yCropEntry_Callback(hObject, eventdata, handles)


function yCropEntry_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function xCropEntry_Callback(hObject, eventdata, handles)


function xCropEntry_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function autoCorBtn_Callback(hObject, eventdata, handles)

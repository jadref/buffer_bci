function varargout = gameController_export(varargin)
% GAMECONTROLLER_EXPORT M-file for gameController_export.fig
%      GAMECONTROLLER_EXPORT, by itself, creates a new GAMECONTROLLER_EXPORT or raises the existing
%      singleton*.
%
%      H = GAMECONTROLLER_EXPORT returns the handle to a new GAMECONTROLLER_EXPORT or the handle to
%      the existing singleton*.
%
%      GAMECONTROLLER_EXPORT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GAMECONTROLLER_EXPORT.M with the given input arguments.
%
%      GAMECONTROLLER_EXPORT('Property','Value',...) creates a new GAMECONTROLLER_EXPORT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before gameController_export_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to gameController_export_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright 2002-2003 The MathWorks, Inc.

% Edit the above text to modify the response to help gameController_export

% Last Modified by GUIDE v2.5 30-Apr-2014 22:49:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gameController_export_OpeningFcn, ...
                   'gui_OutputFcn',  @gameController_export_OutputFcn, ...
                   'gui_LayoutFcn',  @gameController_export_LayoutFcn, ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before gameController_export is made visible.
function gameController_export_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gameController_export (see VARARGIN)

% Choose default command line output for gameController_export
handles.output = hObject;
data = handles;
data.subject='test';
data.level =1;
data.speed =6;
% Update handles structure
guidata(hObject, data);

% UIWAIT makes gameController_export wait for user response (see UIRESUME)
% uiwait(handles.gameController_export);


% --- Outputs from this function are returned to the command line.
function varargout = gameController_export_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function subjectName_Callback(hObject, eventdata, handles)
% hObject    handle to subjectName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of subjectName as text
%        str2double(get(hObject,'String')) returns contents of subjectName as a double
handles.subject=get(hObject,'String');
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function subjectName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subjectName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in capFitting.
function capFitting_Callback(hObject, eventdata, handles)
% hObject    handle to capFitting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.phaseToRun='capFitting';
guidata(hObject,handles);
uiresume;


% --- Executes on button press in calibration.
function calibration_Callback(hObject, eventdata, handles)
% hObject    handle to calibration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.phaseToRun='calibrate';
guidata(hObject,handles);
uiresume;


% --- Executes on button press in classifier.
function classifier_Callback(hObject, eventdata, handles)
% hObject    handle to classifier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.phaseToRun='train';
guidata(hObject,handles);
uiresume;


% --- Executes on button press in snake.
function snake_Callback(hObject, eventdata, handles)
% hObject    handle to snake (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.phaseToRun='snake';
guidata(hObject,handles);
uiresume;


% --- Executes on button press in sokoban.
function sokoban_Callback(hObject, eventdata, handles)
% hObject    handle to sokoban (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.phaseToRun='sokoban';
guidata(hObject,handles);
uiresume;


% --- Executes on button press in pacman.
function pacman_Callback(hObject, eventdata, handles)
% hObject    handle to pacman (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.phaseToRun='pacman';
guidata(hObject,handles);
uiresume;


% --- Executes on button press in practice.
function practice_Callback(hObject, eventdata, handles)
% hObject    handle to practice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.phaseToRun='practice';
guidata(hObject,handles);
uiresume;


% --- Executes on selection change in level.
function level_Callback(hObject, eventdata, handles)
% hObject    handle to level (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns level contents as cell array
%        contents{get(hObject,'Value')} returns selected item from level
%fprintf('hello');
lvls=get(hObject,'String');
handles.level=lvls{get(hObject,'Value')};
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function level_CreateFcn(hObject, eventdata, handles)
% hObject    handle to level (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --------------------------------------------------------------------
function uipanel4_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to uipanel4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.level = str2num(get(hObject,'String'));
guidata(hObject,handles);


function uipanel5_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to uipanel4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.speed = str2num(get(hObject,'String')); 
guidata(hObject,handles);

function level1_Callback(hObject, eventdata, handles)
% hObject    handle to level (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns level contents as cell array
%        contents{get(hObject,'Value')} returns selected item from level

function level2_Callback(hObject, eventdata, handles)
% hObject    handle to level (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns level contents as cell array
%        contents{get(hObject,'Value')} returns selected item from level

function level3_Callback(hObject, eventdata, handles)
% hObject    handle to level (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns level contents as cell array
%        contents{get(hObject,'Value')} returns selected item from level


% --- Executes on button press in eegviewer.
function eegviewer_Callback(hObject, eventdata, handles)
% hObject    handle to eegviewer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.phaseToRun=get(hObject,'tag');
guidata(hObject,handles);
uiresume;


% --- Executes on button press in Spelling.
function Spelling_Callback(hObject, eventdata, handles)
% hObject    handle to Spelling (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.phaseToRun=get(hObject,'tag');
guidata(hObject,handles);
uiresume;




% --- Creates and returns a handle to the GUI figure. 
function h1 = gameController_export_LayoutFcn(policy)
% policy - create a new figure or use a singleton. 'new' or 'reuse'.

persistent hsingleton;
if strcmpi(policy, 'reuse') & ishandle(hsingleton)
    h1 = hsingleton;
    return;
end
load gameController_export.mat


appdata = [];
appdata.GUIDEOptions = struct(...
    'active_h', [], ...
    'taginfo', struct(...
    'figure', 2, ...
    'text', 5, ...
    'edit', 2, ...
    'uipanel', 7, ...
    'pushbutton', 13, ...
    'listbox', 3, ...
    'radiobutton', 12), ...
    'override', 0, ...
    'release', 13, ...
    'resize', 'none', ...
    'accessibility', 'callback', ...
    'mfile', 1, ...
    'callbacks', 1, ...
    'singleton', 1, ...
    'syscolorfig', 1, ...
    'lastSavedFile', '/home/jdrf/projects/bci/buffer_bci/games/gameController_export.m', ...
    'blocking', 0);
appdata.lastValidTag = 'gameController';
appdata.GUIDELayoutEditor = [];

h1 = figure(...
'Units','characters',...
'Color',[0.701960784313725 0.701960784313725 0.701960784313725],...
'Colormap',[0 0 0.5625;0 0 0.625;0 0 0.6875;0 0 0.75;0 0 0.8125;0 0 0.875;0 0 0.9375;0 0 1;0 0.0625 1;0 0.125 1;0 0.1875 1;0 0.25 1;0 0.3125 1;0 0.375 1;0 0.4375 1;0 0.5 1;0 0.5625 1;0 0.625 1;0 0.6875 1;0 0.75 1;0 0.8125 1;0 0.875 1;0 0.9375 1;0 1 1;0.0625 1 1;0.125 1 0.9375;0.1875 1 0.875;0.25 1 0.8125;0.3125 1 0.75;0.375 1 0.6875;0.4375 1 0.625;0.5 1 0.5625;0.5625 1 0.5;0.625 1 0.4375;0.6875 1 0.375;0.75 1 0.3125;0.8125 1 0.25;0.875 1 0.1875;0.9375 1 0.125;1 1 0.0625;1 1 0;1 0.9375 0;1 0.875 0;1 0.8125 0;1 0.75 0;1 0.6875 0;1 0.625 0;1 0.5625 0;1 0.5 0;1 0.4375 0;1 0.375 0;1 0.3125 0;1 0.25 0;1 0.1875 0;1 0.125 0;1 0.0625 0;1 0 0;0.9375 0 0;0.875 0 0;0.8125 0 0;0.75 0 0;0.6875 0 0;0.625 0 0;0.5625 0 0],...
'DockControls','off',...
'IntegerHandle','off',...
'InvertHardcopy',get(0,'defaultfigureInvertHardcopy'),...
'MenuBar','none',...
'Name','BCI Game Controller',...
'NumberTitle','off',...
'PaperPosition',get(0,'defaultfigurePaperPosition'),...
'Position',[103.8 30.8186813186813 61.6666666666667 30.6428571428571],...
'Resize','off',...
'ToolBar','none',...
'HandleVisibility','callback',...
'Tag','gameController',...
'UserData',[],...
'Behavior',get(0,'defaultfigureBehavior'),...
'Visible','on',...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'subjectName';

h2 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'Callback','gameController_export(''subjectName_Callback'',gcbo,[],guidata(gcbo))',...
'Position',[19.8333333333333 27.5714285714286 40.1666666666667 1.57142857142857],...
'String','test',...
'Style','edit',...
'CreateFcn', {@local_CreateFcn, 'gameController_export(''subjectName_CreateFcn'',gcbo,[],guidata(gcbo))', appdata} ,...
'Tag','subjectName',...
'Behavior',get(0,'defaultuicontrolBehavior'));

appdata = [];
appdata.lastValidTag = 'text2';

h3 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'FontWeight','bold',...
'HorizontalAlignment','right',...
'Position',[3.16666666666667 27.6428571428571 13.5 1.5],...
'String','Subject',...
'Style','text',...
'Tag','text2',...
'Behavior',get(0,'defaultuicontrolBehavior'),...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'uipanel1';

h4 = uipanel(...
'Parent',h1,...
'Units','characters',...
'BorderType','etchedout',...
'Title','Setup + Calibration',...
'Position',[1.5 6.21428571428571 28.5 20.0714285714286],...
'Tag','uipanel1',...
'Behavior',get(0,'defaultuipanelBehavior'),...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'capFitting';

h5 = uicontrol(...
'Parent',h4,...
'Units','characters',...
'Callback','gameController_export(''capFitting_Callback'',gcbo,[],guidata(gcbo))',...
'Position',[3.16666666666667 14.2142857142857 13.5 2.92857142857143],...
'String','CapFitting',...
'Tag','capFitting',...
'Behavior',get(0,'defaultuicontrolBehavior'),...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'calibration';

h6 = uicontrol(...
'Parent',h4,...
'Units','characters',...
'Callback','gameController_export(''calibration_Callback'',gcbo,[],guidata(gcbo))',...
'Position',[3.16666666666667 5.64285714285714 20.1666666666667 2.92857142857143],...
'String','Calibration',...
'Tag','calibration',...
'Behavior',get(0,'defaultuicontrolBehavior'),...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'classifier';

h7 = uicontrol(...
'Parent',h4,...
'Units','characters',...
'Callback','gameController_export(''classifier_Callback'',gcbo,[],guidata(gcbo))',...
'Position',[3.16666666666667 1.35714285714286 20.1666666666667 2.92857142857143],...
'String','Train Classifier',...
'Tag','classifier',...
'Behavior',get(0,'defaultuicontrolBehavior'),...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'practice';

h8 = uicontrol(...
'Parent',h4,...
'Units','characters',...
'Callback','gameController_export(''practice_Callback'',gcbo,[],guidata(gcbo))',...
'Position',[3.16666666666667 9.92857142857142 20.1666666666667 2.92857142857143],...
'String','Practice',...
'Tag','practice',...
'Behavior',get(0,'defaultuicontrolBehavior'),...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'eegviewer';

h9 = uicontrol(...
'Parent',h4,...
'Units','characters',...
'Callback','gameController_export(''eegviewer_Callback'',gcbo,[],guidata(gcbo))',...
'Position',[16.5 14.2142857142857 6.83333333333333 2.92857142857143],...
'String','EEG',...
'Tag','eegviewer',...
'Behavior',get(0,'defaultuicontrolBehavior'),...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'uipanel2';

h10 = uipanel(...
'Parent',h1,...
'Units','characters',...
'BorderType','etchedout',...
'Title','Games',...
'Position',[33.1666666666667 6.21428571428571 26.8333333333333 20.0714285714286],...
'Tag','uipanel2',...
'Behavior',get(0,'defaultuipanelBehavior'),...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'snake';

h11 = uicontrol(...
'Parent',h10,...
'Units','characters',...
'Callback','gameController_export(''snake_Callback'',gcbo,[],guidata(gcbo))',...
'Position',[3 9.14285714285714 20.1666666666667 2.92857142857143],...
'String','Snake',...
'Tag','snake',...
'Behavior',get(0,'defaultuicontrolBehavior'),...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'sokoban';

h12 = uicontrol(...
'Parent',h10,...
'Units','characters',...
'Callback','gameController_export(''sokoban_Callback'',gcbo,[],guidata(gcbo))',...
'Position',[3.16666666666667 5 20.1666666666667 2.92857142857143],...
'String','Sokoban',...
'Tag','sokoban',...
'Behavior',get(0,'defaultuicontrolBehavior'),...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'pacman';

h13 = uicontrol(...
'Parent',h10,...
'Units','characters',...
'Callback','gameController_export(''pacman_Callback'',gcbo,[],guidata(gcbo))',...
'Position',[3.33333333333333 1.21428571428571 20.1666666666667 2.92857142857143],...
'String','Pacman',...
'Tag','pacman',...
'Behavior',get(0,'defaultuicontrolBehavior'),...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'uipanel4';

h14 = uibuttongroup(...
'Parent',h10,...
'Units','characters',...
'Title','Level',...
'Position',[3.16666666666667 15.6428571428571 20.1666666666667 2.92857142857143],...
'Tag','uipanel4',...
'Behavior',struct(),...
'SelectedObject',[],...
'SelectionChangeFcn','gameController_export(''uipanel4_SelectionChangeFcn'',gcbo,[],guidata(gcbo))',...
'OldSelectedObject',[],...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'level1';

h15 = uicontrol(...
'Parent',h14,...
'Units','characters',...
'Callback','gameController_export(''level1_Callback'',gcbo,[],guidata(gcbo))',...
'Position',[1.16666666666667 0.357142857142857 5.16666666666667 1.5],...
'String','1',...
'Style','radiobutton',...
'Value',1,...
'Tag','level1',...
'Behavior',get(0,'defaultuicontrolBehavior'),...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'level2';

h16 = uicontrol(...
'Parent',h14,...
'Units','characters',...
'Callback',mat{1},...
'Position',[6.83333333333333 0.357142857142857 5.16666666666667 1.5],...
'String','2',...
'Style','radiobutton',...
'Tag','level2',...
'Behavior',get(0,'defaultuicontrolBehavior'),...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'level3';

h17 = uicontrol(...
'Parent',h14,...
'Units','characters',...
'Callback',mat{2},...
'Position',[12.3333333333333 0.357142857142857 5.16666666666667 1.5],...
'String','3',...
'Style','radiobutton',...
'Tag','level3',...
'Behavior',get(0,'defaultuicontrolBehavior'),...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'uipanel5';

h18 = uibuttongroup(...
'Parent',h10,...
'Units','characters',...
'Title','Speed (s)',...
'Position',[3.33333333333333 12.8571428571429 20.1666666666667 2.92857142857143],...
'Tag','uipanel5',...
'Behavior',struct(),...
'SelectedObject',[],...
'SelectionChangeFcn','gameController_export(''uipanel5_SelectionChangeFcn'',gcbo,[],guidata(gcbo))',...
'OldSelectedObject',[],...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'radiobutton9';

h19 = uicontrol(...
'Parent',h18,...
'Units','characters',...
'Callback',mat{3},...
'Position',[1.16666666666667 0.357142857142857 5.16666666666667 1.5],...
'String','2',...
'Style','radiobutton',...
'Tag','radiobutton9',...
'Behavior',get(0,'defaultuicontrolBehavior'),...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'radiobutton10';

h20 = uicontrol(...
'Parent',h18,...
'Units','characters',...
'Callback',mat{4},...
'Position',[6.83333333333333 0.357142857142857 5.16666666666667 1.5],...
'String','4',...
'Style','radiobutton',...
'Tag','radiobutton10',...
'Behavior',get(0,'defaultuicontrolBehavior'),...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'radiobutton11';

h21 = uicontrol(...
'Parent',h18,...
'Units','characters',...
'Callback',mat{5},...
'Position',[12.3333333333333 0.357142857142857 5.16666666666667 1.5],...
'String','6',...
'Style','radiobutton',...
'Value',1,...
'Tag','radiobutton11',...
'Behavior',get(0,'defaultuicontrolBehavior'),...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'spellpanel';

h22 = uipanel(...
'Parent',h1,...
'Units','characters',...
'Title','Communication',...
'Position',[1.5 0.5 58.5 5.07142857142857],...
'Tag','spellpanel',...
'Behavior',get(0,'defaultuipanelBehavior'),...
'CreateFcn', {@local_CreateFcn, '', appdata} );

appdata = [];
appdata.lastValidTag = 'Spelling';

h23 = uicontrol(...
'Parent',h22,...
'Units','characters',...
'Callback','gameController_export(''Spelling_Callback'',gcbo,[],guidata(gcbo))',...
'Position',[3.16666666666667 0.642857142857143 51.8333333333333 2.92857142857143],...
'String','Spelling Words',...
'Tag','Spelling',...
'Behavior',get(0,'defaultuicontrolBehavior'),...
'CreateFcn', {@local_CreateFcn, '', appdata} );


hsingleton = h1;


% --- Set application data first then calling the CreateFcn. 
function local_CreateFcn(hObject, eventdata, createfcn, appdata)

if ~isempty(appdata)
   names = fieldnames(appdata);
   for i=1:length(names)
       name = char(names(i));
       setappdata(hObject, name, getfield(appdata,name));
   end
end

if ~isempty(createfcn)
   eval(createfcn);
end


% --- Handles default GUIDE GUI creation and callback dispatch
function varargout = gui_mainfcn(gui_State, varargin)

gui_StateFields =  {'gui_Name'
                    'gui_Singleton'
                    'gui_OpeningFcn'
                    'gui_OutputFcn'
                    'gui_LayoutFcn'
                    'gui_Callback'};
gui_Mfile = '';
for i=1:length(gui_StateFields)
    if ~isfield(gui_State, gui_StateFields{i})
        error('Could not find field %s in the gui_State struct in GUI M-file %s', gui_StateFields{i}, gui_Mfile);        
    elseif isequal(gui_StateFields{i}, 'gui_Name')
        gui_Mfile = [gui_State.(gui_StateFields{i}), '.m'];
    end
end

numargin = length(varargin);

if numargin == 0
    % GAMECONTROLLER_EXPORT
    % create the GUI
    gui_Create = 1;
elseif isequal(ishandle(varargin{1}), 1) && ispc && iscom(varargin{1}) && isequal(varargin{1},gcbo)
    % GAMECONTROLLER_EXPORT(ACTIVEX,...)    
    vin{1} = gui_State.gui_Name;
    vin{2} = [get(varargin{1}.Peer, 'Tag'), '_', varargin{end}];
    vin{3} = varargin{1};
    vin{4} = varargin{end-1};
    vin{5} = guidata(varargin{1}.Peer);
    feval(vin{:});
    return;
elseif ischar(varargin{1}) && numargin>1 && isequal(ishandle(varargin{2}), 1)
    % GAMECONTROLLER_EXPORT('CALLBACK',hObject,eventData,handles,...)
    gui_Create = 0;
else
    % GAMECONTROLLER_EXPORT(...)
    % create the GUI and hand varargin to the openingfcn
    gui_Create = 1;
end

if gui_Create == 0
    varargin{1} = gui_State.gui_Callback;
    if nargout
        [varargout{1:nargout}] = feval(varargin{:});
    else
        feval(varargin{:});
    end
else
    if gui_State.gui_Singleton
        gui_SingletonOpt = 'reuse';
    else
        gui_SingletonOpt = 'new';
    end
    
    % Open fig file with stored settings.  Note: This executes all component
    % specific CreateFunctions with an empty HANDLES structure.
    
    % Do feval on layout code in m-file if it exists
    if ~isempty(gui_State.gui_LayoutFcn)
        gui_hFigure = feval(gui_State.gui_LayoutFcn, gui_SingletonOpt);
        % openfig (called by local_openfig below) does this for guis without
        % the LayoutFcn. Be sure to do it here so guis show up on screen.
        movegui(gui_hFigure,'onscreen')
    else
        gui_hFigure = local_openfig(gui_State.gui_Name, gui_SingletonOpt);            
        % If the figure has InGUIInitialization it was not completely created
        % on the last pass.  Delete this handle and try again.
        if isappdata(gui_hFigure, 'InGUIInitialization')
            delete(gui_hFigure);
            gui_hFigure = local_openfig(gui_State.gui_Name, gui_SingletonOpt);            
        end
    end
    
    % Set flag to indicate starting GUI initialization
    setappdata(gui_hFigure,'InGUIInitialization',1);

    % Fetch GUIDE Application options
    gui_Options = getappdata(gui_hFigure,'GUIDEOptions');
    
    if ~isappdata(gui_hFigure,'GUIOnScreen')
        % Adjust background color
        if gui_Options.syscolorfig 
            set(gui_hFigure,'Color', get(0,'DefaultUicontrolBackgroundColor'));
        end

        % Generate HANDLES structure and store with GUIDATA
        guidata(gui_hFigure, guihandles(gui_hFigure));
    end
    
    % If user specified 'Visible','off' in p/v pairs, don't make the figure
    % visible.
    gui_MakeVisible = 1;
    for ind=1:2:length(varargin)
        if length(varargin) == ind
            break;
        end
        len1 = min(length('visible'),length(varargin{ind}));
        len2 = min(length('off'),length(varargin{ind+1}));
        if ischar(varargin{ind}) && ischar(varargin{ind+1}) && ...
                strncmpi(varargin{ind},'visible',len1) && len2 > 1
            if strncmpi(varargin{ind+1},'off',len2)
                gui_MakeVisible = 0;
            elseif strncmpi(varargin{ind+1},'on',len2)
                gui_MakeVisible = 1;
            end
        end
    end
    
    % Check for figure param value pairs
    for index=1:2:length(varargin)
        if length(varargin) == index || ~ischar(varargin{index})
            break;
        end
        try set(gui_hFigure, varargin{index}, varargin{index+1}), catch break, end
    end

    % If handle visibility is set to 'callback', turn it on until finished
    % with OpeningFcn
    gui_HandleVisibility = get(gui_hFigure,'HandleVisibility');
    if strcmp(gui_HandleVisibility, 'callback')
        set(gui_hFigure,'HandleVisibility', 'on');
    end
    
    feval(gui_State.gui_OpeningFcn, gui_hFigure, [], guidata(gui_hFigure), varargin{:});
    
    if ishandle(gui_hFigure)
        % Update handle visibility
        set(gui_hFigure,'HandleVisibility', gui_HandleVisibility);
        
        % Make figure visible
        if gui_MakeVisible
            set(gui_hFigure, 'Visible', 'on')
            if gui_Options.singleton 
                setappdata(gui_hFigure,'GUIOnScreen', 1);
            end
        end

        % Done with GUI initialization
        rmappdata(gui_hFigure,'InGUIInitialization');
    end
    
    % If handle visibility is set to 'callback', turn it on until finished with
    % OutputFcn
    if ishandle(gui_hFigure)
        gui_HandleVisibility = get(gui_hFigure,'HandleVisibility');
        if strcmp(gui_HandleVisibility, 'callback')
            set(gui_hFigure,'HandleVisibility', 'on');
        end
        gui_Handles = guidata(gui_hFigure);
    else
        gui_Handles = [];
    end
    
    if nargout
        [varargout{1:nargout}] = feval(gui_State.gui_OutputFcn, gui_hFigure, [], gui_Handles);
    else
        feval(gui_State.gui_OutputFcn, gui_hFigure, [], gui_Handles);
    end
    
    if ishandle(gui_hFigure)
        set(gui_hFigure,'HandleVisibility', gui_HandleVisibility);
    end
end    

function gui_hFigure = local_openfig(name, singleton)

% openfig with three arguments was new from R13. Try to call that first, if
% failed, try the old openfig.
try 
    gui_hFigure = openfig(name, singleton, 'auto');
catch
    % OPENFIG did not accept 3rd input argument until R13,
    % toggle default figure visible to prevent the figure
    % from showing up too soon.
    gui_OldDefaultVisible = get(0,'defaultFigureVisible');
    set(0,'defaultFigureVisible','off');
    gui_hFigure = openfig(name, singleton);
    set(0,'defaultFigureVisible',gui_OldDefaultVisible);
end

M
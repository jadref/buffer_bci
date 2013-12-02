function varargout = controller(varargin)
% CONTROLLER M-file for controller.fig
%      CONTROLLER, by itself, creates a new CONTROLLER or raises the existing
%      singleton*.
%
%      H = CONTROLLER returns the handle to a new CONTROLLER or the handle to
%      the existing singleton*.
%
%      CONTROLLER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CONTROLLER.M with the given input arguments.
%
%      CONTROLLER('Property','Value',...) creates a new CONTROLLER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before controller_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to controller_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright 2002-2003 The MathWorks, Inc.

% Edit the above text to modify the response to help controller

% Last Modified by GUIDE v2.5 25-Oct-2013 23:12:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @controller_OpeningFcn, ...
                   'gui_OutputFcn',  @controller_OutputFcn, ...
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
% End initialization code - DO NOT EDIT


% --- Executes just before controller is made visible.
function controller_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to controller (see VARARGIN)

% Choose default command line output for controller
handles.output = hObject;
data = handles;
data.subject='test';
data.level =1;
data.speed =6;
data.phasesCompleted={};
data.phasetoRun=[];

% Update handles structure
guidata(hObject, data);

% UIWAIT makes controller wait for user response (see UIRESUME)
% uiwait(handles.controller);


% --- Outputs from this function are returned to the command line.
function varargout = controller_OutputFcn(hObject, eventdata, handles) 
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
handles.phaseToRun=get(hObject,'Tag');
guidata(hObject,handles);
uiresume;


% --- Executes on button press in calibration.
function calibration_Callback(hObject, eventdata, handles)
% hObject    handle to calibration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.phaseToRun=get(hObject,'Tag');
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


% --- Executes on button press in freespell.
function freespelling_Callback(hObject, eventdata, handles)
% hObject    handle to freespell (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.phaseToRun=get(hObject,'Tag');
guidata(hObject,handles);
uiresume;


% --- Executes on button press in practice.
function practice_Callback(hObject, eventdata, handles)
% hObject    handle to practice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.phaseToRun=get(hObject,'Tag');
guidata(hObject,handles);
uiresume;


% --- Executes on button press in eegviewer.
function eegviewer_Callback(hObject, eventdata, handles)
% hObject    handle to eegviewer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.phaseToRun=get(hObject,'Tag');
guidata(hObject,handles);
uiresume;


% --- Executes on button press in testing.
function testing_Callback(hObject, eventdata, handles)
% hObject    handle to testing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.phaseToRun=get(hObject,'Tag');
guidata(hObject,handles);
uiresume;


% --- Executes on button press in contfeedback.
function contfeedback_Callback(hObject, eventdata, handles)
% hObject    handle to contfeedback (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.phaseToRun=get(hObject,'Tag');
guidata(hObject,handles);
uiresume;



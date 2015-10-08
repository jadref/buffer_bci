function varargout = bufferSignalProcOpts(varargin)
% BUFFERSIGNALPROCOPTS M-file for bufferSignalProcOpts.fig
%      BUFFERSIGNALPROCOPTS, by itself, creates a new BUFFERSIGNALPROCOPTS or raises the existing
%      singleton*.
%
%      H = BUFFERSIGNALPROCOPTS returns the handle to a new BUFFERSIGNALPROCOPTS or the handle to
%      the existing singleton*.
%
%      BUFFERSIGNALPROCOPTS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BUFFERSIGNALPROCOPTS.M with the given input arguments.
%
%      BUFFERSIGNALPROCOPTS('Property','Value',...) creates a new BUFFERSIGNALPROCOPTS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before bufferSignalProcOpts_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to bufferSignalProcOpts_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright 2002-2003 The MathWorks, Inc.

% Edit the above text to modify the response to help bufferSignalProcOpts

% Last Modified by GUIDE v2.5 26-Nov-2014 10:15:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @bufferSignalProcOpts_OpeningFcn, ...
                   'gui_OutputFcn',  @bufferSignalProcOpts_OutputFcn, ...
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


% --- Executes just before bufferSignalProcOpts is made visible.
function bufferSignalProcOpts_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to bufferSignalProcOpts (see VARARGIN)

% Choose default command line output for bufferSignalProcOpts
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes bufferSignalProcOpts wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = bufferSignalProcOpts_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function EpochEventType_Callback(hObject, eventdata, handles)
% hObject    handle to EpochEventType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.epochEventType=get(hObject,'String');
guidata(hObject,handles);

% Hints: get(hObject,'String') returns contents of EpochEventType as text
%        str2double(get(hObject,'String')) returns contents of EpochEventType as a double


% --- Executes during object creation, after setting all properties.
function EpochEventType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EpochEventType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cancelbut.
function cancelbut_Callback(hObject, eventdata, handles)
% hObject    handle to cancelbut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ok=0;
guidata(hObject,handles);
set(handles.figure1,'visible','off')
uiresume;


% --- Executes on button press in okbut.
function okbut_Callback(hObject, eventdata, handles)
% hObject    handle to okbut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ok=1;
handles.opts.epochEventType=get(handles.EpochEventType,'String');;
handles.opts.freqband=-ones(4,1);
handles.opts.freqband(2)=str2double(get(handles.freqbands_lowpass,'String'));
handles.opts.freqband(3)=str2double(get(handles.freqbands_highpass,'String'));
handles.opts.trlen_ms=str2double(get(handles.trlen_ms,'String'));
if ( get(handles.erp,'Value')==1 ) handles.opts.clsfr_type='erp'; end;
if ( get(handles.ersp,'Value')==1 ) handles.opts.clsfr_type='ersp'; end;
% get the strings from the other parts...
guidata(hObject,handles);
set(handles.figure1,'visible','off')
uiresume;



function trlen_ms_Callback(hObject, eventdata, handles)
% hObject    handle to trlen_ms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function trlen_ms_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trlen_ms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function freqbands_lowpass_Callback(hObject, eventdata, handles)
% hObject    handle to freqbands_lowpass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function freqbands_lowpass_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freqbands_lowpass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function freqbands_highpass_Callback(hObject, eventdata, handles)
% hObject    handle to freqbands_highpass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function freqbands_highpass_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freqbands_highpass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ersp.
function ersp_Callback(hObject, eventdata, handles)
% hObject    handle to ersp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in ersp.
function erp_Callback(hObject, eventdata, handles)
% hObject    handle to ersp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function varargout = gameController(varargin)
% GAMECONTROLLER M-file for gameController.fig
%      GAMECONTROLLER, by itself, creates a new GAMECONTROLLER or raises the existing
%      singleton*.
%
%      H = GAMECONTROLLER returns the handle to a new GAMECONTROLLER or the handle to
%      the existing singleton*.
%
%      GAMECONTROLLER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GAMECONTROLLER.M with the given input arguments.
%
%      GAMECONTROLLER('Property','Value',...) creates a new GAMECONTROLLER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before gameController_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to gameController_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
if nargin && ischar(varargin{1}) % call the call-back function
  feval(varargin{:});
else
  varargout{1} = gameController_layout(varargin{:});  
end

function subjectName_Callback(hObject, eventdata, handles)
% hObject    handle to subjectName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of subjectName as text
%        str2double(get(hObject,'String')) returns contents of subjectName as a double
handles=guidata(hObject);
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
handles=guidata(hObject);
handles.phaseToRun='capFitting';
guidata(hObject,handles);
uiresume;


% --- Executes on button press in calibration.
function calibration_Callback(hObject, eventdata, handles)
% hObject    handle to calibration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles=guidata(hObject);
handles.phaseToRun='calibrate';
guidata(hObject,handles);
uiresume;


% --- Executes on button press in classifier.
function classifier_Callback(hObject, eventdata, handles)
% hObject    handle to classifier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles=guidata(hObject);
handles.phaseToRun='train';
guidata(hObject,handles);
uiresume;


% --- Executes on button press in snake.
function snake_Callback(hObject, eventdata, handles)
% hObject    handle to snake (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles=guidata(hObject);
handles.phaseToRun='snake';
guidata(hObject,handles);
uiresume;


% --- Executes on button press in sokoban.
function sokoban_Callback(hObject, eventdata, handles)
% hObject    handle to sokoban (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles=guidata(hObject);
handles.phaseToRun='sokoban';
guidata(hObject,handles);
uiresume;


% --- Executes on button press in pacman.
function pacman_Callback(hObject, eventdata, handles)
% hObject    handle to pacman (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles=guidata(hObject);
handles.phaseToRun='pacman';
guidata(hObject,handles);
uiresume;


% --- Executes on button press in practice.
function practice_Callback(hObject, eventdata, handles)
% hObject    handle to practice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles=guidata(hObject);
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
handles=guidata(hObject);
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
handles=guidata(hObject);
handles.level = str2num(get(hObject,'String'));
guidata(hObject,handles);


function uipanel5_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to uipanel4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles=guidata(hObject);
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
handles=guidata(hObject);
handles.phaseToRun=get(hObject,'tag');
guidata(hObject,handles);
uiresume;


% --- Executes on button press in Spelling.
function Spelling_Callback(hObject, eventdata, handles)
% hObject    handle to Spelling (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles=guidata(hObject);
handles.phaseToRun=get(hObject,'tag');
guidata(hObject,handles);
uiresume;



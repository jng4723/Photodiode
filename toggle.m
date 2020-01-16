function varargout = toggle(varargin)
% TOGGLE MATLAB code for toggle.fig
%      TOGGLE, by itself, creates a new TOGGLE or raises the existing
%      singleton*.
%
%      H = TOGGLE returns the handle to a new TOGGLE or the handle to
%      the existing singleton*.
%
%      TOGGLE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TOGGLE.M with the given input arguments.
%
%      TOGGLE('Property','Value',...) creates a new TOGGLE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before toggle_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to toggle_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help toggle

% Last Modified by GUIDE v2.5 12-Jul-2019 16:32:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @toggle_OpeningFcn, ...
                   'gui_OutputFcn',  @toggle_OutputFcn, ...
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


% --- Executes just before toggle is made visible.
function toggle_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to toggle (see VARARGIN)

% Choose default command line output for toggle
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes toggle wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = toggle_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in start_stop.
function start_stop_Callback(hObject, eventdata, handles)
% hObject    handle to start_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% cla(handles.axes1,'reset');
 cla(handles.axes2,'reset');
 cla(handles.axes3,'reset');

myDaq = daq.createSession('ni');
ch=addAnalogInputChannel(myDaq,'Dev4', 4, 'Voltage');
ch.Range = [-10,10];
global duration addTimeStamp
addTimeStamp=0;
myDaq.DurationInSeconds = str2double(get(handles.DATVal,'String')); %Get the value of duration from GUI
runtime = str2double(get(handles.runTime,'String')); % intended program runtime in seconds
duration=myDaq.DurationInSeconds;
myDaq.Rate= str2double(get(handles.SampleRate,'String'));%Gets sampling rates from user input
myDaq.NotifyWhenDataAvailableExceeds=myDaq.Rate*duration;

M2=0;
sigma2=0;
iter=0;
loop=get(hObject,'value');
seconds=5; % save the figure every __ second
files = cell(round(runtime/seconds),1);
filenumber=0;
stoptime=0;
ax3=handles.axes3; %got rid of lag, about .09 sec lag for every 30 seconds 

% meanval=zeros(runtime*myDaq.Rate,1);
% timeval=zeros(runtime*myDaq.Rate,1);


while loop
        tic
        stoptime=stoptime+duration;
        iter=iter+1;
        
        axes(handles.axes2);
        lh = addlistener(myDaq,'DataAvailable', @plotData);
        myDaq.startBackground();
        myDaq.wait();
        delete(lh);
        
        
        %     axes(handles.axes1);
        hChildren = get(handles.axes2,'Children');
        time = get(hChildren(1),'XData');
        voltage = get(hChildren(1),'YData');
        %     plot(time,voltage,'b');
        %     hold on;
        
        %     hChildren1=get(handles.axes1,'Children');
        %     time1 = get(hChildren(1),'XData');
        %     voltage1 = get(hChildren(1),'YData');
        
        M=mean(voltage);
        set(handles.MeanValue,'String',M);
        % sigma=int16(std(voltage));
        % set(handles.StandardDeviationValue,'String',sigma);
        % CV=sigma/M;
        % set(handles.CV_Value,'String',CV);
        
        % for plot=1:seconds
        %     meanval(plot,1)=M;
        %     timeval(plot,1)=time(end);
        % end
        
        % plot(meanval(),timeval(),'b');
        plot(ax3,time(end),M,'bo');
        
        % drawnow;
        hold(ax3, 'on');
        
        % M2=((iter-1)*M2+mean(voltage))*(1/(iter));
        % set(handles.MeanValue2,'String',M2);
        % sigma2=sqrt(((sigma2*sqrt(iter))^2+std(voltage,1)^2))*(1/sqrt(iter+1));
        % set(handles.StandardDeviationValue2,'String',sigma2);
        % CV2=sigma2/M2;
        % test=get(hObject,'value');
        % set(handles.CV_Value2,'String',test);
        
        
        
        % Every minute, MATLAB delays by 10 seconds. That means if data is to be
        % collected by MATLAB for 10 minutes, then if 10 minutes pass in real time,
        % MATLAB will have only collected 8 minutes and 20 seconds of data. If
        % measuring for 5 hours, MATLAB will have 4 hours and 10 minutes of data.
        % Note that all of this is for the condition that the sampling rate is 500
        % and the data collection time is one second
        
        % What really happens is that the time between each data collection event
        % increases. Initially, the time between each event should be less than a
        % second (ideally instantly). After each minute passes, the time between
        % each data collection event increases by (10/60) seconds.
        
        %     if mod(iter,seconds) == 0  %% save the figure every seconds
        %         filenumber=filenumber+1;
        % %         filename = ['C:\Users\MerilesLab2\Documents\LaserPowerDataFiles\',datestr(now,'yyyy-mm-dd_HHMMSS'),'.fig'];
        %         savefig(filename);
        %         files(filenumber,1)={filename};
        % %         cla(handles.axes1,'reset');
        %         cla(handles.axes2,'reset');
        %         cla(handles.axes3,'reset');
        %
        %
        %     end
        
       
        
        

        set(handles.TocVal,'String',toc);
        if get(hObject,'value')==0
            break;
        elseif stoptime==runtime
            loop=0;
        end
        % end
        
        
        % totalfig=figure();
        % axes
        %     for openfile= 1:filenumber
        %         figfile=openfig(char(files(openfile,1)));
        %         allaxes=findall(figfile,'type','axes');
        %         ax=allaxes(1,1);
        %         L = findobj(ax,'type','line');
        %         copyobj(L,findobj(totalfig,'type','axes'));
        %         close(figfile);
        %     end
        
        %     title('Mean Value After Each Data Collection Event')
        %     xlabel('Time (s)')
        %     ylabel('Mean Voltage')
   


end
       
getdata = findall(handles.axes3,'type','line');

totaltime=get(getdata,'Xdata') ;
meanvoltage=get(getdata,'Ydata') ;
totalfigdata = [datestr(now,'yyyy-mm-dd_HHMMSS'),'.mat'];
diffdat = cell2mat(flipud([totaltime,meanvoltage]));
save(totalfigdata,'diffdat');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function plotData(src, event)
         global duration addTimeStamp
         plot(event.TimeStamps+addTimeStamp,event.Data*-1,'b')
         addTimeStamp=addTimeStamp+duration;
  

% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)



function runTime_Callback(hObject, eventdata, handles)
% hObject    handle to runTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of runTime as text
%        str2double(get(hObject,'String')) returns contents of runTime as a double


% --- Executes during object creation, after setting all properties.
function runTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to runTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to SampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SampleRate as text
%        str2double(get(hObject,'String')) returns contents of SampleRate as a double


% --- Executes during object creation, after setting all properties.
function SampleRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DATVal_Callback(hObject, eventdata, handles)
% hObject    handle to DATVal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DATVal as text
%        str2double(get(hObject,'String')) returns contents of DATVal as a double


% --- Executes during object creation, after setting all properties.
function DATVal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DATVal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function saveas_Callback(hObject, eventdata, handles)
% hObject    handle to saveas (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of saveas as text
%        str2double(get(hObject,'String')) returns contents of saveas as a double


% --- Executes during object creation, after setting all properties.
function saveas_CreateFcn(hObject, eventdata, handles)
% hObject    handle to saveas (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
str=get(handles.saveas,'String');
saveas(gcf,str);
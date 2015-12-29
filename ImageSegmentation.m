function varargout = ImageSegmentation(varargin)%%do not edit
% IMAGESEGMENTATION MATLAB code for ImageSegmentation.fig
%      IMAGESEGMENTATION, by itself, creates a new IMAGESEGMENTATION or raises the existing
%      singleton*.
%
%      H = IMAGESEGMENTATION returns the handle to a new IMAGESEGMENTATION or the handle to
%      the existing singleton*.
%
%      IMAGESEGMENTATION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMAGESEGMENTATION.M with the given input arguments.
%
%      IMAGESEGMENTATION('Property','Value',...) creates a new IMAGESEGMENTATION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ImageSegmentation_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ImageSegmentation_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ImageSegmentation

% Last Modified by GUIDE v2.5 04-Nov-2015 15:28:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ImageSegmentation_OpeningFcn, ...
                   'gui_OutputFcn',  @ImageSegmentation_OutputFcn, ...
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

% --- Executes just before ImageSegmentation is made visible.
function ImageSegmentation_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ImageSegmentation (see VARARGIN)

% Choose default command line output for ImageSegmentation
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
set(handles.axes,'visible','off');
set(handles.axes5,'visible','off');

% --- Outputs from this function are returned to the command line.
%output in matlab command window, do need to edit
function varargout = ImageSegmentation_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes during object creation, after setting all properties.
function slice_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --------------------------------------------------------------------
%read a nd2 file,get the operation file 'evalue'
function openfile_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to openfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename, pathname] = uigetfile('*.nii','select the .nii file');
filename
global data0
data0=load_untouch_nii([pathname,filename]);
global image0;
image0=data0.img;

global rflag
rflag=0; %%indicate change orient %% indicate t1 or t2 under processing
[logindex,location]=ismember('t1',filename);
if logindex==[1 1] & location(2)-location(1)==1
image0=permute(image0,[1,3,2]);
rflag=1;
end

clear image nii data;
sz=size(image0);

if length(sz)==2
    sz=[sz,1];
end

set(handles.slice,'string', {1:1:sz(3)});%set the selection of popupmenu by number 1 to sz(3) 
set(handles.slice,'value',1);

global image1;
button=questdlg('load unfinished data?','load data','Yes','No','Yes');
if strcmp(button,'Yes')==1
    [filename, pathname] = uigetfile('*.nii','select the .nii file');
    data1=load_nii([pathname filename]);
    image1=data1.img;
    if rflag==1
    image1=permute(image1,[1,3,2]);
    end
else
    image1 = zeros(sz);%build a container
end
filename

image0=double(image0);
image1=double(image1);


% %---------------for test--------------
% data=load_nii('t1-temporary.nii');


slice0=image0(:,:,1);% get the maxvalue of each pixel from all slice
axes(handles.axes);%the left axes
imshow(slice0,[]);
slice1=image1(:,:,1);
axes(handles.axes5);
imshow(slice1);


%%initialize some global value
global points
points=4;

global num_label1
num_label1=1;

global cflag;%true already cut
cflag=0;

global sflag;%true already segment
sflag=0;

global rect;%the array about the coordinate of vertex of cutting rectangle  [y1,y2,x1,x2]
rect=[1,sz(2),1,sz(1)];%be careful about the order

global savevalue;%container saves slice0, used in function of restart
savevalue=[];

global mask_save;
mask_save=zeros(sz(1),sz(2));

global saveflag;
saveflag=0;


% --- Executes on button press in selectpoint.
function selectpoint_Callback(hObject, eventdata, handles)
% hObject    handle to selectpoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global image0;

slct=get(handles.slice,'value');
sz=size(image0);

global cflag;
global rect;
slice0=image0(:,:,slct);%get a slice for image0 dataset
if cflag==1
    slicecut=slice0(rect(1):rect(2),rect(3):rect(4));
    slice0=slicecut;    
end

[X,Y]=size(slice0);

global points
global num_label1

global seed;
global label;

axes(handles.axes);
global sflag;

if sflag==0
i=0;
seed=[];
label=zeros(1,num_label1);
N=ones(1,points-num_label1);
label=[label,N];%first version, fixed 4 seeds and 2 types of labels.


while(i<points)   
    [x_p,y_p]=ginput(1);
    x_p=round(x_p);
    y_p=round(y_p);
    hold on
    plot(x_p,y_p,'g.','MarkerSize',5);
    seed=[seed,sub2ind([X Y],y_p,x_p)];
    i=i+1;
%     pause(1);   
end
hold off
end

if sflag==1
    [x_p,y_p]=ginput(1);
    x_p=round(x_p);
    y_p=round(y_p);
%     t=sub2ind([X Y],y_p,x_p);
    if ismember(sub2ind([X Y],y_p,x_p),seed)
        return;
    end
    hold on
    plot(x_p,y_p,'g.','MarkerSize',5);
    seed=[seed,sub2ind([X Y],y_p,x_p)];
    label=[label,1];
end
    
hold off


global mask_save;
[mask1,probabilities] = random_walker(slice0,seed,label,120);
mask1=reshape(mask1,X,Y);
mask1=1-mask1;
mask_copy=zeros(sz(1),sz(2));
if cflag==1
   mask_copy(rect(1):rect(2),rect(3):rect(4))=mask1;
else
    mask_copy=mask1;
end

mask_save=mask_copy;

% mask_save=mask_save+mask_copy;
% mask_save(mask_save~=0)=1;

[fx,fy]=gradient(mask1);
x_mask=find(fx);
y_mask=find(fy);
segOutline=zeros(X,Y);
segOutline(x_mask)=1;
segOutline(y_mask)=1;


axes(handles.axes);
outcome1=slice0+segOutline*max(max(slice0))/2;

imshow(outcome1,[]);
axes(handles.axes5);
imshow(mask1);


sflag=1;

% --- Executes on button press in line.
function line_Callback(hObject, eventdata, handles)
% hObject    handle to line (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global image0;
global mask_save;

slct=get(handles.slice,'value');
sz=size(image0);

global cflag;
global rect;
slice0=image0(:,:,slct);%get a slice for image0 dataset
if cflag==1
    slicecut=slice0(rect(1):rect(2),rect(3):rect(4));
    slice0=slicecut;    
end

[X,Y]=size(slice0);
mask_copy=zeros(X,Y);
axes(handles.axes);

[x1_p,y1_p]=ginput(1);
x1_p=round(x1_p);
y1_p=round(y1_p);
hold on
plot(x1_p,y1_p,'w.','MarkerSize',5);
[x2_p,y2_p]=ginput(1);
x2_p=round(x2_p);
y2_p=round(y2_p);
hold on
plot(x2_p,y2_p,'w.','MarkerSize',5);
plot([x1_p x2_p],[y1_p y2_p]);

hold off;

dx=x2_p-x1_p;
dy=y2_p-y1_p;
dist=sqrt(dx^2+dy^2);
n=abs(dist);
i=0;
fx=dx/dist;
fy=dy/dist;
x=x1_p;
y=y1_p;
while i<n
    x=x+fx;
    y=y+fy;
    i=i+1;
    mask_copy(round(y),round(x))=1;
end
if cflag==1
    mask_save(rect(1):rect(2),rect(3):rect(4))=mask_copy;
else mask_save=mask_copy;
end
axes(handles.axes5);
imshow(mask_save);

% --- Executes on selection change in popupmenu2.
function slice_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global image0;
global image1;
global mask_save;

slct=get(handles.slice,'value');

slice0=image0(:,:,slct);%get a slice for image0 dataset
axes(handles.axes);
imshow(slice0,[]);


slice1=image1(:,:,slct);
axes(handles.axes5);
imshow(slice1,[]);

mask_save=zeros(size(slice0));

global sflag
sflag=0;
global seed
seed=[];
global label
label=[];

% --- Executes on button press in back.
function back_Callback(hObject, eventdata, handles)
% hObject    handle to back (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global image0;
global image1;
global mask_save;
global cflag;
global rect;
slct=get(handles.slice,'value');
if slct>1
 slct=slct-1;
end
set(handles.slice,'value',slct);

slice0=image0(:,:,slct);
mask_save=zeros(size(slice0));
if cflag==1
slicecut=slice0(rect(1):rect(2),rect(3):rect(4));
slice0=slicecut;
end
axes(handles.axes);
imshow(slice0,[]);


slice1=image1(:,:,slct);
if cflag==1
slicecut=slice1(rect(1):rect(2),rect(3):rect(4));
slice1=slicecut;
end
axes(handles.axes5);
imshow(slice1,[]);

global sflag
sflag=0;
global seed
seed=[];
global label
label=[];

% --- Executes on button press in next.
function next_Callback(hObject, eventdata, handles)
% hObject    handle to next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global image0;
global image1;
global rect;
global cflag;
global mask_save;
slct=get(handles.slice,'value');
sz=size(image0);
if slct<sz(3)
slct=slct+1;
end
set(handles.slice,'value',slct);

slice0=image0(:,:,slct);
mask_save=zeros(size(slice0));
if cflag==1
slicecut=slice0(rect(1):rect(2),rect(3):rect(4));
slice0=slicecut;
end
axes(handles.axes);
imshow(slice0,[]);


slice1=image1(:,:,slct);
if cflag==1
slicecut=slice1(rect(1):rect(2),rect(3):rect(4));
slice1=slicecut;
end
axes(handles.axes5);
imshow(slice1,[])

global sflag
sflag=0;
global seed
seed=[];
global label
label=[];

% --- Executes on button press in cut.
function cut_Callback(hObject, eventdata, handles)
% hObject    handle to cut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%---select and cut--
global image0;
global image1;
global rect;
global cflag;%ture:cflag=1,operate on cut iamge
global savevalue;


slct=get(handles.slice,'value');
if cflag==1
%     slice0=savevalue{2};
     questdlg('you can cut only once','warning','OK','OK');
     return
else   
    slice0=image0(:,:,slct);
    savevalue={savevalue;slice0};
end
axes(handles.axes);
[rx_1,ry_1]=ginput(1);
rx_1=round(rx_1);ry_1=round(ry_1);
hold on
plot(rx_1,ry_1,'r.','MarkerSize',5);
[rx_2,ry_2]=ginput(1);
rx_2=round(rx_2);ry_2=round(ry_2);
plot(rx_2,ry_2,'r.','MarkerSize',5);
hold off
rect=[ry_1,ry_2,rx_1,rx_2];




slicecut=slice0(rect(1):rect(2),rect(3):rect(4));
slice0=slicecut;
imshow(slice0,[]);


slice1=image1(:,:,slct);
slicecut=slice1(rect(1):rect(2),rect(3):rect(4));
slice1=slicecut;
axes(handles.axes5);
imshow(slice1);


cflag=1;

% --- Executes on button press in restart.
function restart_Callback(hObject, eventdata, handles)
% hObject    handle to restart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global image0;
global image1;
% global savevalue;

global points
global num_label1
A=inputdlg({'number of label 1','number of points'},'input1',1,{'1','4'});
points=str2double(A{2});
num_label1=str2double(A{1});

slct=get(handles.slice,'value');

slice0=image0(:,:,slct);
axes(handles.axes);
imshow(slice0,[]);

slice1=image1(:,:,slct);
axes(handles.axes5);
imshow(slice1,[]);

sz=size(image0);

global rect;
rect=[1,sz(2),1,sz(1)];
global mask_save;
mask_save=zeros(sz(1),sz(2));

global sflag;
sflag=0;

global cflag;
cflag=0;
% savevalue=savevalue{1};

global seed
seed=[];
global label
label=[];
% if isempty(savevalue)
%     cflag=0;
% end

% --- Executes on button press in save.
function save_Callback(hObject, eventdata, handles)
% hObject    handle to save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global image1;
global mask_save;
slct=get(handles.slice,'value');
image1(:,:,slct)=image1(:,:,slct)+mask_save;

% --- Executes on button press in undo.
function undo_Callback(hObject, eventdata, handles)
% hObject    handle to undo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global image0;
global mask_save;
global rect;
global cflag;

slct=get(handles.slice,'value');
slice0=image0(:,:,slct);
if cflag==1
    slice0=slice0(rect(1):rect(2),rect(3):rect(4));
    mask_save(rect(1):rect(2),rect(3):rect(4))=0;
else
    mask_save=0;
end
axes(handles.axes);
imshow(slice0,[]);
axes(handles.axes5);
imshow(mask_save);

global sflag
sflag=0;
global seed
seed=[];
global label
label=[];

% --- Executes on button press in clear.
function clear_Callback(hObject, eventdata, handles)
% hObject    handle to clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global image1;
global cflag;
global rect;

slct=get(handles.slice,'value');
slice1=image1(:,:,slct);
if cflag==1
    slice1(rect(1):rect(2),rect(3):rect(4))=0;
else
    slice1=0;
end
image1(:,:,slct)=slice1;

if cflag==1
    slice1=slice1(rect(1):rect(2),rect(3):rect(4));
end
axes(handles.axes5);
imshow(slice1);

% --------------------------------------------------------------------
function savenii_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to savenii (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global image1;
global saveflag;
global rflag;
global data0;
[filename,pathname]=uiputfile('.nii','save');
if rflag==1
    image1=permute(image1,[1,3,2]);
end
data0.img=image1;
save_untouch_nii(data0,[pathname filename]);
saveflag=1;

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
global saveflag
if saveflag==1
    delete(hObject);
else
    button=questdlg('exit without save mask?','exit','Yes','No','No');
if strcmp(button,'Yes')
    delete(hObject);
end
end

% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
key=eventdata.Key;
switch key
    case 's'
        selectpoint_Callback(hObject, eventdata, handles);
        handles=guidata(hObject);
    case 'backspace'
        undo_Callback(hObject, eventdata, handles);
        handles=guidata(hObject);
    case 'a'
        back_Callback(hObject, eventdata, handles);
        handles=guidata(hObject);
    case 'd'
        next_Callback(hObject, eventdata, handles);
        handles=guidata(hObject);
    case 'w'
        save_Callback(hObject, eventdata, handles);
        handles=guidata(hObject);
    case 'q'
        clear_Callback(hObject, eventdata, handles);
        handles=guidata(hObject);  
    case 'f'
        line_Callback(hObject,eventdata,handles);
        hadles=guidata(hObject);
    case 'escape'
        figure1_CloseRequestFcn(hObject, eventdata, handles);
        handles=guidata(hObject);  
end
        

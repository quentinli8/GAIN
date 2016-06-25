function edit_box=createEditBox(h,i,oneParameter,pEdit,pText)
%figure(h);
h;
if oneParameter.active
    enbl='on';
else
    enbl='off';
end
if i < 2
    edit_box=uicontrol('Style','edit',...%editbox showing the image file dir
    'Units', 'pixels',...
    'position', pEdit,...
    'string', oneParameter.value,...
    'HorizontalAlignment', 'right',...
    'Enable',enbl);
    
    
else
    edit_box=uicontrol('Style','edit',...%edit boxes and text boxes for parameters
    'Units', 'pixels',...
    'position', pEdit,...
    'string', oneParameter.value,...
    'Enable',enbl);
    uicontrol('Style','text',...
    'Units', 'pixels',...
    'position', pText,...
    'string',oneParameter.name,...
    'HorizontalAlignment','left');
end  
end
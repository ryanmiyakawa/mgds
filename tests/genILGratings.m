
addpath('..')
mgds = MGDS();



%% Make all primitive:
dLayer = 1;
dLayer2 = 2;

dMinWidth = 0.01;

mgds.init('IL_main', 'autogen structures', true);


cField = 'grat1';
dLen = 15; 
dHeight = 15;
dXOffset1 = 19.95;
dYOffset1 = 10 + 7.5;
dPitch = 0.08;
mgds.makeVGrating(cField, dPitch, 0.5, dLen - 10, dHeight, 'center', dLayer);
mgds.makeRef('IL_main', cField, [dXOffset1, dYOffset1; -dXOffset1, dYOffset1]);


cField = 'grat2';
dLen = 20; 
dHeight = 20;
dXOffset2 = 25.15;
% dXOffset2 = 30; % <-- delete

dYOffset2 = 0;
dPitch = 0.064;
mgds.makeVGrating(cField, dPitch, 0.5, dLen - 10, dHeight, 'center', dLayer);
mgds.makeRef('IL_main', cField, [dXOffset2, dYOffset2; -dXOffset2, dYOffset2]);


cField = 'grat3';
dLen = 12; 
dHeight = 12;
dXOffset3 = 16.55;
% dXOffset3 = 20; % <-- delete

dYOffset3 = -10 - 6;
dPitch = 0.048*2;
mgds.makeVGrating(cField, dPitch, 0.5, dLen - 10, dHeight, 'center', dLayer);
mgds.makeRef('IL_main', cField, [dXOffset3, dYOffset3; -dXOffset3, dYOffset3]);

% make apodized sections

%make a gaussian transition over 5 um:
cField = 'grat1apod';
dPitch = 0.08;
dLen = 15; 
dHeight = 15;
xcoords = dPitch:dPitch:5;
for k = 1:length(xcoords)
    dWidth = dPitch*0.5*xcoords(k)/5;
    if dWidth < dMinWidth
        dWidth = dMinWidth;
    end
    mgds.makeRect(cField, dWidth, dHeight, [xcoords(k) - dLen/2 - dPitch/4 - dWidth/2, -dHeight/2], dLayer2);
end
mgds.makeRef('IL_main', cField, [dXOffset1, dYOffset1; -dXOffset1, dYOffset1]);
mgds.makeRef('IL_main', cField, [dXOffset1, dYOffset1; -dXOffset1, dYOffset1], pi);

cField = 'grat2apod';
dPitch = 0.064;
dLen = 20; 
dHeight = 20;
xbump1 = -0.024;

xcoords = dPitch:dPitch:5;
for k = 1:length(xcoords)
    dWidth = dPitch*0.5*xcoords(k)/5;
    if dWidth < dMinWidth
        dWidth = dMinWidth;
    end
%     dWidth = dPitch*0.5;% <-- delete

    mgds.makeRect(cField, dWidth, dHeight, [xcoords(k) - dLen/2 - dPitch/4 - dWidth/2, -dHeight/2], dLayer2);
end
mgds.makeRef('IL_main', cField, [dXOffset2 + xbump1, dYOffset2; -dXOffset2 + xbump1, dYOffset2]);
mgds.makeRef('IL_main', cField, [dXOffset2 + xbump1, dYOffset2; -dXOffset2 + xbump1, dYOffset2], pi);


cField = 'grat3apod';
dPitch =  0.048*2;
dLen = 12; 
dHeight = 12;
xcoords = dPitch:dPitch:5;
xbump1 = -0.04;
xbump2 = 0.008;

for k = 1:length(xcoords)
    dWidth = dPitch*0.5*xcoords(k)/5;
    if dWidth < dMinWidth
        dWidth = dMinWidth;
    end
%     dWidth = dPitch*0.5; % <-- delete
    mgds.makeRect(cField, dWidth, dHeight, [xcoords(k) - dLen/2 - dPitch/4 - dWidth/2, -dHeight/2], dLayer2);
end
mgds.makeRef('IL_main', cField, [dXOffset3 + xbump1, dYOffset3; -dXOffset3 + xbump1, dYOffset3]);
mgds.makeRef('IL_main', cField, [dXOffset3 + xbump2, dYOffset3; -dXOffset3 + xbump2, dYOffset3], pi);
mgds.makeGDS();

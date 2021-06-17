function gdt2gds(gdtName, gdsName, deleteFlag)


[cBinDir p] = fileparts(mfilename('fullpath'));

cCurDir = pwd;

if ispc
    binName = 'gdt2gds.exe';
elseif ismac
    binName = 'gdt2gds.Darwin';
else
    fprintf('OS not recognized\n');
    return
end
    
binPath = fullfile(cBinDir, binName);
gdtPath = fullfile(cCurDir, gdtName);
gdsPath = fullfile(cCurDir, gdsName);

str = sprintf('%s %s %s', fullfile(binPath, gdtPath, gdsPath));

fprintf('Sys command: %s\n', str);
system(str);

if nargin > 2 && deleteFlag
    delete(gdtName);
end


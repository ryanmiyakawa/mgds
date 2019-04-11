function gdt2gds(gdtName, gdsName, deleteFlag)


[cBinDir p] = fileparts(mfilename('fullpath'));

cCurDir = pwd;
str = sprintf('%s/gdt2gdsRM.Darwin %s/%s %s/%s',cBinDir, cCurDir, gdtName, cCurDir,gdsName);

system(str);

if nargin > 2 && deleteFlag
    delete(gdtName);
end


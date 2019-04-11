function gdt2gds(gdtName, gdsName, deleteFlag)

d = pwd;
str = sprintf('gdt2gdsRM.Darwin %s/%s %s/%s', d, gdtName, d,gdsName);

system(str);

if nargin > 2 && deleteFlag
    delete(gdtName);
end


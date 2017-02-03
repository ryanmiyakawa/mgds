function gdt2gds(gdtName, gdsName, deleteFlag)

d = pwd;
ver = 'debug';

switch ver
    case 'debug'
        str = sprintf('/Users/rhmiyakawa/Documents/MATLAB/GDS/old/GDS_source/GDT-1.0.1_RMEdited_working/gdt2gds.Darwin %s/%s %s/%s', d, gdtName, d,gdsName);
    case 'v3'
        str = sprintf('/Users/rhmiyakawa/Documents/MATLAB/GDS/MGDS/gdt2gds_v3.Darwin %s/%s %s/%s', d, gdtName, d,gdsName);
    case '2007'
        str = sprintf('/Users/rhmiyakawa/Documents/MATLAB/GDS/MGDS/gdt2gds_2007.Darwin %s/%s %s/%s', d, gdtName, d,gdsName);
    case '1.1'
        str = sprintf('/Users/rhmiyakawa/Documents/MATLAB/GDS/MGDS/gdt2gdsRM.Darwin %s/%s %s/%s', d, gdtName, d,gdsName);
    case '1.1pure'
        str = sprintf('/Users/rhmiyakawa/Documents/MATLAB/GDS/MGDS/gdt2gds_pure.Darwin %s/%s %s/%s', d, gdtName, d,gdsName);
end

system(str);

if nargin > 2 && deleteFlag
    delete(gdtName);
end


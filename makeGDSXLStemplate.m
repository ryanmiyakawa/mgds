function makeGDSXLStemplate(cXLSname, cFieldName, ceFieldList, bForceOverwrite)

% see if workbook exists:
try
    xlsread(cXLSname);
    fprintf('Opening workbook %s\n', cXLSname);
catch
    % sheet doesnt exist, create one:
    xlswrite(cXLSname, ' ');
end


% see if sheet exists:
try
    xlsread(cXLSname, cFieldName);
    fprintf('Field sheet %s found\n', cFieldName);
    
    if nargin < 4 || ~bForceOverwrite
        a = questdlg(sprintf('Overwrite field %s', cFieldName));

        if ~strcmp(a, 'yes')
            return
        end
    end
end
                   
xlwrite(cXLSname,  ceFieldList', cFieldName, 'A10');
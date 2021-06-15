classdef LEMacro < handle
    
    properties
        cName
        ceMacroList
        bPreserveMacroLocally = false
    end
    
    methods
        function this = LEMacro()
        end
        
        function init(this, cName, varargin)
            this.cName = cName;
            
            for k = 1:length(varargin)
                switch varargin{k}
                    case 'preserveMacro'
                        this.bPreserveMacroLocally = varargin{k+1};
                    
                end
            end
        end
        
        function removeCell(this, cTargetCell)
            this.ceMacroList{end+1} = [...
                sprintf('layout->drawing->setCell("%s");\n', cTargetCell) ...
                'layout->drawing->deleteActuellCell();\n'];
        end
        
        function importGDS(this, cGDSPath)
            this.ceMacroList{end+1} = sprintf('layout->drawing->importFile("%s");\n', cGDSPath);
        end
        
        function renameCell(this, cCellName)
            this.ceMacroList{end + 1} = sprintf('layout->drawing->currentCell->cellName="%s";', cCellName);
        end
        
        function newCell(this, cCellName)
            this.ceMacroList{end + 1} = sprintf('layout->drawing->newCell();\n');
            this.ceMacroList{end + 1} = sprintf('layout->drawing->currentCell->cellName="%s";\n', cCellName);
        end
        
        function makeRef(this, cHomeCell, cTargetCell, dPos)
            this.ceMacroList{end + 1} = sprintf('layout->drawing->setCell("%s");\n', cHomeCell);
            this.ceMacroList{end + 1} = sprintf('layout->drawing->point(%d,%d);\n', dPos(1), dPos(2));
            this.ceMacroList{end + 1} = sprintf('layout->drawing->cellref("%s");\n', cTargetCell);
        end
        
        function save(this, cFileName)
            this.ceMacroList{end + 1} = sprintf('layout->drawing->saveFile("%s");\n', cFileName);
        end
        
        function open(this, cFileName)
            this.ceMacroList{end + 1} = sprintf('layout->drawing->openFile("%s");\n', cFileName);
        end
    
        function renderMacro(this)
            fid = fopen(this.cName, 'w');
            fprintf(fid, '#!/usr/bin/layout\n#name=Macro: %s\n#help=Recorded Mon Jan 23 2017\n\n', this.cName);
            fprintf(fid, 'int main(){\n');
            for k = 1:length(this.ceMacroList)
                fprintf(fid, [this.ceMacroList{k}, '\n']);
            end
            fprintf(fid, '}');
            
            
%             if (this.bPreserveMacroLocally)
%                 copyfile(this.cName, '/Applications/layout.app/macros/');
%             else
%                 movefile(this.cName, '/Applications/layout.app/macros/');
%             end
            
            fprintf('Generated LEMacro %s\n', this.cName);
            fclose(fid);
        end
        
        
    end
    
    
   
    
end
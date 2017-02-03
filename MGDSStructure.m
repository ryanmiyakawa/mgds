classdef MGDSStructure < MGDSSuper
    properties
        ceShapeChildren = {}
        ceReferenceChildren = {}
        ceMReferenceChildren = {}
        ceTextChildren = {}
    end
    
    methods
        % Construct with name, layer
        function this = MGDSStructure(cName, dLayer)
            this.cType = 'structure';
            this.cName = cName;
            if nargin > 1
                this.dLayer = dLayer;
            end
            
        end
        
        function attachChild(this, mgdsNode)
            switch mgdsNode.cType
                case 'shape'
                    this.ceShapeChildren{end+1} = mgdsNode;
                    mgdsNode.cStructureName = this.cName;
                case 'text'
                    this.ceTextChildren{end+1} = mgdsNode;
                    mgdsNode.cStructureName = this.cName;
                case 'ref'
                    this.ceReferenceChildren{end+1} = mgdsNode;
                    mgdsNode.cStructureName = this.cName;
                case 'mref'
                    this.ceMReferenceChildren{end+1} = mgdsNode;
                    mgdsNode.cStructureName = this.cName;
                otherwise
                    fprintf('MGDSNode type %s cannot accept children of type %s\n', this.cType, mgdsNode.cType);
                    return;
            end
        end
        
        function render(this, fid)
            fprintf(fid,'cell{c=%s %s m=%s %s ''%s'' \n', datestr(now, 29), datestr(now, 13), ...
                datestr(now, 29), datestr(now, 13), this.cName);
            
            for k = 1:length(this.ceShapeChildren)
                this.ceShapeChildren{k}.render(fid);
            end
            for k = 1:length(this.ceTextChildren)
                this.ceTextChildren{k}.render(fid);
            end
            for k = 1:length(this.ceReferenceChildren)
                this.ceReferenceChildren{k}.render(fid);
            end
            for k = 1:length(this.ceMReferenceChildren)
                this.ceMReferenceChildren{k}.render(fid);
            end
            
            fprintf(fid,'}\n'); 
        end
    end
end

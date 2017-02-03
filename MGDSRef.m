classdef MGDSRef < MGDSSuper
    properties
        mgdsStructure % Target structure
        dPosition
        dAng  = 0;% radians
        cStructureName % Home structure
    end
    
    methods
        % Construct with name, layer
        function this = MGDSRef(varargin)
            this.cType = 'ref';
            if ~isempty(varargin)
                mgdsNode = varargin{1};
                dPos = varargin{2};
                dAng = varargin{3};
                this.attachChild(mgdsNode, dPos, dAng);
            end 
        end
        
        function render(this, fid)
            thisX = this.dPosition(:,1);
            thisY = this.dPosition(:,2);
            
            for k = 1:length(thisX)
                fprintf(fid,'s{''%s'' a%0.1f xy(%0.6f %0.6f)}\n',...
                    this.mgdsStructure.cName, this.dAng*180/pi, thisX(k), thisY(k));
            end
    
        end
    end
    
    methods (Access = private)
        function attachChild(this, mgdsNode, dPos, dAng)
            switch mgdsNode.cType
                case 'structure'
                    if ~isempty(this.mgdsStructure)
                        fprintf('This reference cell already has a structure %s\n',  this.mgdsStructure.cName);
                    end
                    this.mgdsStructure = mgdsNode;
                    this.dPosition = dPos;
                    this.dAng = dAng;
                
                otherwise
                    fprintf('MGDSNode type %s cannot accept children of type %s\n', this.cType, mgdsNode.cType);
                    return;
            end
        end
        
    end
end

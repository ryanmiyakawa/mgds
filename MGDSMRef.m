classdef MGDSMRef < MGDSSuper
    properties
        mgdsStructure % Target Structure
        dNx
        dNy
        dTx
        dTy
        dOriginX
        dOriginY
        cStructureName % Home structure

    end
    
    methods
        % Construct with name, layer
        function this = MGDSMRef(varargin)
            this.cType = 'ref';
            if ~isempty(varargin)
                mgdsNode = varargin{1};
                dNx = varargin{2};
                dNy = varargin{3};
                dTx = varargin{4};
                dTy = varargin{5};
                dOriginX = varargin{6};
                dOriginY = varargin{7};
                
                this.attachChild(mgdsNode, dNx, dNy, dTx, dTy, dOriginX, dOriginY);
            end
            
        end
        
       
        
        function render(this, fid)
            
            dX = this.dNx * this.dTx;
            dY = this.dNy * this.dTy;
            

            fprintf(fid,'a{''%s'' cr(%d %d) xy(%0.6f %0.6f %0.6f %0.6f %0.6f %0.6f)}\n',...
                this.mgdsStructure.cName, this.dNx, this.dNy, this.dOriginX, this.dOriginY,...
                                dX + this.dOriginX, this.dOriginY, this.dOriginX,  dY + this.dOriginY); 
    
        end
    end
    
    methods (Access = private)
        function attachChild(this, mgdsNode, dNx, dNy, dTx, dTy, dOriginX, dOriginY)
            switch mgdsNode.cType
                case 'structure'
                    if ~isempty(this.mgdsStructure)
                        fprintf('This reference cell already has a structure %s\n',  this.mgdsStructure.cName);
                    end
                    this.mgdsStructure = mgdsNode;
                    this.dNx = dNx;
                    this.dNy = dNy;
                    this.dTx = dTx;
                    this.dTy = dTy;
                    this.dOriginX = dOriginX;
                    this.dOriginY = dOriginY;
                otherwise
                    fprintf('MGDSNode type %s cannot accept children of type %s\n', this.cType, mgdsNode.cType);
                    return;
            end
        end
    end
end

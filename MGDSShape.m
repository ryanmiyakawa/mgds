classdef MGDSShape < MGDSSuper
    properties
        shapeDataX
        shapeDataY
        cStructureName
    end
    
    
    
    methods
        % Construct with name, X, Y, layer
        function this = MGDSShape(varargin)
            this.cType = 'shape';
            if length(varargin) == 1
                fprintf('MGDSNode type "shape" requires a polygon child node\n');
                return;
            end
                 
            if ~isempty(varargin)
                X = varargin{1};
                Y = varargin{2};
                
                this.attachChild(X, Y);
            end
            
            if length(varargin) > 2
                this.dLayer = varargin{3};
            end
            
        end
        
        function attachChild(this, X, Y)
            this.shapeDataX = X;
            this.shapeDataY = Y;
            
            if X(1) ~= X(end) || Y(1) ~= Y(end)
                this.shapeDataX(end + 1) = X(1);
                this.shapeDataY(end + 1) = Y(1);
            end
        end
        
        function render(this, fid)
            fprintf(fid, 'b{%d xy(', this.dLayer);
            for m = 1:length( this.shapeDataX)
                fprintf(fid, '%0.6f %0.6f ', this.shapeDataX(m), this.shapeDataY(m));
            end
            fprintf(fid,')}\n');
        end
    end
end

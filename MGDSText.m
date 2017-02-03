classdef MGDSText < MGDSSuper
    properties
        dX
        dY
        cText
        cStructureName
        dAngle
        dWidth
        cJustification
    end
    
    
    
    methods
        % Construct with name, X, Y, layer
        function this = MGDSText(dX, dY, dAngle, cText, dWidth, cJustification, dLayer)
            this.cType = 'text';
            this.dX = dX;
            this.dY = dY;
            this.cText = cText;
            this.dAngle = dAngle;
            this.dWidth = dWidth;
            this.dLayer = dLayer;
            
            switch lower(cJustification)
                case 'left'
                    this.cJustification = 'l';
                case 'center'
                    this.cJustification = 'c';
                case 'right'
                    this.cJustification = 'r';
            end
           
        end

        function render(this, fid)
            fprintf(fid, 't{%d m%s w%d a%d xy(%0.6f, %0.6f) ''%s'')}\n', ...
                            this.dLayer, this.cJustification, this.dWidth, round(this.dAngle), this.dX, this.dY, (this.cText));
        end
    end
end

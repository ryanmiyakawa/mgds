# MATLAB GDS Generator
**Author:** R Miyakawa  
**Date:** 01/2017

This is an MPM package and is intended for use in MPM (https://github.com/ryanmiyakawa/mpm).  Using this class directly without its dependencies may not have all of its functionallity enabled.

This class is designed to mimic the hierarchical structure of the GDS file. Each component can be created separately and programmatically, culminating in the rendering of the GDS file at the end. The file generation engine in use is `gdt2gds.Darwin` (64-bit OSX) or `gdt2gds.exe` (64-bit Win).

## How to Use
1. Instantiate a `MGDS` instance.
2. Utilize the provided methods.

### Methods

- **init(cName, varargin)**
  - **Description:** Initializes MGDS with project name and properties.

- **makeGDS()**
  - **Description:** Renders current MGDS structure to GDS.

- **import(MGDS)**
  - **Description:** Imports structures and macros from another MGDS instance.

- **makeStructure(mName)**
  - **Description:** Creates a structure. 
  - **Parameters:** May pass a name string or a cell array of names.

- **makeShape(cHomeStructureName, dCoordsX, dCoordsY, dLayer)**
  - **Description:** Creates a polygon boundary using the specified coordinates.

- **makeRef(cHomeStructureName, mTargetStructure, dPositions)**
  - **Description:** Creates a reference in `CHOMESTRUCTURE` to target structure `MTARGETSTRUCTURE`. MTARGETSTRUCTURE can be either a structure name or a MGDS structure node.

- **makeARef(cHomeStructureName, mTargetStructure, dNx, dNy, dTx, dTy, dOriginX, dOriginY)**
  - **Description:** Makes an AREF to target structure. Only rectangular arrays can be made currently.
  - **Parameters:** 
    - `DNX,Y`: Number of elements along the x- and y-directions.
    - `DTX,Y`: The periods.

- **makeRefFromXLS(cXLSName, cHomeStructureName)**
  - **Description:** Creates reference cells as described in an XLS file.
  - **Note:** See `Template.xls` for details.

- **makeCircle(cHomeStructureName, dRadius, dOffset, dNPoints, dLayer)**
  - **Description:** Creates a circular boundary with origin referenced to the center of the circle.

- **makeEllipse(cHomeStructureName, dSemiAxes, dOffset, dNPoints, dLayer)**

- **makeRect(cHomeStructureName, dLen, dHeight, mBLCoord, dLayer)**
  - **Description:** Creates a rectangular boundary. 
  - **Parameters:** `MBLCOORD` is the BL origin coordinate, or can be 'center', which centers the rectangle on [0,0].

- **makePolygonText(cHomeStructureName, dCoordsX, dCoordsY, dAngle, cText, dHeight_um, cJustification, bFlipText, dLayer)**
  - **Description:** Creates a text label. 
  - **Parameters:** 
    - `BFLIPTEXT`: Vertical flip of text for correct wafer printing.
    - `CJUSTIFICATION`: Can be 'left', 'center', or 'right'.

- **makeHGrating(cHomeStructureName, dPitch, dDutyCucle, dLen, dHeight, mBLCoord, dLayer)**  
- **makeVGrating(cHomeStructureName, dPitch, dDutyCucle, dLen, dHeight, mBLCoord, dLayer)**  
- **makeBoundedGrating(this, cHomeStructureName, dPitch, dDC, dLen, dHeight, dAng, mBLCoord, bAddPitchLabel, dLayer)**
  - **Description:** Makes a 1D grating bounded by a rectangle. 
  - **Parameters:** `BADDPITCHLABEL` labels pitch and angle of the grating.

- **scheduleBinaryOperation(cHomeStructureName, cStructureA, cStructureB, cBinaryOperation)**
  - **Description:** Schedules a layout editor macro on two structures.
  - **Parameters:** `CBINARYOPERATION` can be AND, OR, or XOR.
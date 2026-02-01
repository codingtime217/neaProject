#[compute]
#version 450
// setup stuff

struct cell { // defining as a structure to simplify things
     double thermalE;
     double conductivity;
     double specHeatCap;
     double mass;
};



layout(local_size_x = 3, local_size_y = 1, local_size_z = 1) in;
// experiment with other values to find a more appropriate number

layout(set = 0, binding = 0 , std430) restrict buffer InBuffer {
    cell grid[]; // array of the cells
}
inBuffer;

layout(binding = 2, std140) uniform constants {
    int distance;
    int timeStep;    
    int gridx; // used for finding where in the grid the cell is
    
};


layout(set = 0, binding = 1, std430) restrict buffer OutBuffer{
    cell newGrid[]; //defines the outputbuffer
}
outBuffer;


double getFlux(in cell cell1, in cell cell2)
{
    if ((cell1.mass == 0) || (cell2.mass == 0)) {
        return 0;
    };

    double temp1 = (cell1.thermalE*cell1.specHeatCap);
    double temp2 = (cell2.thermalE*cell2.specHeatCap);

    double flux = -cell1.conductivity*(((temp1/cell1.mass) - (temp2/cell2.mass))/distance);
    //if (isnan(flux)) {
     //   return 0;
    // };
    return flux;
}

uint findIndex(in uint globalX, in uint globalY, in int gridX) {
 return globalX + globalY*gridX;  //finds the index in the 1d array given its invocation coordinates
}

cell tryGet(in int index) { // used to fetch cells from the grid, returning a vacuum cell if outside the bounds    
    if (index > inBuffer.grid.length()) {
        return cell(0,0,0,0); }
    else if (index < 0) {
        return cell(0,0,0,0); 
    } 
    return inBuffer.grid[index];
}

cell copyCell(in cell cellToCopy) {
    return cell(cellToCopy.thermalE,cellToCopy.conductivity,cellToCopy.specHeatCap,cellToCopy.mass); //used to copy a cell as structs get treated as memeory refs rather than data
}

void main() { // for each invoke
    uint currentIndex;
    cell currentCell;
    cell[4] neighbours; 

    currentIndex = findIndex(gl_GlobalInvocationID.x,gl_GlobalInvocationID.y,gridx); //find our associated index
    currentCell = inBuffer.grid[currentIndex]; //grab te cell

    int indexInt = int(currentIndex);

    neighbours = cell[4](tryGet(indexInt + 1),tryGet(indexInt + gridx),tryGet(indexInt - 1),tryGet(indexInt - gridx)); //list of neighbours in anticlockwise order, starting with the one to the right
    double flux;
    double netFlux = 0;
    double temp;
    for (int i = 0; i < 4; ++i) {
        flux = getFlux(currentCell, neighbours[i]);

        temp = netFlux;
        netFlux = temp + flux; //find the net flux in/out
    }; 


    cell newCell = copyCell(currentCell); //make a duplicate
    
    newCell.thermalE = newCell.thermalE + netFlux; //update the duplicate

    
    outBuffer.newGrid[currentIndex] = newCell; //write to output buffer
}


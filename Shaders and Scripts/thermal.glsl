#[compute]
#version 450
// setup stuff

struct cell { // defining as a structure to simplify things
 //used for bit count shenanigans
    uint materialIndex;
    double temperature; 
};


struct material {
    double conductivity;
    double specHeatCap;
    double mass;
};


layout(local_size_x = 2, local_size_y = 2, local_size_z = 1) in;
// experiment with other values to find a more appropriate number

layout(set = 0, binding = 0 , std430) restrict buffer InBuffer {
    cell grid[]; // array of the cells
}
inBuffer;

layout(binding = 1, std140) uniform constants {
 //here for bit count shenanigans
    uint distance;
    uint timeStep;  
    uint gridx;

    
};

layout(binding = 2, std140 ) uniform matDict {
    material materialArray[64]; // used for finding where in the grid the cell is
};



layout(set = 0, binding = 3, std430) restrict buffer OutBuffer{
    cell newGrid[]; //defines the outputbuffer
}
outBuffer;


double getDeltaTemp(in cell cell1, in cell cell2)
{
    //return 10;
    if ((cell1.materialIndex == 0) || (cell2.materialIndex == 0)) { //index 0 will always be the void material
        return 0;
    };
    if (cell1.temperature == cell2.temperature) {
        return 0;
    };

    double conductivity = (materialArray[cell1.materialIndex].conductivity + materialArray[cell2.materialIndex].conductivity)/2; // average the conductivities

    double flux = (-conductivity)*((cell1.temperature - cell2.temperature)/distance) * timeStep; // find the change in thermal energy

    
    return flux/(materialArray[cell1.materialIndex].mass * materialArray[cell1.materialIndex].specHeatCap); //return change in temperature
}

uint findIndex(in uint globalX, in uint globalY, in uint gridX) {
 return globalX + globalY*gridX;  //finds the index in the 1d array given its invocation coordinates
}

cell tryGet(in uint index) { // used to fetch cells from the grid, returning a vacuum cell if outside the bounds    
    if (index >= inBuffer.grid.length()) {
        return cell(0,0); }
    else if (index < 0) {
        return cell(0,0); 
    } 
    return inBuffer.grid[index];
}

cell[4] getNeighbours(in uint index) {
    cell[4] neighbours;
    neighbours = cell[4](tryGet(index + 1),tryGet(index + gridx),tryGet(index - 1),tryGet(index - gridx)); //list of neighbours in anticlockwise order, starting with the one to the right

    if ((index % gridx) == 0) { //accounts for cells on the right or left edges, top and bottom would create invalid indices already account for in tryGet()
        neighbours[2] = cell(0,0);
    } else if ((index + 1) % gridx == 0) {
        neighbours[0] = cell(0,0) ;
    };
    return neighbours;
}

cell copyCell(in cell cellToCopy) {
    return cell(cellToCopy.materialIndex,cellToCopy.temperature); //used to copy a cell as structs get treated as memeory refs rather than data
}

void main() { // for each invoke
    uint currentIndex;
    cell currentCell;
    cell[4] neighbours; 

    currentIndex = findIndex(gl_GlobalInvocationID.x,gl_GlobalInvocationID.y,gridx); //find our associated index
    currentCell = inBuffer.grid[currentIndex]; //grab te cell

    neighbours = getNeighbours(int(currentIndex)); // get the neighbours

    double deltaT;
    double netDeltaT = 0;
    double temp;
    for (int i = 0; i < 4; ++i) {
        deltaT = getDeltaTemp(currentCell, neighbours[i]);

        temp = netDeltaT;
        netDeltaT = temp + deltaT; //find the net temperature in/out
    }; 


    cell newCell = copyCell(currentCell); //make a duplicate
    
    newCell.temperature = newCell.temperature + netDeltaT; //update the duplicate
    
    outBuffer.newGrid[currentIndex] = newCell; //write to output buffer
}


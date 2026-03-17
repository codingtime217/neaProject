#[compute]
#version 450
// setup stuff, defining shader type, glsl version and others

struct cell { // defining a cell structure 
    uint materialIndex;
    uint pointsless; //here to make the data 16 bits for buffer alignments
    double thermalEnergy; 
    
};


struct material { //defined as a structure too
    double specHeatCap;
    double conductivity;
    double mass;
};


layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in; 
// defeine local workgroups as 1*1*1 -> 1 invocaton per cell

layout(set = 0, binding = 0 , std140) restrict buffer InBuffer { //defining in buffer
    cell grid[]; // array of the cells
}
inBuffer;

layout(binding = 1, std140) uniform constants {//defining constants buffer
    uint dis;
    uint gridx;   
    uint timeStep;  //only consists of 3 unsigned integers
 
};

layout(binding = 2, std140 ) uniform matDict {//define material buffer as an array of materials
    material materialArray[32]; 
};



layout(set = 0, binding = 3, std140) restrict buffer OutBuffer{//defining outbuffer buffer
    cell newGrid[]; //also an array of cells
}
outBuffer;


double getDeltaTemp(in cell cell1, in cell cell2) //function to find the flow of thermal energy from cell1 to cell2
{
    if ((cell1.materialIndex == 0) || (cell2.materialIndex == 0)) { //index 0 will always be the void material
        return 0;
    };

    double conduction = (materialArray[cell1.materialIndex].conductivity + materialArray[cell2.materialIndex].conductivity)/2; // average the conductivities

    double specHeat1 = materialArray[cell1.materialIndex].mass * materialArray[cell1.materialIndex].specHeatCap; //find the J/C* for each cell
    double specHeat2 = materialArray[cell2.materialIndex].mass * materialArray[cell2.materialIndex].specHeatCap;

    double temp1 = cell1.thermalEnergy/specHeat1; //temperatures of each cell
    double temp2 = cell2.thermalEnergy/specHeat2;

    double flux = (-conduction)*((temp1 - temp2)/dis) * timeStep; // find the change in thermal energy

     
    return flux;
}

uint findIndex(in uint globalX, in uint globalY, in uint gridX) {
 return globalX + globalY*gridX;  //finds the index in the 1d array given its invocation coordinates
}

cell copyCell(in cell cellToCopy) {
    return cell(cellToCopy.materialIndex,0,cellToCopy.thermalEnergy); //used to copy a cell as structs get treated as memory refs rather than data
}


cell tryGet(in uint index) { // used to fetch cells from the grid, returning a vacuum cell if outside the bounds    
    if (index >= inBuffer.grid.length()) {
        return cell(0,0,0); };
    
    cell fetchedCell = inBuffer.grid[index];
    return copyCell(fetchedCell);
}

cell[4] getNeighbours(in uint index) { //fetches a cells neighbours
    cell[4] neighbours;

    neighbours = cell[4](tryGet(index + 1),tryGet(index + gridx),tryGet(index - 1),tryGet(index - gridx)); //list of neighbours in clockwise order, starting with the one to the right
    if ((index % gridx) == 0) { //accounts for cells on the left edges,
        neighbours[2] = cell(0,0,0);
    } else if ((index + 1) % gridx == 0) { //accounts fro cells on the right edge
        neighbours[0] = cell(0,0,0) ;
    };
    if (index == 0) { //first cell
        neighbours[2] = cell(0,0,0);
        neighbours[3] = cell(0,0,0);
    } else if (index < gridx) { //top row
        neighbours[3] = cell(0,0,0);
    };
    return neighbours;
}



void main() { // for each invoke
    //local variables
    uint currentIndex;
    cell currentCell;
    cell[4] neighbours; 

    currentIndex = findIndex(gl_GlobalInvocationID.x,gl_GlobalInvocationID.y,gridx); //find our associated index
    currentCell = inBuffer.grid[currentIndex]; //grab the cell
    neighbours = getNeighbours(currentIndex); // get the neighbours

    double deltaT;
    double netDeltaT = 0;
    double temp;
    for (int i = 0; i < 4; ++i) { //iterate through neighbours
        deltaT = getDeltaTemp(currentCell, neighbours[i]);
        temp = netDeltaT;
        netDeltaT = temp + deltaT; //find the net thermalEnergy in/out
    }; 


    cell newCell = copyCell(currentCell); //make a duplicate
    newCell.thermalEnergy = netDeltaT + currentCell.thermalEnergy; //update the duplicate
    outBuffer.newGrid[currentIndex] = newCell; //write to output buffer
}


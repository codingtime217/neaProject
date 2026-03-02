#[compute]
#version 450
// setup stuff


// this shader will find consider what neutrons in the cell will do inside the cell and adjust the no. of neutrons to be only the no. leaving the cell

struct cell { // defining as a structure to simplify things
 //used for bit count shenanigans
    uint materialIndex;

    uint fastNeutrons; //since they are emitted in random directions we can treat all neutrons as being equal spread accross the four edges
    uint thermalNeutrons;// this will both be neutrons per cell ie per 1000cm^3 = 0.001m^3

    double thermalEnergy; 
    
};


struct material {
    double fissileDensity; //this is density of fissile nuclei in a cell
    double fissionCrossSection;  //fission cross section of each nuclei
    double averageNoNeutrons; //average no. of neutrons emitted per fission
    double deltaE; //energy emitted per fission
    // other properties needed for moderators
    double mass;
};


layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
// experiment with other values to find a more appropriate number

layout(set = 0, binding = 0 , std140) restrict buffer InBuffer {
    cell grid[]; // array of the cells
}
inBuffer;

layout(binding = 1, std140) uniform constants {
 //here for bit count shenanigans
    uint dis;
    uint gridx;   
    uint timeStep;  
 
};

layout(binding = 2, std140 ) uniform matDict {
    material materialArray[32]; // used for finding where in the grid the cell is
};



layout(set = 0, binding = 3, std140) restrict buffer OutBuffer{
    cell newGrid[]; //defines the outputbuffer
}
outBuffer;


uint getNoFissions(in cell cell1) {
    uint noFissions = 0;
    double macroCrossSection = cell.fissileDensity * cell.fissionCrossSection;
    return noFissions;
}




uint findIndex(in uint globalX, in uint globalY, in uint gridX) {
 return globalX + globalY*gridX;  //finds the index in the 1d array given its invocation coordinates
}

cell copyCell(in cell cellToCopy) {
    return cellToCopy; //used to copy a cell as structs get treated as memeory refs rather than data
}


cell tryGet(in uint index) { // used to fetch cells from the grid, returning a vacuum cell if outside the bounds    
    if (index >= inBuffer.grid.length()) {
        return cell(0,0,0); };
    
    cell fetchedCell = inBuffer.grid[index];
    return copyCell(fetchedCell);
}

cell[4] getNeighbours(in uint index) {
    cell[4] neighbours;

    neighbours = cell[4](tryGet(index + 1),tryGet(index + gridx),tryGet(index - 1),tryGet(index - gridx)); //list of neighbours in clockwise order, starting with the one to the right
    if ((index % gridx) == 0) { //accounts for cells on the left edges,
        neighbours[2] = cell(0,0,0);
    } else if ((index + 1) % gridx == 0) {
        neighbours[0] = cell(0,0,0) ;
    };
    if (index == 0) {
        neighbours[2] = cell(0,0,0);
        neighbours[3] = cell(0,0,0);
    } else if (index < gridx) {
        neighbours[3] = cell(0,0,0);
    };
    
    return neighbours;
}



void main() { // for each invoke
    const float PI = 3.14159265358;
    const double cellVolume = 4/3 * PI * gridx**3
    uint currentIndex;
    cell currentCell;
    cell[4] neighbours; 

    currentIndex = findIndex(gl_GlobalInvocationID.x,gl_GlobalInvocationID.y,gridx); //find our associated index
    currentCell = inBuffer.grid[currentIndex]; //grab te cell
    neighbours = getNeighbours(currentIndex); // get the neighbours


    outBuffer.newGrid[currentIndex] = newCell; //write to output buffer
}


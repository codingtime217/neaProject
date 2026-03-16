#[compute]
#version 450
// setup stuff


// this cell will consider fission events caused by neutrons from neigbouring cells

struct cell { // defining as a structure to simplify things
 //used for bit count shenanigans
    uint materialIndex;
    float fissileDensity; //this is density of fissile nuclei in a cell
    double fastNeutronFlux; //since they are emitted in random directions we can treat all neutrons as being equal spread accross the four edges. The flux is the product of density and velocity so contains info about neutron avverage eneryg
    double thermalNeutronFlux;// this will both be neutrons per cell ie per 1000cm^3 = 0.001m^3
    double thermalEnergy; 
    
};


struct material {
    double fissionCrossSection;  //thermal fission cross Section
    double averageNoNeutrons;
    double neutronEnergy; //average no. of neutrons emitted per fission * t
    double deltaE; //energy emitted per fission as thermal fragments and such// other properties needed for moderators
    double moderationFactor; //proportion of fast neutrons converted to thermal (after being hit)
    double moderationCrossSection;
    double absorbtionCrossSection;
    double nuclearDensity;
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


cell updateCell(in cell cell1, in cell[4] neightbour) {
    uint noFissions = 0;
    for(int i = 0; i < 4; i++) {
        cell consideringNeighbour = neightbour[i];
        if (consideringNeighbour.thermalNeutronFlux == 0 || consideringNeighbour.fastNeutronFlux == 0) {
            continue;
        };
        cell1.thermalNeutronFlux += int(consideringNeighbour.thermalNeutronFlux / 4);
        cell1.fastNeutronFlux += int(consideringNeighbour.fastNeutronFlux / 4);
    };  
    
    material celMat = materialArray[cell1.materialIndex];
    
    


    double temp = cell1.fastNeutronFlux;
    double moderatedFlux = cell1.fastNeutronFlux * celMat.nuclearDensity * celMat.moderationFactor * celMat.moderationCrossSection * pow(10,-28); //* pow(10,-28) is to convert form barns to m^2
    
    cell1.fastNeutronFlux -= moderatedFlux;
    cell1.thermalNeutronFlux += moderatedFlux;
    
    return cell1;
}




uint findIndex(in uint globalX, in uint globalY, in uint gridX) {
 return globalX + globalY*gridX;  //finds the index in the 1d array given its invocation coordinates
}

cell copyCell(in cell cellToCopy) {
    return cellToCopy; //used to copy a cell as structs get treated as memeory refs rather than data
}


cell tryGet(in uint index) { // used to fetch cells from the grid, returning a vacuum cell if outside the bounds    
    if (index >= inBuffer.grid.length()) {
        return cell(0,0,0,0,0); };
    
    cell fetchedCell = inBuffer.grid[index];
    return copyCell(fetchedCell);
}

cell[4] getNeighbours(in uint index) {
    cell[4] neighbours;

    neighbours = cell[4](tryGet(index + 1),tryGet(index + gridx),tryGet(index - 1),tryGet(index - gridx)); //list of neighbours in clockwise order, starting with the one to the right
    if ((index % gridx) == 0) { //accounts for cells on the left edges,
        neighbours[2] = cell(0,0,0,0,0);
    } else if ((index + 1) % gridx == 0) {
        neighbours[0] = cell(0,0,0,0,0) ;
    };
    if (index == 0) {
        neighbours[2] = cell(0,0,0,0,0);
        neighbours[3] = cell(0,0,0,0,0);
    } else if (index < gridx) {
        neighbours[3] = cell(0,0,0,0,0);
    };
    
    return neighbours;
}



void main() { // for each invoke
    const double thermalNeutronVelocity = 2190;
    uint currentIndex;
    cell currentCell;
    cell[4] neighbours; 

    currentIndex = findIndex(gl_GlobalInvocationID.x,gl_GlobalInvocationID.y,gridx); //find our associated index
    currentCell = inBuffer.grid[currentIndex]; //grab te cell
    neighbours = getNeighbours(currentIndex); // get the neighbours
    cell newCell = copyCell(currentCell);

    newCell = updateCell(newCell,neighbours);

    if (isnan(newCell.thermalEnergy)) {
        newCell.thermalEnergy = 2;
    }
    outBuffer.newGrid[currentIndex] = newCell; //write to output buffer
}


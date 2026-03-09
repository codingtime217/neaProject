#[compute]
#version 450
// setup stuff


// this shader will find consider what neutrons in the cell will do inside the cell and adjust the no. of neutrons to be only the no. leaving the cell

struct cell { // defining as a structure to simplify things
 //used for bit count shenanigans
    uint materialIndex;
    double fastNeutronFlux; //since they are emitted in random directions we can treat all neutrons as being equal spread accross the four edges. The flux is the product of density and velocity so contains info about neutron avverage eneryg
    double thermalNeutronFlux;// this will both be neutrons per cell ie per 1000cm^3 = 0.001m^3
    double thermalEnergy; 
    double fissileDensity; //this is density of fissile nuclei in a cell
};


struct material {
    
    double[2] fissionCrossSection;  //fission cross section of each nuclei, first item is thermal, 2nd is fast
    double averageNoNeutrons;
    double neutronEnergy; //average no. of neutrons emitted per fission
    double deltaE; //energy emitted per fission as thermal fragments and such
   
   
    // other properties needed for moderators
    double moderationFactor; //proportion of fast neutrons converted to thermal (after being hit)
    double moderationCrossSection;
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


uint getNoFissions(out cell cell1) {
    material cellMat = materialArray[cell1.materialIndex];
    double[2] fissionCrossSection = cellMat.fissionCrossSection;
    if (fissionCrossSection[0] == 0 && fissionCrossSection[1] == 0) {
        return 0;
    }
    double[2] neutronFluxes = double[2](cell1.thermalNeutronFlux,cell1.fastNeutronFlux);
    uint thermalFissions = int( cell1.fissileDensity * fissionCrossSection[0] * pow(10,-28) * neutronFluxes[0]); //* pow(10,-28) is to convert form barns to m^2
    uint fastFissions = int( cell1.fissileDensity * fissionCrossSection[1] * pow(10,-28) * neutronFluxes[1]);

    cell1.thermalNeutronFlux -= thermalFissions/pow(dis,3); //these don't account for neutron energy levels but should
    cell1.fastNeutronFlux -= fastFissions/pow(dis,3);
    return fastFissions + thermalFissions;
}


cell updateCell(out cell cell1, uint noFissions) {
    material celMat = materialArray[cell1.materialIndex];
    cell1.fastNeutronFlux += noFissions * celMat.averageNoNeutrons * celMat.neutronEnergy;
    cell1.thermalEnergy += noFissions * celMat.deltaE;
    cell1.fissileDensity -= noFissions/pow(dis,3);
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

void main() { // for each invoke
    const float PI = 3.14159265358;
    const double cellVolume = 4/3 * PI * pow(dis/2,3);
    uint currentIndex;
    uint noFissions;
    cell currentCell;
    
    currentIndex = findIndex(gl_GlobalInvocationID.x,gl_GlobalInvocationID.y,gridx); //find our associated index
    currentCell = inBuffer.grid[currentIndex]; //grab te cell
     
    cell newCell = copyCell(currentCell);
    noFissions = getNoFissions(newCell);
    newCell = updateCell(newCell,noFissions);



    outBuffer.newGrid[currentIndex] = newCell; //write to output buffer
}


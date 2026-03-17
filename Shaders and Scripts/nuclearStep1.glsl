#[compute]
#version 450
// setup stuff

// this shader will find consider what neutrons in the cell will do inside the cell and adjust the no. of neutrons to be only the no. leaving the cell

struct cell { // defining as a structure
    uint materialIndex;
    float fissileDensity;  //this is density of fissile nuclei in a cell, stored as a float to compact this slightly
    double fastNeutronFlux; //fluxes are number of neutrons * avg velocity
    double thermalNeutronFlux;
    double thermalEnergy; //thermal energy of the cell
   
};


struct material {
    double fissionCrossSection;  //thermal fission cross Section
    double averageNoNeutrons; //average no. of neutrons emitted per fission 
    double neutronEnergy; //average energy of fission neutrons
    double deltaE; //energy emitted per fission as thermal fragments and such// other properties needed for moderators
    double moderationFactor; //proportion of fast neutrons converted to thermal (after being hit)
    double moderationCrossSection; //neutron cross section for moderation collisions
    double absorbtionCrossSection; //cross section for absorbtion without fission
    double nuclearDensity; //density of nuclei
};


layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;


layout(set = 0, binding = 0 , std140) restrict buffer InBuffer { //define in buffer
    cell grid[]; // array of the cells
}
inBuffer;

layout(binding = 1, std140) uniform constants { //constants buffers
    uint dis;
    uint gridx;   
    uint timeStep;  
};

layout(binding = 2, std140 ) uniform matDict {
    material materialArray[32]; //material dict buffer
};



layout(set = 0, binding = 3, std140) restrict buffer OutBuffer{
    cell newGrid[]; //defines the outputbuffer
}
outBuffer;


uint getNoFissions(in cell cell1) { //finds the number of fissions happening in the cell
    material cellMat = materialArray[cell1.materialIndex]; //get the cells material properties
    double fissionCrossSection = cellMat.fissionCrossSection;
    if (fissionCrossSection== 0) { //if the cross section is 0 there will be no fission
        return 0;
    };
    double neutronFluxes = cell1.thermalNeutronFlux;
    double macroCrossSection = cell1.fissileDensity * fissionCrossSection * pow(10,-28); 
    //macro crossection is the total cross section of nuclei in an area, * pow(10,-28) is to convert form barns to m^2
    uint thermalFissions = uint( macroCrossSection* neutronFluxes* timeStep); // the rate of fission is crosssection * flux

    return thermalFissions;
}


cell updateCell(in cell cell1,in uint noFissions) { //updates the fluxes, fissile density and thermal energy of the cell based on the fissions that occured
 
    material celMat = materialArray[cell1.materialIndex];
    //remove absorbed (not fission) neutrons
    cell1.fastNeutronFlux -= cell1.fastNeutronFlux *(celMat.nuclearDensity - cell1.fissileDensity) * (celMat.absorbtionCrossSection - celMat.fissionCrossSection) * (dis/100) * pow(10,-28);
    cell1.thermalNeutronFlux -= cell1.thermalNeutronFlux * (celMat.nuclearDensity - cell1.fissileDensity) *(celMat.absorbtionCrossSection - celMat.fissionCrossSection) * (dis/100) * pow(10,-28);

    //add neutrons based on number of fissions that occured
    cell1.fastNeutronFlux += noFissions * celMat.averageNoNeutrons * celMat.neutronEnergy;

    double deltaFlux;
    deltaFlux = noFissions;
    double temp = cell1.thermalNeutronFlux;
    cell1.thermalNeutronFlux = temp - (deltaFlux); //decrease the thermal neutron flux to account for the fissions that happened
    if (cell1.thermalNeutronFlux < 0) { //min is 0
        cell1.thermalNeutronFlux = 0;
    }
    cell1.thermalEnergy += noFissions * celMat.deltaE; //increase the thermal energy based on fissions
    cell1.fissileDensity -= timeStep * noFissions; //decrease fissile density to account for fissed nuclei
    
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
    float PI = 3.14159265358;
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


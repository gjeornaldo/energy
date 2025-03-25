This data analysis was carried out for the journalistic investigation led by [Osservatorio Balcani Caucaso Transeuropa](https://www.balcanicaucaso.org) within the EU-funded project [European Data Journalism Network](https://www.europeandatajournalism.eu/it/).


THe main aim of the analysis was to offer data on the regional level for the EU member states regarding the energy demand and its composition in energy source type and energy sector. Moreover, using different sources, this analysis also tries to give a perspective on the amount of energy demand that could theoretically ally be met by renewable energy in the future according to the latest scientific publications.


## Data sources:
Two data sources have been used for this project.

The first one is the [EU Energy Atlas](https://data.jrc.ec.europa.eu/dataset/76a6b550-253c-44a4-9a4c-d22079e7bf62), created and published by the Joint Research Center research of the European Union. The data consists of 44 different datasets, discriminating between 8 groups of energy products, and 5 sectors of economic activity, as well as the total amount of energy demanded from a certain energy product.

The datasets cover the entirety of the European Union, minus the French overseas territories, with a grid composed of 24,911,114 cells of 1 square kilometer each. All figures are expressed in tonnes of oil equivalent (toe).

The energy products are:
- electricity;
- gas (natural gas);
- heat;
- nuclear (nuclear heat);
- oil (oil and petroleum products);
- others (manufactured gasses, oil shale, and peat and peat products); 
- renewables (renewables and biofuels);
- solid (solid fossil fuels).

The sectors of economic activity are:
- industry;
- non-energy-use;
- other sectors (commercial and public services, households, agriculture and fishing);
- transport;
- transformation input;
- total.

For more information on the data, referr to the [original documentation](https://publications.jrc.ec.europa.eu/repository/handle/JRC136080).

The second data source comes from the publication [Renewable Energy production and potential in EU Rural Areas](https://publications.jrc.ec.europa.eu/repository/handle/JRC135612), produced as well by the Joint Research Center of the European Union.

The dataset consists in a spreadsheet that estimates the potential renewable energy production in the NUTS 3 regions of the EU quantifying it in Terawatt hours (TWh).

## Analysis: 
The primary task of the analysis, whic can be found in the code, consists in the zonal analysis computed on the cell values from raw datasets that intersect or fall within each of the NUTS 3 regions of the EU, making it possible to assign a value to every one each of the 1162 regions.


![](https://datavis.europeandatajournalism.eu/obct/connectivity/files/screenshot.png)

For how much the process is quite straightforward, some challenges and limitations were identified in the analysis. 

### Coastal regions:
In the coastal regions and those with large bodies of water, certain cells remained unmatched because the region's boundary did not sufficiently cover these cells. 

To address this, the methodology includes a step to reproject the NUTS 3 boundaries by applying a 500-meter buffer. This adjustment only affects areas not bordering another NUTS 3 region, ensuring no cell is assigned to more than one region. This buffering process successfully captures previously unmatched cells, as illustrated in a series of visual plots. 

The following images better illustrate this limitation and the process:

This is the plot of the cells belonging to the unbuffered Rome NUTS 3.
![](https://datavis.europeandatajournalism.eu/obct/connectivity/files/Rome_unbuffered.png)

This is instead the plot of the buffered NUTS 3 region of Rome.
![](https://datavis.europeandatajournalism.eu/obct/connectivity/files/Rome_buffered.png)

Finally, this is the difference between the two plots, or the cells that were included after buffering the boundaries.
![](https://datavis.europeandatajournalism.eu/obct/connectivity/files/Rome_buffer.png)

In the case of the Rome region, the buffering adjustment accounted for an additional 0.63% of the total energy demand. The significance of this difference may vary depending on the concentration of energy-intensive activities in coastal areas and the relative size of the region.

### Concentration of energy demand in a small number of cells:
It was observed that a substantial proportion of energy demand is concentrated in a small number of grid cells, typically corresponding to power plants or large industrial facilities. Residential areas, by contrast, generally exhibit much lower energy demand.

To systematically quantify this concentration in a generalized way, a section of the script isolates the top 1% of grid cells with the highest energy demand in each region. For these cells, the absolute and relative energy demand is calculated, offering insights into the concentration of energy use. The 1% threshold was selected to account for the considerable variation in the number of grid cells assigned to different regions as a result of the different extension of NUTS 3 region in the EU, that span from the 14 km2 of Melilla, in Spain, to the 105208 km2 of Norrbottens lä, in Sweden.


### Comparing energy demand and renewavle energy potential:
The last step of the analysis consisted of a comparison of the two data sources, in order to estimate which share of energy demand could theoretically be met by the perspective production of renewable energy.
Given that the two datasets have different units of measurement (toe and TWh), first the amounts of energy demand have been transformed from ktoe to TWh (1 toe equals to 0,00001163 TWh). Then, the energy demand from all energy type and use, besides the non energetic uses, transformed in TWh has been compared to the potential production of energy from renewable energies in relative terms.

## Dataset and how to cite:
The product of the analysis can be found in [this dataset](https://docs.google.com/spreadsheets/d/1QMY6OxKxIXTsOdB_lu6g7EQbwxobU69mjj3LG6Pjhpw/edit?gid=2052512253#gid=2052512253).

This project is licensed under the Creative Commons Attribution 4.0 International (CC BY-SA 4.0).
To cite this project please refer to the [European Data Journalism Network](https://www.europeandatajournalism.eu/).



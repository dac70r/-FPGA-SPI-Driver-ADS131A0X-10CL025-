## ADS131A04 SPI Library
ADS131A04 SPI Library written in Verilog HDL

## Introduction
- SPI_Master.v was written as an interface to a single ADS131A04 analog-to-digital converter by Texas Instruments. 
- ADS131A0X.v was written as the top module/ wrapper. 

## Operating Mechanism
1. Initialization - The FPGA/ Master initializes the ADC. Check if 0x0555_000 is received to confirm a successful initialization. 
2. Asynchronous Reading of ADC Data - Perform continous reads on all 4 channels of the analog-to-digital converter. The ADC DRDY line will assert low indicating fresh available data, followed by a SPI Read by FPGA/ Master.
3. Process & Transfer data to NIOS - The raw ADC Values will be collected and passed into Asynchronous FIFOs to be read by the NIOS softcore.    

## Author 
Dennis Wong Guan Ming

## Versioning
- v2.0.0    Fully Functional ADC Reads    -   18th Jun 2025
- v1.0.0    First Version                 -   12th Jun 2025
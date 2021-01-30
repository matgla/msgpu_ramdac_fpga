package spi_types; 

/* SPI modes */
typedef enum {
    SPI_MODE_1,
    SPI_MODE_4_INPUTS,
    SPI_MODE_4_OUTPUTS,
    SPI_MODE_WAIT
} SpiMode;

typedef enum {SPI_OPERATION_FINISHED, SPI_OPERATION_WORKING} operation_status;

typedef enum {
    QSPI_WRITE_ENABLE_CLOCK,
    QSPI_WRITE_PART_1,
    QSPI_WRITE_PART_2
} QspiWriteState;

typedef enum {
    QSPI_READ_ENABLE_CLOCK, 
    QSPI_READ_PART_1,
    QSPI_READ_PART_2
} QspiReadState;

typedef enum 
{
    READ_WRITE_INIT,
    READ_WRITE_0_BIT,
    READ_WRITE_1_BIT,
    READ_WRITE_2_BIT,
    READ_WRITE_3_BIT,
    READ_WRITE_4_BIT,
    READ_WRITE_5_BIT,
    READ_WRITE_6_BIT,
    READ_WRITE_7_BIT
} ReadWriteByteState;


endpackage : spi_types
